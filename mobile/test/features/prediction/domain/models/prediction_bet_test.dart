import 'package:flutter_test/flutter_test.dart';
import 'package:blip/features/prediction/domain/models/prediction_bet.dart';

void main() {
  group('PredictionBet', () {
    final now = DateTime(2026, 3, 26);
    final settled = DateTime(2026, 3, 27);

    PredictionBet create({
      BetStatus status = BetStatus.pending,
      int betAmount = 100,
      double oddsAtBet = 2.5,
    }) =>
        PredictionBet(
          id: 'bet-001',
          predictionId: 'pred-001',
          deviceFingerprint: 'fp-abc123',
          optionId: 'opt-a',
          betAmount: betAmount,
          oddsAtBet: oddsAtBet,
          status: status,
          payout: status == BetStatus.won ? 250 : null,
          createdAt: now,
          settledAt: status != BetStatus.pending ? settled : null,
        );

    test('생성 시 모든 필드 정상 할당', () {
      final bet = create();

      expect(bet.id, 'bet-001');
      expect(bet.predictionId, 'pred-001');
      expect(bet.deviceFingerprint, 'fp-abc123');
      expect(bet.optionId, 'opt-a');
      expect(bet.betAmount, 100);
      expect(bet.oddsAtBet, 2.5);
      expect(bet.status, BetStatus.pending);
      expect(bet.payout, isNull);
      expect(bet.createdAt, now);
      expect(bet.settledAt, isNull);
    });

    test('fromJson / toJson 왕복 일치', () {
      final bet = create(status: BetStatus.won);
      final json = bet.toJson();
      final restored = PredictionBet.fromJson(json);

      expect(restored.id, bet.id);
      expect(restored.predictionId, bet.predictionId);
      expect(restored.deviceFingerprint, bet.deviceFingerprint);
      expect(restored.optionId, bet.optionId);
      expect(restored.betAmount, bet.betAmount);
      expect(restored.oddsAtBet, bet.oddsAtBet);
      expect(restored.status, bet.status);
      expect(restored.payout, bet.payout);
      expect(restored.createdAt, bet.createdAt);
      expect(restored.settledAt, bet.settledAt);
    });

    test('isPending: status=pending → true', () {
      expect(create(status: BetStatus.pending).isPending, isTrue);
    });

    test('isPending: status=won → false', () {
      expect(create(status: BetStatus.won).isPending, isFalse);
    });

    test('expectedPayout: amount=100, odds=2.5 → 250', () {
      expect(create(betAmount: 100, oddsAtBet: 2.5).expectedPayout, 250);
    });

    test('expectedPayout: amount=33, odds=1.5 → 49 (floor)', () {
      expect(create(betAmount: 33, oddsAtBet: 1.5).expectedPayout, 49);
    });
  });
}
