import 'package:flutter_test/flutter_test.dart';
import 'package:blip/features/group_chat/domain/models/group_message.dart';

void main() {
  group('GroupMessage', () {
    test('생성 시 모든 필드 정상 할당', () {
      const msg = GroupMessage(
        id: 'msg-1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: 'Hello group!',
        timestamp: 1700000000000,
        isMine: true,
      );

      expect(msg.id, 'msg-1');
      expect(msg.senderId, 'user-1');
      expect(msg.senderName, 'Alice');
      expect(msg.content, 'Hello group!');
      expect(msg.timestamp, 1700000000000);
      expect(msg.isMine, isTrue);
    });

    test('isMine false 설정', () {
      const msg = GroupMessage(
        id: 'msg-2',
        senderId: 'user-2',
        senderName: 'Bob',
        content: 'Hi!',
        timestamp: 1700000001000,
        isMine: false,
      );

      expect(msg.isMine, isFalse);
    });

    test('시스템 메시지 (senderId == system)', () {
      const msg = GroupMessage(
        id: 'sys-1',
        senderId: 'system',
        senderName: 'System',
        content: 'Alice joined',
        timestamp: 1700000002000,
        isMine: false,
      );

      expect(msg.senderId, 'system');
      expect(msg.content, 'Alice joined');
    });

    test('빈 content 허용', () {
      const msg = GroupMessage(
        id: 'msg-3',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000003000,
        isMine: true,
      );

      expect(msg.content, isEmpty);
    });
  });
}
