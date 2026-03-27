-- ============================================================
-- 예측 시드 데이터 (로케일별)
-- 실행: Supabase SQL Editor에서 1회 실행
-- ============================================================

-- 시스템 디바이스 (시드 데이터 생성자)
INSERT INTO device_points (device_fingerprint, balance, total_earned, hardware_hash)
VALUES ('system-seed', 99999, 99999, 'system')
ON CONFLICT (device_fingerprint) DO NOTHING;

-- ─── English ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', 'Will Bitcoin break $100k by end of 2026?', 'economy', 'en', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'Will AI replace 50% of customer service jobs by 2028?', 'tech', 'en', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', 'Will the next US president be a woman?', 'politics', 'en', '["yes","no"]',
   NOW() + INTERVAL '30 days', NOW() + INTERVAL '31 days'),
  ('system-seed', 'Will a team outside Europe win the next World Cup?', 'sports', 'en', '["yes","no"]',
   NOW() + INTERVAL '21 days', NOW() + INTERVAL '22 days'),
  ('system-seed', 'Will GTA 6 release before December 2026?', 'gaming', 'en', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── 한국어 ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', '비트코인이 2026년 안에 1억 5천만원을 돌파할까?', 'economy', 'ko', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'AI가 2028년까지 고객센터 업무의 50%를 대체할까?', 'tech', 'ko', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', '다음 한국 대선에서 여성 대통령이 탄생할까?', 'politics', 'ko', '["yes","no"]',
   NOW() + INTERVAL '30 days', NOW() + INTERVAL '31 days'),
  ('system-seed', '손흥민이 2026년에도 토트넘에서 뛸까?', 'sports', 'ko', '["yes","no"]',
   NOW() + INTERVAL '21 days', NOW() + INTERVAL '22 days'),
  ('system-seed', 'GTA 6가 2026년 12월 전에 출시될까?', 'gaming', 'ko', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── 日本語 ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', 'ビットコインは2026年末までに10万ドルを突破するか？', 'economy', 'ja', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'AIは2028年までにカスタマーサービスの50%を代替するか？', 'tech', 'ja', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', '大谷翔平は2026年にMVPを獲得するか？', 'sports', 'ja', '["yes","no"]',
   NOW() + INTERVAL '21 days', NOW() + INTERVAL '22 days'),
  ('system-seed', 'GTA 6は2026年12月前にリリースされるか？', 'gaming', 'ja', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── 中文 (简体) ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', '比特币会在2026年底突破10万美元吗？', 'economy', 'zh', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'AI会在2028年前取代50%的客服工作吗？', 'tech', 'zh', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', 'GTA 6会在2026年12月前发售吗？', 'gaming', 'zh', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── 中文 (繁體) ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', '比特幣會在2026年底突破10萬美元嗎？', 'economy', 'zh-TW', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'AI會在2028年前取代50%的客服工作嗎？', 'tech', 'zh-TW', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', 'GTA 6會在2026年12月前發售嗎？', 'gaming', 'zh-TW', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── Español ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', '¿Bitcoin superará los $100k antes de fin de 2026?', 'economy', 'es', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', '¿La IA reemplazará el 50% de los empleos de atención al cliente para 2028?', 'tech', 'es', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', '¿GTA 6 se lanzará antes de diciembre de 2026?', 'gaming', 'es', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── Français ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', 'Le Bitcoin dépassera-t-il 100 000 $ avant fin 2026 ?', 'economy', 'fr', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'L''IA remplacera-t-elle 50 % des emplois de service client d''ici 2028 ?', 'tech', 'fr', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', 'GTA 6 sortira-t-il avant décembre 2026 ?', 'gaming', 'fr', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');

-- ─── Deutsch ───

INSERT INTO predictions (creator_fingerprint, question, category, locale, options, closes_at, reveals_at)
VALUES
  ('system-seed', 'Wird Bitcoin bis Ende 2026 die 100.000 $-Marke durchbrechen?', 'economy', 'de', '["yes","no"]',
   NOW() + INTERVAL '7 days', NOW() + INTERVAL '8 days'),
  ('system-seed', 'Wird KI bis 2028 50 % der Kundenservice-Jobs ersetzen?', 'tech', 'de', '["yes","no"]',
   NOW() + INTERVAL '14 days', NOW() + INTERVAL '15 days'),
  ('system-seed', 'Wird GTA 6 vor Dezember 2026 erscheinen?', 'gaming', 'de', '["yes","no"]',
   NOW() + INTERVAL '10 days', NOW() + INTERVAL '11 days');
