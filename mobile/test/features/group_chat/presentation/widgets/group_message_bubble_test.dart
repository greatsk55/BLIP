import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/group_chat/domain/models/group_message.dart';
import 'package:blip/features/group_chat/presentation/widgets/group_message_bubble.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('GroupMessageBubble', () {
    testWidgets('메시지 텍스트 표시', (tester) async {
      const msg = GroupMessage(
        id: '1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: 'Hello everyone!',
        timestamp: 1700000000000,
        isMine: false,
      );

      await tester.pumpWidget(createTestApp(
        const GroupMessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('Hello everyone!'), findsOneWidget);
    });

    testWidgets('상대 메시지: 발신자 이름 표시', (tester) async {
      const msg = GroupMessage(
        id: '2',
        senderId: 'user-2',
        senderName: 'Bob',
        content: 'Hi there!',
        timestamp: 1700000001000,
        isMine: false,
      );

      await tester.pumpWidget(createTestApp(
        const GroupMessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('내 메시지: 발신자 이름 미표시', (tester) async {
      const msg = GroupMessage(
        id: '3',
        senderId: 'me',
        senderName: 'Me',
        content: 'My message',
        timestamp: 1700000002000,
        isMine: true,
      );

      await tester.pumpWidget(createTestApp(
        const GroupMessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('My message'), findsOneWidget);
      // 내 메시지에는 발신자 이름이 표시되지 않음
      expect(find.text('Me'), findsNothing);
    });

    testWidgets('시스템 메시지: 중앙 정렬, 이름 미표시', (tester) async {
      const msg = GroupMessage(
        id: '4',
        senderId: 'system',
        senderName: 'System',
        content: 'Alice joined the chat',
        timestamp: 1700000003000,
        isMine: false,
      );

      await tester.pumpWidget(createTestApp(
        const GroupMessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('Alice joined the chat'), findsOneWidget);
      // 시스템 메시지는 Center 위젯 사용
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('내 메시지 vs 상대 메시지 정렬 구분', (tester) async {
      const myMsg = GroupMessage(
        id: '5',
        senderId: 'me',
        senderName: 'Me',
        content: 'Mine',
        timestamp: 1700000004000,
        isMine: true,
      );
      const otherMsg = GroupMessage(
        id: '6',
        senderId: 'other',
        senderName: 'Other',
        content: 'Theirs',
        timestamp: 1700000005000,
        isMine: false,
      );

      // 내 메시지 - CrossAxisAlignment.end
      await tester.pumpWidget(createTestApp(
        const GroupMessageBubble(message: myMsg),
      ));
      await tester.pump();

      final myColumn = tester.widget<Column>(find.byType(Column).last);
      expect(myColumn.crossAxisAlignment, CrossAxisAlignment.end);

      // 상대 메시지 - CrossAxisAlignment.start
      await tester.pumpWidget(createTestApp(
        const GroupMessageBubble(message: otherMsg),
      ));
      await tester.pump();

      final otherColumn = tester.widget<Column>(find.byType(Column).last);
      expect(otherColumn.crossAxisAlignment, CrossAxisAlignment.start);
    });
  });
}
