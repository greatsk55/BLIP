import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/group_chat/presentation/widgets/group_created_view.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  const testRoomId = 'GRP12345';
  const testPassword = 'PASS-6789';
  const testAdminToken = 'ADM-TOKEN-XYZ';
  const testBaseUrl = 'https://blip-blip.vercel.app';

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=$testBaseUrl');
  });

  Widget buildWidget() {
    return createTestApp(
      GroupCreatedView(
        roomId: testRoomId,
        password: testPassword,
        adminToken: testAdminToken,
        onEnterChat: () {},
      ),
    );
  }

  group('GroupCreatedView', () {
    testWidgets('비밀번호 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text(testPassword), findsOneWidget);
    });

    testWidgets('관리자 토큰 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text(testAdminToken), findsOneWidget);
    });

    testWidgets('공유 링크 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      final expectedLink =
          '$testBaseUrl/group/$testRoomId?k=${Uri.encodeComponent(testPassword)}';
      expect(find.text(expectedLink), findsOneWidget);
    });

    testWidgets('입장 버튼 존재', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('Enter Chat Room'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('입장 버튼 탭 시 콜백 호출', (tester) async {
      var called = false;
      await tester.pumpWidget(createTestApp(
        GroupCreatedView(
          roomId: testRoomId,
          password: testPassword,
          adminToken: testAdminToken,
          onEnterChat: () => called = true,
        ),
      ));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Enter Chat Room'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enter Chat Room'));
      expect(called, isTrue);
    });

    testWidgets('ACCESS KEY 라벨 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('ACCESS KEY'), findsOneWidget);
    });

    testWidgets('ADMIN TOKEN 라벨 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('ADMIN TOKEN'), findsOneWidget);
    });

    testWidgets('SHARE LINK 라벨 표시', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pump();

      expect(find.text('SHARE LINK'), findsOneWidget);
    });
  });
}
