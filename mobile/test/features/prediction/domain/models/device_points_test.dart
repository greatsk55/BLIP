import 'package:flutter_test/flutter_test.dart';
import 'package:blip/features/prediction/domain/models/device_points.dart';

void main() {
  group('DevicePoints', () {
    final now = DateTime(2026, 3, 26);

    DevicePoints create({int balance = 100}) => DevicePoints(
          deviceFingerprint: 'fp-abc123',
          balance: balance,
          totalEarned: 500,
          totalSpent: 300,
          totalWon: 200,
          totalLost: 100,
          lastDailyRewardAt: now,
          createdAt: now,
        );

    test('생성 시 모든 필드 정상 할당', () {
      final dp = create();

      expect(dp.deviceFingerprint, 'fp-abc123');
      expect(dp.balance, 100);
      expect(dp.totalEarned, 500);
      expect(dp.totalSpent, 300);
      expect(dp.totalWon, 200);
      expect(dp.totalLost, 100);
      expect(dp.lastDailyRewardAt, now);
      expect(dp.createdAt, now);
    });

    test('copyWith으로 balance만 변경', () {
      final dp = create();
      final updated = dp.copyWith(balance: 999);

      expect(updated.balance, 999);
      expect(updated.deviceFingerprint, dp.deviceFingerprint);
      expect(updated.totalEarned, dp.totalEarned);
      expect(updated.createdAt, dp.createdAt);
    });

    test('fromJson / toJson 왕복 일치', () {
      final dp = create();
      final json = dp.toJson();
      final restored = DevicePoints.fromJson(json);

      expect(restored.deviceFingerprint, dp.deviceFingerprint);
      expect(restored.balance, dp.balance);
      expect(restored.totalEarned, dp.totalEarned);
      expect(restored.totalSpent, dp.totalSpent);
      expect(restored.totalWon, dp.totalWon);
      expect(restored.totalLost, dp.totalLost);
      expect(restored.lastDailyRewardAt, dp.lastDailyRewardAt);
      expect(restored.createdAt, dp.createdAt);
    });

    test('rank 계산: 0 → Static', () {
      expect(create(balance: 0).rank, 'Static');
    });

    test('rank 계산: 5 → Receiver', () {
      expect(create(balance: 5).rank, 'Receiver');
    });

    test('rank 계산: 50 → Signal', () {
      expect(create(balance: 50).rank, 'Signal');
    });

    test('rank 계산: 200 → Decoder', () {
      expect(create(balance: 200).rank, 'Decoder');
    });

    test('rank 계산: 1000 → Control', () {
      expect(create(balance: 1000).rank, 'Control');
    });

    test('rank 계산: 5000 → Oracle', () {
      expect(create(balance: 5000).rank, 'Oracle');
    });

    test('경계값: 4 → Static, 5 → Receiver', () {
      expect(create(balance: 4).rank, 'Static');
      expect(create(balance: 5).rank, 'Receiver');
    });

    test('canAfford: balance=100, cost=150 → false', () {
      expect(create(balance: 100).canAfford(150), isFalse);
    });

    test('canAfford: balance=200, cost=150 → true', () {
      expect(create(balance: 200).canAfford(150), isTrue);
    });

    test('creationCost: 기본 150', () {
      expect(create(balance: 50).creationCost, 150);
    });

    test('creationCost: Control → 120 (20% 할인)', () {
      expect(create(balance: 1000).creationCost, 120);
    });

    test('creationCost: Oracle → 75 (50% 할인)', () {
      expect(create(balance: 5000).creationCost, 75);
    });
  });
}
