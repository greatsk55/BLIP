import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/group_chat/domain/models/group_participant.dart';
import 'package:blip/features/group_chat/presentation/widgets/participant_list_sheet.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  final participants = [
    const GroupParticipant(
      userId: 'admin-1',
      username: 'Admin Alice',
      isAdmin: true,
    ),
    const GroupParticipant(
      userId: 'user-2',
      username: 'Bob',
      isAdmin: false,
    ),
    const GroupParticipant(
      userId: 'user-3',
      username: 'Charlie',
      isAdmin: false,
    ),
  ];

  group('ParticipantListSheet', () {
    testWidgets('참여자 목록 표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'admin-1',
          isAdmin: true,
          onKick: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.textContaining('Admin Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Charlie'), findsOneWidget);
    });

    testWidgets('관리자 배지(star 아이콘) 표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'admin-1',
          isAdmin: true,
          onKick: (_) {},
        ),
      ));
      await tester.pump();

      // Admin에게는 star 아이콘
      expect(find.byIcon(Icons.star), findsOneWidget);
      // 일반 사용자에게는 person_outline
      expect(find.byIcon(Icons.person_outline), findsNWidgets(2));
    });

    testWidgets('Admin 텍스트 표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'admin-1',
          isAdmin: true,
          onKick: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('관리자일 때 강퇴 버튼 표시 (일반 사용자에게만)', (tester) async {
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'admin-1',
          isAdmin: true,
          onKick: (_) {},
        ),
      ));
      await tester.pump();

      // Bob, Charlie에 대해 강퇴 버튼 (자신과 admin 제외)
      expect(find.byIcon(Icons.remove_circle_outline), findsNWidgets(2));
    });

    testWidgets('비관리자일 때 강퇴 버튼 미표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'user-2',
          isAdmin: false,
          onKick: (_) {},
        ),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.remove_circle_outline), findsNothing);
    });

    testWidgets('강퇴 버튼 탭 시 콜백 호출', (tester) async {
      String? kickedUserId;
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'admin-1',
          isAdmin: true,
          onKick: (id) => kickedUserId = id,
        ),
      ));
      await tester.pump();

      // 첫 번째 강퇴 버튼 탭 (Bob)
      await tester.tap(find.byIcon(Icons.remove_circle_outline).first);
      expect(kickedUserId, 'user-2');
    });

    testWidgets('참여자 수 표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        ParticipantListSheet(
          participants: participants,
          myId: 'admin-1',
          isAdmin: true,
          onKick: (_) {},
        ),
      ));
      await tester.pump();

      // "PARTICIPANTS (3)" 같은 텍스트
      expect(find.textContaining('3'), findsWidgets);
    });
  });
}
