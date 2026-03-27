-- ============================================================
-- BLIP: 포인트 베팅 시스템 (예측 질문 + BP 베팅 + 정산)
-- 선행: 001_rooms.sql
-- Critical Issues: C1(Idempotency), C2(Device Registry),
--                  C4(이중 정산 방지), C5(payout 합계 검증)
-- High Issues: H1(인덱스), H7(타임아웃 자동 환불)
-- ============================================================

-- ─── 디바이스별 포인트 ───

CREATE TABLE IF NOT EXISTS device_points (
  device_fingerprint TEXT PRIMARY KEY,
  balance INT NOT NULL DEFAULT 100 CHECK (balance >= 0),
  total_earned INT NOT NULL DEFAULT 0,
  total_spent INT NOT NULL DEFAULT 0,
  total_won INT NOT NULL DEFAULT 0,
  total_lost INT NOT NULL DEFAULT 0,
  hardware_hash TEXT,                    -- C2: 디바이스 레지스트리 (하드웨어 해시)
  last_daily_reward_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 예측 질문 ───

CREATE TABLE IF NOT EXISTS predictions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_fingerprint TEXT NOT NULL,
  question TEXT NOT NULL,
  category TEXT NOT NULL,
  locale TEXT NOT NULL DEFAULT 'en',
  type TEXT NOT NULL DEFAULT 'yes_no' CHECK (type IN ('yes_no', 'multiple')),
  options JSONB NOT NULL DEFAULT '["yes","no"]',
  correct_answer TEXT,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'closed', 'settled', 'cancelled')),
  total_pool INT DEFAULT 0,
  creator_share_percent INT DEFAULT 50,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  closes_at TIMESTAMPTZ NOT NULL,
  reveals_at TIMESTAMPTZ NOT NULL,
  settled_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 베팅 기록 ───

CREATE TABLE IF NOT EXISTS prediction_bets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID NOT NULL REFERENCES predictions(id) ON DELETE CASCADE,
  device_fingerprint TEXT NOT NULL,
  option_id TEXT NOT NULL,
  bet_amount INT NOT NULL CHECK (bet_amount >= 1 AND bet_amount <= 500),
  odds_at_bet DECIMAL(8,4) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'won', 'lost', 'refunded')),
  payout INT,
  idempotency_key TEXT UNIQUE,           -- C1: 중복 베팅 방지
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

-- ─── 질문 생성 기록 (생성자 보상 추적) ───

CREATE TABLE IF NOT EXISTS prediction_creations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  prediction_id UUID NOT NULL REFERENCES predictions(id) ON DELETE CASCADE,
  creator_fingerprint TEXT NOT NULL,
  creation_cost INT NOT NULL DEFAULT 150,
  total_earned INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  settled_at TIMESTAMPTZ
);

-- ─── 인덱스 (H1 해결: 배당률 SUM 쿼리 최적화) ───

CREATE INDEX IF NOT EXISTS idx_bets_prediction_option
  ON prediction_bets (prediction_id, option_id) INCLUDE (bet_amount);

CREATE INDEX IF NOT EXISTS idx_bets_device
  ON prediction_bets (device_fingerprint, prediction_id);

CREATE INDEX IF NOT EXISTS idx_bets_pending
  ON prediction_bets (prediction_id, status) WHERE status = 'pending';

CREATE INDEX IF NOT EXISTS idx_predictions_status
  ON predictions (status, closes_at) WHERE status IN ('active', 'closed');

-- ─── RLS: anon 전부 차단 (rooms 패턴 동일) ───

ALTER TABLE device_points ENABLE ROW LEVEL SECURITY;
ALTER TABLE predictions ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_bets ENABLE ROW LEVEL SECURITY;
ALTER TABLE prediction_creations ENABLE ROW LEVEL SECURITY;

-- service_role은 RLS 우회하므로 별도 정책 불필요

-- ─── 트리거: updated_at 자동 갱신 ───

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_device_points_updated_at
  BEFORE UPDATE ON device_points
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER tr_predictions_updated_at
  BEFORE UPDATE ON predictions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();


-- ============================================================
-- RPC 함수
-- ============================================================

-- ─── 1. 디바이스 등록 (C2: Device Registry) ───
-- 기존 hardware_hash → 기존 디바이스 반환 (리셋 방지)
-- 신규 → 100 BP 지급

