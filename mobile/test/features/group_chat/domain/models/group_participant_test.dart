import 'package:flutter_test/flutter_test.dart';
import 'package:blip/features/group_chat/domain/models/group_participant.dart';

void main() {
  group('GroupParticipant', () {
    test('생성 시 모든 필드 정상 할당', () {
      const p = GroupParticipant(
        userId: 'user-1',
        username: 'Alice',
        joinedAt: 1700000000000,
        isAdmin: true,
      );

      expect(p.userId, 'user-1');
      expect(p.username, 'Alice');
      expect(p.joinedAt, 1700000000000);
      expect(p.isAdmin, isTrue);
    });

    test('isAdmin 기본값 false', () {
      const p = GroupParticipant(
        userId: 'user-2',
        username: 'Bob',
      );

      expect(p.isAdmin, isFalse);
      expect(p.joinedAt, isNull);
    });

    test('joinedAt nullable', () {
      const p = GroupParticipant(
        userId: 'user-3',
        username: 'Charlie',
        isAdmin: false,
      );

      expect(p.joinedAt, isNull);
    });
  });
}
