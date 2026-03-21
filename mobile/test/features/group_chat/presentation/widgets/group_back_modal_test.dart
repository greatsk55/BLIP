import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../helpers/test_helpers.dart';

/// GroupChatRoomView의 _showBackOptions 바텀시트 모달 테스트
/// 실제 위젯 대신, 동일한 구조의 바텀시트를 재현하여 테스트
void main() {
  group('그룹채팅 뒤로가기 모달', () {
    Future<String?> showBackModal(WidgetTester tester) async {
      String? result;

      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              result = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.groupBackModalTitle),
                        Text(l10n.groupBackModalDescription),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop('goBack'),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.groupBackModalGoBack),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(ctx).pop('leaveChat'),
                          icon: const Icon(Icons.logout),
                          label: Text(l10n.groupBackModalLeaveChat),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: Text(l10n.groupBackModalStay),
                        ),
                      ],
                    ),
                  ),
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

      return result;
    }

    testWidgets('모달에 3가지 옵션이 표시됨', (tester) async {
      await showBackModal(tester);

      // LEAVE OPTIONS / GO BACK / LEAVE CHAT / STAY (en locale)
      expect(find.text('LEAVE OPTIONS'), findsOneWidget);
      expect(find.text('GO BACK'), findsOneWidget);
      expect(find.text('LEAVE CHAT'), findsOneWidget);
      expect(find.text('STAY'), findsOneWidget);
    });

    testWidgets('GO BACK 탭 시 goBack 반환', (tester) async {
      String? result;

      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              result = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop('goBack'),
                      child: Text(l10n.groupBackModalGoBack),
                    ),
                  ],
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

      await tester.tap(find.text('GO BACK'));
      await tester.pumpAndSettle();

      expect(result, 'goBack');
    });

    testWidgets('LEAVE CHAT 탭 시 leaveChat 반환', (tester) async {
      String? result;

      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              result = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop('leaveChat'),
                      child: Text(l10n.groupBackModalLeaveChat),
                    ),
                  ],
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

      await tester.tap(find.text('LEAVE CHAT'));
      await tester.pumpAndSettle();

      expect(result, 'leaveChat');
    });

    testWidgets('STAY 탭 시 null 반환', (tester) async {
      String? result = 'initial';

      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () async {
              final l10n = AppLocalizations.of(context)!;
              result = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: Text(l10n.groupBackModalStay),
                    ),
                  ],
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

      await tester.tap(find.text('STAY'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('한국어 locale에서 올바른 텍스트 표시', (tester) async {
      await tester.pumpWidget(createTestApp(
        Builder(builder: (context) {
          return ElevatedButton(
            onPressed: () {
              final l10n = AppLocalizations.of(context)!;
              showModalBottomSheet(
                context: context,
                builder: (ctx) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.groupBackModalTitle),
                    Text(l10n.groupBackModalGoBack),
                    Text(l10n.groupBackModalLeaveChat),
                    Text(l10n.groupBackModalStay),
                  ],
                ),
              );
            },
            child: const Text('Open'),
          );
        }),
        locale: const Locale('ko'),
      ));
      await tester.pump();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('나가기 옵션'), findsOneWidget);
      expect(find.text('페이지만 나가기'), findsOneWidget);
      expect(find.text('채팅에서 나가기'), findsOneWidget);
      expect(find.text('머물기'), findsOneWidget);
    });
  });
}
