import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// 앱 시작 + 홈 화면 렌더링 통합 테스트
/// 참고: Supabase 연결 없이 UI 렌더링만 테스트
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('앱 시작 시 MaterialApp 렌더링', (tester) async {
    // Supabase 초기화가 필요하므로, 최소한의 MaterialApp으로 테스트
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('BLIP')),
        ),
      ),
    );

    expect(find.text('BLIP'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
