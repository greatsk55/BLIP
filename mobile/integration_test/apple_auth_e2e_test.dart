import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:blip/core/services/auth_service.dart';
import 'package:blip/features/auth/presentation/login_screen.dart';
import 'package:blip/features/auth/providers/auth_provider.dart';
import 'package:blip/features/settings/presentation/settings_screen.dart';
import 'package:blip/l10n/app_localizations.dart';

// ─── Mock 클래스 ───

class MockAuthService extends AuthService {
  MockAuthService() : super.forTesting();

  bool _loggedIn = false;
  final _authController = StreamController<AuthState>.broadcast();

  bool get isLoggedIn => _loggedIn;
  Stream<AuthState> get mockStream => _authController.stream;

  @override
  Session? get currentSession => _loggedIn ? _FakeSession() : null;

  @override
  User? get currentUser => _loggedIn ? _FakeUser() : null;

  @override
  Stream<AuthState> get authStateChanges => _authController.stream;

  @override
  Future<AuthResponse> signInWithApple() async {
    _loggedIn = true;
    // AuthResponse를 직접 생성할 수 없으므로 상태만 변경
    // 실제 앱에서는 Supabase가 AuthState 이벤트를 방출
    return AuthResponse(session: null, user: null);
  }

  @override
  Future<void> signOut() async {
    _loggedIn = false;
  }

  @override
  Future<void> deleteAccount() async {
    _loggedIn = false;
  }

  void dispose() {
    _authController.close();
  }
}

/// 최소한의 Session fake (null 체크용)
class _FakeSession implements Session {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  String get accessToken => 'fake-access-token';

  @override
  String get tokenType => 'bearer';
}

/// 최소한의 User fake
class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;

  @override
  String get id => 'fake-user-id';
}

// ─── 테스트용 라우터 (실제 앱 라우팅 로직 재현) ───

GoRouter _buildTestRouter({
  required bool isLoggedIn,
  required ValueNotifier<bool> authNotifier,
}) {
  return GoRouter(
    initialLocation: isLoggedIn ? '/' : '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loggedIn = authNotifier.value;
      final isOnLogin = state.matchedLocation == '/login';

      if (!loggedIn && !isOnLogin) return '/login';
      if (loggedIn && isOnLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const _TestHomeScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

/// 테스트용 홈 화면 (설정 이동 버튼 포함)
class _TestHomeScreen extends StatelessWidget {
  const _TestHomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLIP'),
        actions: [
          IconButton(
            key: const Key('settings_button'),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: const Center(child: Text('Home')),
    );
  }
}

// ─── 테스트 앱 래퍼 ───

class _TestApp extends StatelessWidget {
  final GoRouter router;

  const _TestApp({required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

// ─── E2E 테스트 ───

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuth;
  late ValueNotifier<bool> authNotifier;

  setUpAll(() {
    dotenv.testLoad(fileInput: 'API_BASE_URL=https://blip-blip.vercel.app');
  });

  setUp(() {
    mockAuth = MockAuthService();
    authNotifier = ValueNotifier(false);
    AuthService.testInstance = mockAuth;
  });

  tearDown(() {
    mockAuth.dispose();
    authNotifier.dispose();
    AuthService.resetInstance();
  });

  group('Apple 로그인 → 회원탈퇴 E2E', () {
    testWidgets('1. 미로그인 시 로그인 화면 표시', (tester) async {
      final router = _buildTestRouter(
        isLoggedIn: false,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // 로그인 화면 확인
      expect(find.text('BLIP'), findsOneWidget);
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('2. Apple 로그인 성공 → 홈 화면 이동', (tester) async {
      final router = _buildTestRouter(
        isLoggedIn: false,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // 로그인 화면 확인
      expect(find.byIcon(Icons.apple), findsOneWidget);

      // Apple 로그인 버튼 탭
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      // MockAuthService에서 로그인 성공 처리됨
      expect(mockAuth.isLoggedIn, isTrue);

      // 라우터에 로그인 상태 반영 → 홈으로 리다이렉트
      authNotifier.value = true;
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('BLIP'), findsOneWidget);
    });

    testWidgets('3. 홈 → 설정 화면 이동', (tester) async {
      // 로그인 상태로 시작
      mockAuth._loggedIn = true;
      authNotifier.value = true;

      final router = _buildTestRouter(
        isLoggedIn: true,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // 홈 화면 확인
      expect(find.text('Home'), findsOneWidget);

      // 설정 버튼 탭
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // 설정 화면 확인 (l10n key: settingsTitle)
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('4. 설정 화면 — 계정 섹션 표시 (iOS + 로그인 상태)',
        (tester) async {
      mockAuth._loggedIn = true;
      authNotifier.value = true;

      final router = _buildTestRouter(
        isLoggedIn: true,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // 설정으로 이동
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // iOS 시뮬레이터에서 실행 → Platform.isIOS == true
      // 로그인 상태 → 계정 섹션 표시
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('5. 회원탈퇴 — 확인 다이얼로그 → 삭제 → 로그인 화면 복귀',
        (tester) async {
      mockAuth._loggedIn = true;
      authNotifier.value = true;

      final router = _buildTestRouter(
        isLoggedIn: true,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // 설정으로 이동
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // 계정 삭제 버튼 탭
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // 확인 다이얼로그 표시 확인
      expect(find.byType(AlertDialog), findsOneWidget);

      // "삭제" 확인 버튼 탭 (다이얼로그 내 두 번째 TextButton)
      final dialogButtons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      expect(dialogButtons, findsNWidgets(2));

      // 확인 버튼 (두 번째) 탭
      await tester.tap(dialogButtons.last);
      await tester.pump();

      // MockAuthService에서 삭제 처리됨
      expect(mockAuth.isLoggedIn, isFalse);

      // 라우터에 로그아웃 상태 반영 → 로그인 화면으로
      authNotifier.value = false;
      await tester.pumpAndSettle();

      // 로그인 화면 복귀 확인
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('6. 로그아웃 → 로그인 화면 복귀', (tester) async {
      mockAuth._loggedIn = true;
      authNotifier.value = true;

      final router = _buildTestRouter(
        isLoggedIn: true,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // 설정으로 이동
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();

      // 로그아웃 버튼 탭
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      expect(mockAuth.isLoggedIn, isFalse);

      // 라우터에 상태 반영
      authNotifier.value = false;
      await tester.pumpAndSettle();

      // 로그인 화면 복귀
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('7. 전체 플로우: 로그인 → 설정 → 탈퇴 → 로그인', (tester) async {
      final router = _buildTestRouter(
        isLoggedIn: false,
        authNotifier: authNotifier,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: _TestApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      // ── Step 1: 로그인 ──
      expect(find.byIcon(Icons.apple), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      expect(mockAuth.isLoggedIn, isTrue);

      authNotifier.value = true;
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);

      // ── Step 2: 설정 이동 ──
      await tester.tap(find.byKey(const Key('settings_button')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // ── Step 3: 계정 삭제 ──
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_forever));
      await tester.pumpAndSettle();

      // 확인 다이얼로그
      expect(find.byType(AlertDialog), findsOneWidget);
      final confirmBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(confirmBtn.last);
      await tester.pump();

      expect(mockAuth.isLoggedIn, isFalse);

      // ── Step 4: 로그인 화면 복귀 ──
      authNotifier.value = false;
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });
  });
}