CREATE OR REPLACE FUNCTION register_device(
  p_device_fingerprint TEXT,
  p_hardware_hash TEXT
) RETURNS TABLE(success BOOLEAN, device_fingerprint TEXT, balance INT, is_new BOOLEAN) AS $$
DECLARE
  v_existing_fingerprint TEXT;
  v_balance INT;
BEGIN
  -- C2: hardware_hash로 기존 디바이스 탐색 (리셋 우회 방지)
  IF p_hardware_hash IS NOT NULL AND p_hardware_hash != '' THEN
    SELECT dp.device_fingerprint, dp.balance
    INTO v_existing_fingerprint, v_balance
    FROM device_points dp
    WHERE dp.hardware_hash = p_hardware_hash
    LIMIT 1;

    IF v_existing_fingerprint IS NOT NULL THEN
      RETURN QUERY SELECT TRUE, v_existing_fingerprint, v_balance, FALSE;
      RETURN;
    END IF;
  END IF;

  -- 기존 fingerprint 확인
  SELECT dp.balance INTO v_balance
  FROM device_points dp
  WHERE dp.device_fingerprint = p_device_fingerprint;

  IF v_balance IS NOT NULL THEN
    -- 기존 디바이스: hardware_hash 갱신
    UPDATE device_points
    SET hardware_hash = COALESCE(p_hardware_hash, hardware_hash)
    WHERE device_points.device_fingerprint = p_device_fingerprint;

    RETURN QUERY SELECT TRUE, p_device_fingerprint, v_balance, FALSE;
    RETURN;
  END IF;

  -- 신규 디바이스: 100 BP 지급
  INSERT INTO device_points (device_fingerprint, balance, hardware_hash)
  VALUES (p_device_fingerprint, 100, p_hardware_hash);

  RETURN QUERY SELECT TRUE, p_device_fingerprint, 100, TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ─── 1b. 예측 생성 (원자적: balance 차감 + prediction INSERT) ───

CREATE OR REPLACE FUNCTION create_prediction_atomic(
  p_device_fingerprint TEXT,
  p_question TEXT,
  p_category TEXT,
  p_options JSONB,
  p_closes_at TIMESTAMPTZ,
  p_reveals_at TIMESTAMPTZ,
  p_cost INT,
  p_locale TEXT DEFAULT 'en'
) RETURNS TABLE(success BOOLEAN, prediction_id UUID) AS $$
DECLARE
  v_balance INT;
  v_new_id UUID;
BEGIN
  -- 잔액 확인 + 잠금
  SELECT dp.balance INTO v_balance
  FROM device_points dp
  WHERE dp.device_fingerprint = p_device_fingerprint
  FOR UPDATE;

  IF v_balance IS NULL THEN
    RAISE EXCEPTION '등록되지 않은 디바이스입니다';
  END IF;

  IF v_balance < p_cost THEN
    RAISE EXCEPTION '잔액이 부족합니다 (잔액: %, 비용: %)', v_balance, p_cost;
  END IF;

  -- 잔액 차감
  UPDATE device_points
  SET balance = balance - p_cost,
      total_spent = total_spent + p_cost
  WHERE device_points.device_fingerprint = p_device_fingerprint;

  -- 예측 생성
  INSERT INTO predictions (
    creator_fingerprint, question, category, locale, options,
    closes_at, reveals_at
  ) VALUES (
    p_device_fingerprint, p_question, p_category, p_locale, p_options,
    p_closes_at, p_reveals_at
  ) RETURNING id INTO v_new_id;

  -- 생성 기록
  INSERT INTO prediction_creations (
    prediction_id, creator_fingerprint, creation_cost
  ) VALUES (
    v_new_id, p_device_fingerprint, p_cost
  );

  RETURN QUERY SELECT TRUE, v_new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ─── 2. 배당률 계산 + 베팅 (C1: Idempotency + Race Condition 방지) ───
-- SELECT ... FOR UPDATE 로 원자적 처리
-- idempotency_key 중복 체크
-- 자기 질문 베팅 금지
-- 배당률: (total_pool * 0.9) / option_total, 클램핑 1.05~20.0

