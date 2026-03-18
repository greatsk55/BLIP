import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:blip/l10n/app_localizations.dart';
import 'package:blip/features/group_chat/presentation/group_create_screen.dart';

/// 그룹 채팅 생성 화면 이동 플로우 통합 테스트
/// Supabase 연결 없이 UI 렌더링만 테스트
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://blip-blip.vercel.app');
  });

  testWidgets('그룹 채팅 생성 화면 렌더링', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: GroupCreateScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 그룹 생성 화면 요소 확인
    expect(find.byIcon(Icons.group_add), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });

  testWidgets('그룹 이름 입력 후 생성 버튼 확인', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: GroupCreateScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 그룹 이름 입력
    await tester.enterText(find.byType(TextField), 'Test Group');
    await tester.pump();

    expect(find.text('Test Group'), findsOneWidget);

    // 생성 버튼 존재 확인
    final button = find.byType(ElevatedButton);
    expect(button, findsOneWidget);
  });
}
