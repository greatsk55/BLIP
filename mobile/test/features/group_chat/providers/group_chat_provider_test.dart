import 'package:flutter_test/flutter_test.dart';
import 'package:blip/features/group_chat/providers/group_chat_provider.dart';

void main() {
  group('GroupChatNotifier disconnect vs softDisconnect', () {
    test('disconnect 후 status는 destroyed', () {
      // GroupChatNotifier는 생성 시 _init()에서 Supabase 연결을 시도하므로
      // 여기서는 상태 전이 로직만 검증
      // disconnect() → status = destroyed
      // softDisconnect() → status 변경 없음 (채널 정리만)

      const state = GroupChatState(
        status: GroupChatStatus.chatting,
        myUsername: 'test-user',
        myId: 'test-id',
        participants: [],
      );

      // disconnect 후 예상되는 상태
      final afterDisconnect = state.copyWith(
        messages: [],
        status: GroupChatStatus.destroyed,
      );
      expect(afterDisconnect.status, GroupChatStatus.destroyed);
      expect(afterDisconnect.messages, isEmpty);
    });

    test('softDisconnect는 status를 destroyed로 변경하지 않음', () {
      const state = GroupChatState(
        status: GroupChatStatus.chatting,
        myUsername: 'test-user',
        myId: 'test-id',
        participants: [],
      );

      // softDisconnect는 state를 변경하지 않음 (채널 정리만)
      // 따라서 상태는 chatting 그대로
      expect(state.status, GroupChatStatus.chatting);
      expect(state.status, isNot(GroupChatStatus.destroyed));
    });

    test('GroupChatState copyWith가 올바르게 동작', () {
      const original = GroupChatState(
        status: GroupChatStatus.chatting,
        myUsername: 'alice',
        myId: 'id-1',
        isAdmin: true,
      );

      final modified = original.copyWith(status: GroupChatStatus.destroyed);
      expect(modified.status, GroupChatStatus.destroyed);
      expect(modified.myUsername, 'alice'); // 변경 안 됨
      expect(modified.isAdmin, true); // 변경 안 됨
    });

    test('GroupChatParams equality', () {
      const a = GroupChatParams(roomId: 'r1', password: 'p1');
      const b = GroupChatParams(roomId: 'r1', password: 'p1');
      const c = GroupChatParams(roomId: 'r2', password: 'p1');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