CREATE OR REPLACE FUNCTION calculate_odds_and_place_bet(
  p_prediction_id UUID,
  p_device_fingerprint TEXT,
  p_option_id TEXT,
  p_bet_amount INT,
  p_idempotency_key TEXT
) RETURNS TABLE(success BOOLEAN, odds DECIMAL, new_balance INT) AS $$
DECLARE
  v_prediction predictions%ROWTYPE;
  v_balance INT;
  v_option_total INT;
  v_pool_after INT;
  v_odds DECIMAL(8,4);
  v_existing_bet_id UUID;
BEGIN
  -- C1: idempotency_key 중복 체크
  IF p_idempotency_key IS NOT NULL THEN
    SELECT pb.id INTO v_existing_bet_id
    FROM prediction_bets pb
    WHERE pb.idempotency_key = p_idempotency_key;

    IF v_existing_bet_id IS NOT NULL THEN
      -- 이미 처리된 요청 → 기존 결과 반환
      SELECT dp.balance INTO v_balance
      FROM device_points dp
      WHERE dp.device_fingerprint = p_device_fingerprint;

      SELECT pb.odds_at_bet INTO v_odds
      FROM prediction_bets pb
      WHERE pb.idempotency_key = p_idempotency_key;

      RETURN QUERY SELECT TRUE, v_odds, v_balance;
      RETURN;
    END IF;
  END IF;

  -- 베팅 금액 검증 (H3)
  IF p_bet_amount < 1 OR p_bet_amount > 500 THEN
    RAISE EXCEPTION '베팅 금액은 1~500 BP 범위여야 합니다';
  END IF;

  -- 예측 질문 잠금 (FOR UPDATE → race condition 방지)
  SELECT * INTO v_prediction
  FROM predictions
  WHERE id = p_prediction_id
  FOR UPDATE;

  IF v_prediction.id IS NULL THEN
    RAISE EXCEPTION '존재하지 않는 예측 질문입니다';
  END IF;

  IF v_prediction.status != 'active' THEN
    RAISE EXCEPTION '베팅이 마감된 예측입니다 (status: %)', v_prediction.status;
  END IF;

  IF v_prediction.closes_at <= NOW() THEN
    RAISE EXCEPTION '베팅 마감 시간이 지났습니다';
  END IF;

  -- 자기 질문 베팅 금지
  IF v_prediction.creator_fingerprint = p_device_fingerprint THEN
    RAISE EXCEPTION '자신이 생성한 질문에는 베팅할 수 없습니다';
  END IF;

  -- 잔액 확인 + 잠금
  SELECT dp.balance INTO v_balance
  FROM device_points dp
  WHERE dp.device_fingerprint = p_device_fingerprint
  FOR UPDATE;

  IF v_balance IS NULL THEN
    RAISE EXCEPTION '등록되지 않은 디바이스입니다';
  END IF;

  IF v_balance < p_bet_amount THEN
    RAISE EXCEPTION '잔액이 부족합니다 (잔액: %, 베팅: %)', v_balance, p_bet_amount;
  END IF;

  -- 해당 선택지의 현재 베팅 합계
  SELECT COALESCE(SUM(pb.bet_amount), 0) INTO v_option_total
  FROM prediction_bets pb
  WHERE pb.prediction_id = p_prediction_id
    AND pb.option_id = p_option_id
    AND pb.status = 'pending';

  -- 베팅 반영 후 풀 계산
  v_pool_after := v_prediction.total_pool + p_bet_amount;
  v_option_total := v_option_total + p_bet_amount;

  -- 배당률 계산: (total_pool * 0.9) / option_total
  IF v_option_total > 0 THEN
    v_odds := (v_pool_after * 0.9)::DECIMAL / v_option_total;
  ELSE
    v_odds := 20.0;
  END IF;

  -- 배당률 클램핑: 1.05 ~ 20.0
  v_odds := GREATEST(1.05, LEAST(20.0, v_odds));

  -- 원자적 처리: 잔액 차감
  UPDATE device_points
  SET balance = balance - p_bet_amount,
      total_spent = total_spent + p_bet_amount
  WHERE device_points.device_fingerprint = p_device_fingerprint;

  -- 베팅 기록 INSERT
  INSERT INTO prediction_bets (
    prediction_id, device_fingerprint, option_id,
    bet_amount, odds_at_bet, idempotency_key
  ) VALUES (
    p_prediction_id, p_device_fingerprint, p_option_id,
    p_bet_amount, v_odds, p_idempotency_key
  );

  -- total_pool 갱신
  UPDATE predictions
  SET total_pool = v_pool_after
  WHERE id = p_prediction_id;

  -- 갱신된 잔액 반환
  v_balance := v_balance - p_bet_amount;

  RETURN QUERY SELECT TRUE, v_odds, v_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ─── 3. 예측 정산 (C4: 이중 정산 방지 + C5: payout 합계 검증) ───
