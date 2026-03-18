import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blip/features/group_chat/presentation/widgets/admin_action_dialog.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  group('AdminActionDialog', () {
    Future<void> showDialog_(WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AdminActionDialog(
                  title: 'Kick User',
                  message: 'Are you sure you want to kick Bob?',
                  confirmLabel: 'Kick',
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('제목과 메시지 표시', (tester) async {
      await showDialog_(tester);

      expect(find.text('Kick User'), findsOneWidget);
      expect(find.text('Are you sure you want to kick Bob?'), findsOneWidget);
    });

    testWidgets('확인/취소 버튼 존재', (tester) async {
      await showDialog_(tester);

      expect(find.text('Kick'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('취소 버튼 탭 시 false 반환', (tester) async {
      bool? result;
      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const AdminActionDialog(
                  title: 'Kick User',
                  message: 'Kick Bob?',
                  confirmLabel: 'Kick',
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('확인 버튼 탭 시 true 반환', (tester) async {
      bool? result;
      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              result = await showDialog<bool>(
                context: context,
                builder: (_) => const AdminActionDialog(
                  title: 'Kick User',
                  message: 'Kick Bob?',
                  confirmLabel: 'Kick',
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kick'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
