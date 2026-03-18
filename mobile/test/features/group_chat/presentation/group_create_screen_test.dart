import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:blip/features/group_chat/presentation/group_create_screen.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://blip-blip.vercel.app');
  });

  group('GroupCreateScreen', () {
    testWidgets('제목 입력 필드 존재', (tester) async {
      await tester.pumpWidget(createTestApp(const GroupCreateScreen()));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('생성 버튼 존재', (tester) async {
      await tester.pumpWidget(createTestApp(const GroupCreateScreen()));
      await tester.pump();

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Create Group'), findsOneWidget);
    });

    testWidgets('그룹 아이콘 표시', (tester) async {
      await tester.pumpWidget(createTestApp(const GroupCreateScreen()));
      await tester.pump();

      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('제목 입력 가능', (tester) async {
      await tester.pumpWidget(createTestApp(const GroupCreateScreen()));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'My Group');
      expect(find.text('My Group'), findsOneWidget);
    });
  });
}
