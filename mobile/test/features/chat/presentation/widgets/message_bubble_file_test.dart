import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/chat/domain/models/message.dart';
import 'package:blip/features/chat/presentation/widgets/message_bubble.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('MessageBubble - file type', () {
    testWidgets('파일 메시지 버블 렌더링', (tester) async {
      final msg = DecryptedMessage(
        id: 'f1',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000000000,
        isMine: false,
        type: MessageType.file,
        mediaBytes: Uint8List.fromList([0, 1, 2, 3]),
        mediaMetadata: const MediaMetadata(
          fileName: 'document.pdf',
          mimeType: 'application/pdf',
          size: 1048576,
        ),
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.text('document.pdf'), findsOneWidget);
    });

    testWidgets('파일 크기 표시', (tester) async {
      final msg = DecryptedMessage(
        id: 'f2',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000000000,
        isMine: false,
        type: MessageType.file,
        mediaBytes: Uint8List.fromList([0, 1, 2]),
        mediaMetadata: const MediaMetadata(
          fileName: 'photo.zip',
          mimeType: 'application/zip',
          size: 2097152,
        ),
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      // 2MB
      expect(find.text('2.0MB'), findsOneWidget);
    });

    testWidgets('다운로드 아이콘 표시 (mediaBytes 존재 시)', (tester) async {
      final msg = DecryptedMessage(
        id: 'f3',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000000000,
        isMine: true,
        type: MessageType.file,
        mediaBytes: Uint8List.fromList([0]),
        mediaMetadata: const MediaMetadata(
          fileName: 'readme.txt',
          mimeType: 'text/plain',
          size: 512,
        ),
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.download), findsOneWidget);
    });

    testWidgets('파일 아이콘 이모지 표시', (tester) async {
      final msg = DecryptedMessage(
        id: 'f4',
        senderId: 'user-1',
        senderName: 'Alice',
        content: '',
        timestamp: 1700000000000,
        isMine: false,
        type: MessageType.file,
        mediaBytes: Uint8List.fromList([0]),
        mediaMetadata: const MediaMetadata(
          fileName: 'report.pdf',
          mimeType: 'application/pdf',
          size: 1024,
        ),
      );

      await tester.pumpWidget(createTestApp(
        MessageBubble(message: msg),
      ));
      await tester.pump();

      // PDF 파일은 📄 이모지
      expect(find.text('📄'), findsOneWidget);
    });
  });
}