-- settled_at IS NULL 체크
-- 승리자: payout = bet_amount * odds_at_bet (floor)
-- remainder 방식: 마지막 승리자가 나머지 수령 (C5)
-- Rake 분배: 생성자 50%, 소각 30%, 보상풀 20%
-- 패배자: status='lost', payout=0

CREATE OR REPLACE FUNCTION settle_prediction(
  p_prediction_id UUID,
  p_result_option_id TEXT,
  p_creator_share_percent INT DEFAULT 50
) RETURNS TABLE(success BOOLEAN, total_paid INT, creator_earned INT) AS $$
DECLARE
  v_prediction predictions%ROWTYPE;
  v_total_pool INT;
  v_rake INT;
  v_distributable INT;
  v_creator_share INT;
  v_burn_share INT;
  v_reward_pool_share INT;
  v_winner_bet RECORD;
  v_winner_count INT;
  v_total_payout INT := 0;
  v_payout INT;
  v_winner_idx INT := 0;
  v_remainder INT;
  v_creation RECORD;
BEGIN
  -- C4: 이중 정산 방지 (FOR UPDATE + settled_at 체크)
  SELECT * INTO v_prediction
  FROM predictions
  WHERE id = p_prediction_id
  FOR UPDATE;

  IF v_prediction.id IS NULL THEN
    RAISE EXCEPTION '존재하지 않는 예측 질문입니다';
  END IF;

  IF v_prediction.settled_at IS NOT NULL THEN
    RAISE EXCEPTION '이미 정산된 예측입니다 (settled_at: %)', v_prediction.settled_at;
  END IF;

  IF v_prediction.status NOT IN ('active', 'closed') THEN
    RAISE EXCEPTION '정산할 수 없는 상태입니다 (status: %)', v_prediction.status;
  END IF;

  v_total_pool := v_prediction.total_pool;

  -- Rake 계산 (10%)
  v_rake := FLOOR(v_total_pool * 0.10);
  v_distributable := v_total_pool - v_rake;

  -- Rake 분배
  v_creator_share := FLOOR(v_rake * p_creator_share_percent / 100.0);
  v_burn_share := FLOOR(v_rake * 0.30);
  v_reward_pool_share := v_rake - v_creator_share - v_burn_share;  -- 나머지 = 보상풀

  -- 승리자 수 카운트
  SELECT COUNT(*) INTO v_winner_count
  FROM prediction_bets pb
  WHERE pb.prediction_id = p_prediction_id
    AND pb.option_id = p_result_option_id
    AND pb.status = 'pending';

  -- 승리자가 없으면 전액 Rake 처리
  IF v_winner_count = 0 THEN
    -- 모든 베팅자 패배 처리
    UPDATE prediction_bets
    SET status = 'lost', payout = 0, settled_at = NOW()
    WHERE prediction_bets.prediction_id = p_prediction_id
      AND prediction_bets.status = 'pending';

    -- 생성자 보상
    UPDATE device_points
    SET balance = balance + v_creator_share,
        total_earned = total_earned + v_creator_share
    WHERE device_points.device_fingerprint = v_prediction.creator_fingerprint;

    -- 생성 기록 갱신
    UPDATE prediction_creations
    SET total_earned = v_creator_share, settled_at = NOW()
    WHERE prediction_creations.prediction_id = p_prediction_id;

    -- 예측 상태 갱신
    UPDATE predictions
    SET status = 'settled',
        correct_answer = p_result_option_id,
        settled_at = NOW()
    WHERE id = p_prediction_id;

    RETURN QUERY SELECT TRUE, 0, v_creator_share;
    RETURN;
  END IF;

  -- 승리자 payout 계산 (C5: remainder 방식)
  FOR v_winner_bet IN
    SELECT pb.id, pb.device_fingerprint, pb.bet_amount, pb.odds_at_bet
    FROM prediction_bets pb
    WHERE pb.prediction_id = p_prediction_id
      AND pb.option_id = p_result_option_id
      AND pb.status = 'pending'
    ORDER BY pb.created_at ASC
  LOOP
    v_winner_idx := v_winner_idx + 1;
    v_payout := FLOOR(v_winner_bet.bet_amount * v_winner_bet.odds_at_bet);

    -- 마지막 승리자: 나머지 수령 (C5 해결)
    IF v_winner_idx = v_winner_count THEN
      v_remainder := v_distributable - v_total_payout - v_payout;
      IF v_remainder > 0 THEN
        v_payout := v_payout + v_remainder;
      END IF;
      -- 분배액 초과 방지
      IF v_total_payout + v_payout > v_distributable THEN
        v_payout := v_distributable - v_total_payout;
      END IF;
    END IF;

    -- payout이 0 이하가 되지 않도록
    v_payout := GREATEST(0, v_payout);
    v_total_payout := v_total_payout + v_payout;

    -- 베팅 기록 갱신
    UPDATE prediction_bets
    SET status = 'won', payout = v_payout, settled_at = NOW()
    WHERE prediction_bets.id = v_winner_bet.id;

    -- 승리자 잔액 지급
    UPDATE device_points
    SET balance = balance + v_payout,
        total_won = total_won + v_payout,
        total_earned = total_earned + v_payout
    WHERE device_points.device_fingerprint = v_winner_bet.device_fingerprint;
  END LOOP;

  -- C5: SUM(payout) 검증 assertion
  IF v_total_payout > v_distributable THEN
    RAISE EXCEPTION '정산 오류: payout 합계(%)가 분배 가능 금액(%)을 초과합니다',
      v_total_payout, v_distributable;
  END IF;

  -- 패배자 처리
  UPDATE prediction_bets
  SET status = 'lost', payout = 0, settled_at = NOW()
  WHERE prediction_bets.prediction_id = p_prediction_id
    AND prediction_bets.option_id != p_result_option_id
    AND prediction_bets.status = 'pending';

  -- 패배자 total_lost 갱신
  UPDATE device_points dp
  SET total_lost = dp.total_lost + pb.bet_amount
  FROM prediction_bets pb
  WHERE dp.device_fingerprint = pb.device_fingerprint
    AND pb.prediction_id = p_prediction_id
    AND pb.status = 'lost';

  -- 생성자 보상 지급
  UPDATE device_points
  SET balance = balance + v_creator_share,
      total_earned = total_earned + v_creator_share
  WHERE device_points.device_fingerprint = v_prediction.creator_fingerprint;

  -- 생성 기록 갱신
  UPDATE prediction_creations
  SET total_earned = v_creator_share, settled_at = NOW()
  WHERE prediction_creations.prediction_id = p_prediction_id;

  -- 예측 상태 갱신
  UPDATE predictions
  SET status = 'settled',
      correct_answer = p_result_option_id,
      settled_at = NOW()
  WHERE id = p_prediction_id;

  RETURN QUERY SELECT TRUE, v_total_payout, v_creator_share;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ─── 4. 이틀마다 보상 (1 BP) ───
