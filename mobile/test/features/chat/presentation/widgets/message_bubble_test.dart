import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/chat/domain/models/message.dart';
import 'package:blip/features/chat/presentation/widgets/message_bubble.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('MessageBubble - text', () {
    testWidgets('텍스트 메시지 표시', (tester) async {
      const msg = DecryptedMessage(
        id: 't1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: 'Hello World!',
        timestamp: 1700000000000,
        isMine: false,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestApp(
        const MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('Hello World!'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('내 메시지: 발신자 이름 미표시', (tester) async {
      const msg = DecryptedMessage(
        id: 't2',
        senderId: 'me',
        senderName: 'Me',
        content: 'My text',
        timestamp: 1700000001000,
        isMine: true,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestApp(
        const MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('My text'), findsOneWidget);
      expect(find.text('Me'), findsNothing);
    });

    testWidgets('시스템 메시지 표시', (tester) async {
      const msg = DecryptedMessage(
        id: 's1',
        senderId: 'system',
        senderName: 'System',
        content: 'User joined',
        timestamp: 1700000002000,
        isMine: false,
        type: MessageType.text,
      );

      await tester.pumpWidget(createTestApp(
        const MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('User joined'), findsOneWidget);
    });
  });

  group('MessageBubble - image', () {
    testWidgets('이미지 메시지: Image.memory 렌더링', (tester) async {
      // 1x1 transparent PNG
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00,
        0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
        0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62,
        0x00, 0x00, 0x00, 0x02, 0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final msg = DecryptedMessage(
        id: 'i1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000003000,
        isMine: false,
        type: MessageType.image,
        mediaBytes: pngBytes,
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      // Image.memory가 렌더링됨
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('MessageBubble - video', () {
    testWidgets('비디오 메시지: 재생 버튼 오버레이 표시', (tester) async {
      final msg = DecryptedMessage(
        id: 'v1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000004000,
        isMine: false,
        type: MessageType.video,
        mediaBytes: Uint8List.fromList([0, 1, 2, 3]),
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('비디오 썸네일 없으면 videocam 아이콘', (tester) async {
      final msg = DecryptedMessage(
        id: 'v2',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000005000,
        isMine: true,
        type: MessageType.video,
        mediaBytes: Uint8List.fromList([0]),
        mediaThumbnailBytes: null,
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.videocam), findsOneWidget);
    });
  });
}
