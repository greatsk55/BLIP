import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/chat/presentation/widgets/room_created_view.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  const testRoomId = 'ABCD1234';
  const testPassword = 'WXYZ-5678';
  const testBaseUrl = 'https://blip-blip.vercel.app';

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=$testBaseUrl');
  });

  group('RoomCreatedView', () {
    testWidgets('기본 상태: 비밀번호 항상 표시, 링크에 ?k= 포함', (tester) async {
      await tester.pumpWidget(createTestApp(
        RoomCreatedView(roomId: testRoomId, password: testPassword),
      ));
      await tester.pump();

      // ACCESS KEY 라벨 표시 (uppercase)
      expect(find.text('ACCESS KEY'), findsOneWidget);

      // 비밀번호 값 표시
      expect(find.text(testPassword), findsOneWidget);

      // SHARE LINK 라벨 표시
      expect(find.text('SHARE LINK'), findsOneWidget);

      // 링크에 ?k= 포함 (includeKey 기본값 true)
      final expectedLink =
          '$testBaseUrl/room/$testRoomId?k=${Uri.encodeComponent(testPassword)}';
      expect(find.text(expectedLink), findsOneWidget);
    });

    testWidgets('토글 OFF: 링크에서 ?k= 제거, 비밀번호는 여전히 표시',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        RoomCreatedView(roomId: testRoomId, password: testPassword),
      ));
      await tester.pump();

      // 토글 텍스트로 GestureDetector 찾아서 탭
      final toggleFinder = find.text('INCLUDE PASSWORD IN LINK');
      expect(toggleFinder, findsOneWidget);
      await tester.tap(toggleFinder);
      await tester.pump();

      // 비밀번호는 여전히 표시 (항상 보임)
      expect(find.text(testPassword), findsOneWidget);

      // 링크에 ?k= 미포함
      final plainLink = '$testBaseUrl/room/$testRoomId';
      expect(find.text(plainLink), findsOneWidget);
    });

    testWidgets('토글 ON → OFF → ON 반복 시 링크 변경', (tester) async {
      await tester.pumpWidget(createTestApp(
        RoomCreatedView(roomId: testRoomId, password: testPassword),
      ));
      await tester.pump();

      final toggleFinder = find.text('INCLUDE PASSWORD IN LINK');
      final linkWithKey =
          '$testBaseUrl/room/$testRoomId?k=${Uri.encodeComponent(testPassword)}';
      final linkWithoutKey = '$testBaseUrl/room/$testRoomId';

      // 초기: ?k= 포함
      expect(find.text(linkWithKey), findsOneWidget);

      // OFF: ?k= 제거
      await tester.tap(toggleFinder);
      await tester.pump();
      expect(find.text(linkWithoutKey), findsOneWidget);

      // ON 다시: ?k= 포함
      await tester.tap(toggleFinder);
      await tester.pump();
      expect(find.text(linkWithKey), findsOneWidget);
    });

    testWidgets('includeKey 경고 텍스트 토글에 따라 표시/숨김', (tester) async {
      await tester.pumpWidget(createTestApp(
        RoomCreatedView(roomId: testRoomId, password: testPassword),
      ));
      await tester.pump();

      // 초기 (ON): 경고 표시
      expect(
        find.text(
            'ANYONE WITH THIS LINK CAN JOIN WITHOUT ENTERING A PASSWORD'),
        findsOneWidget,
      );

      // OFF: 경고 숨김
      await tester.tap(find.text('INCLUDE PASSWORD IN LINK'));
      await tester.pump();
      expect(
        find.text(
            'ANYONE WITH THIS LINK CAN JOIN WITHOUT ENTERING A PASSWORD'),
        findsNothing,
      );
    });

    testWidgets('보안 경고(glitch-red)는 항상 표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        RoomCreatedView(roomId: testRoomId, password: testPassword),
      ));
      await tester.pump();

      // 보안 경고 항상 표시
      expect(
        find.text('SAVE THIS KEY. IT CANNOT BE RECOVERED.'),
        findsOneWidget,
      );

      // 토글 OFF 해도 보안 경고는 남아있음
      await tester.tap(find.text('INCLUDE PASSWORD IN LINK'));
      await tester.pump();
      expect(
        find.text('SAVE THIS KEY. IT CANNOT BE RECOVERED.'),
        findsOneWidget,
      );
    });

    testWidgets('복사 아이콘 탭 시 체크 아이콘 피드백', (tester) async {
      await tester.pumpWidget(createTestApp(
        RoomCreatedView(roomId: testRoomId, password: testPassword),
      ));
      await tester.pump();

      // 복사 아이콘 2개 (비밀번호, 링크)
      final copyIcons = find.byIcon(Icons.copy);
      expect(copyIcons, findsNWidgets(2));

      // 첫 번째 복사 아이콘 탭
      await tester.tap(copyIcons.first);
      await tester.pump();

      // 체크 아이콘으로 변경
      expect(find.byIcon(Icons.check), findsOneWidget);

      // 1.5초 타이머 소화 (체크 → 복사 복원)
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