-- 48시간 체크 + 7일 내 베팅 존재 확인

CREATE OR REPLACE FUNCTION claim_daily_reward(
  p_device_fingerprint TEXT
) RETURNS TABLE(success BOOLEAN, new_balance INT) AS $$
DECLARE
  v_device device_points%ROWTYPE;
  v_has_recent_bet BOOLEAN;
  v_new_balance INT;
BEGIN
  -- 디바이스 잠금
  SELECT * INTO v_device
  FROM device_points dp
  WHERE dp.device_fingerprint = p_device_fingerprint
  FOR UPDATE;

  IF v_device.device_fingerprint IS NULL THEN
    RAISE EXCEPTION '등록되지 않은 디바이스입니다';
  END IF;

  -- 48시간 체크
  IF v_device.last_daily_reward_at IS NOT NULL
     AND v_device.last_daily_reward_at > NOW() - INTERVAL '48 hours' THEN
    RAISE EXCEPTION '보상을 받을 수 있는 시간이 아닙니다 (48시간 간격)';
  END IF;

  -- 7일 내 베팅 존재 확인 (팜 방지)
  SELECT EXISTS(
    SELECT 1 FROM prediction_bets pb
    WHERE pb.device_fingerprint = p_device_fingerprint
      AND pb.created_at > NOW() - INTERVAL '7 days'
  ) INTO v_has_recent_bet;

  IF NOT v_has_recent_bet THEN
    RAISE EXCEPTION '최근 7일 내 베팅 기록이 없습니다 (활동 조건 미충족)';
  END IF;

  -- 1 BP 지급
  UPDATE device_points
  SET balance = balance + 1,
      total_earned = total_earned + 1,
      last_daily_reward_at = NOW()
  WHERE device_points.device_fingerprint = p_device_fingerprint
  RETURNING balance INTO v_new_balance;

  RETURN QUERY SELECT TRUE, v_new_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ─── 5. 예측 삭제 + 전액 환불 (H7: 타임아웃 자동 환불) ───
-- 모든 베팅자에게 bet_amount 환불
-- 생성자에게 creation_cost 환불
-- prediction status='cancelled'

CREATE OR REPLACE FUNCTION delete_prediction_and_refund(
  p_prediction_id UUID
) RETURNS BOOLEAN AS $$
DECLARE
  v_prediction predictions%ROWTYPE;
  v_bet RECORD;
  v_creation RECORD;
BEGIN
  -- 예측 잠금
  SELECT * INTO v_prediction
  FROM predictions
  WHERE id = p_prediction_id
  FOR UPDATE;

  IF v_prediction.id IS NULL THEN
    RAISE EXCEPTION '존재하지 않는 예측 질문입니다';
  END IF;

  IF v_prediction.status IN ('settled', 'cancelled') THEN
    RAISE EXCEPTION '이미 정산 또는 취소된 예측입니다 (status: %)', v_prediction.status;
  END IF;

  -- 모든 pending 베팅자에게 환불
  FOR v_bet IN
    SELECT pb.id, pb.device_fingerprint, pb.bet_amount
    FROM prediction_bets pb
    WHERE pb.prediction_id = p_prediction_id
      AND pb.status = 'pending'
    FOR UPDATE
  LOOP
    -- 잔액 환불
    UPDATE device_points
    SET balance = balance + v_bet.bet_amount,
        total_earned = total_earned + v_bet.bet_amount
    WHERE device_points.device_fingerprint = v_bet.device_fingerprint;

    -- 베팅 상태 변경
    UPDATE prediction_bets
    SET status = 'refunded', payout = v_bet.bet_amount, settled_at = NOW()
    WHERE prediction_bets.id = v_bet.id;
  END LOOP;

  -- 생성자에게 creation_cost 환불
  SELECT * INTO v_creation
  FROM prediction_creations pc
  WHERE pc.prediction_id = p_prediction_id
  LIMIT 1;

  IF v_creation.id IS NOT NULL THEN
    UPDATE device_points
    SET balance = balance + v_creation.creation_cost,
        total_earned = total_earned + v_creation.creation_cost
    WHERE device_points.device_fingerprint = v_creation.creator_fingerprint;

    UPDATE prediction_creations
    SET settled_at = NOW()
    WHERE prediction_creations.id = v_creation.id;
  END IF;

  -- 예측 상태 변경
  UPDATE predictions
  SET status = 'cancelled', settled_at = NOW()
  WHERE id = p_prediction_id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================
-- pg_cron 스케줄
-- ============================================================

-- 매 2분: active → closed (마감 시간 도달)
SELECT cron.schedule(
  'close-expired-predictions',
  '*/2 * * * *',
  $$
    UPDATE predictions
    SET status = 'closed'
    WHERE status = 'active'
      AND closes_at <= NOW();
  $$
);

-- 매 2분: closed + reveals_at 도달 + 24시간 초과 → 자동 환불 (H7)
SELECT cron.schedule(
  'auto-refund-stale-predictions',
  '*/2 * * * *',
  $$
    SELECT delete_prediction_and_refund(id)
    FROM predictions
    WHERE status = 'closed'
      AND reveals_at <= NOW()
      AND reveals_at + INTERVAL '24 hours' < NOW()
      AND settled_at IS NULL;
  $$
);

-- 데이터 영구 보존: 베팅/예측 기록 삭제 크론 없음
-- 유저가 과거 투표 히스토리를 계속 조회할 수 있도록 함
