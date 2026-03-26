import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import 'core/constants/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/storage/local_storage_service.dart';
import 'core/storage/models/saved_room.dart';
import 'core/services/analytics_service.dart';
import 'core/security/security_overlay.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/board/presentation/board_screen.dart';
import 'features/board/presentation/board_create_screen.dart';
import 'features/blipme/presentation/blipme_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/shell/presentation/main_shell.dart';
import 'features/chat_list/presentation/my_chat_list_screen.dart';
import 'features/community_list/presentation/my_community_list_screen.dart';
import 'features/group_chat/presentation/group_create_screen.dart';
import 'features/group_chat/presentation/group_chat_screen.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/prediction/presentation/prediction_list_screen.dart';
import 'features/prediction/presentation/prediction_detail_screen.dart';
import 'features/prediction/presentation/create_prediction_screen.dart';
import 'features/settings/providers/locale_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 딥링크 ID 검증: 영숫자 6~32자만 허용 (injection 방지)
final _validIdPattern = RegExp(r'^[a-zA-Z0-9]{6,32}$');

final routerProvider = Provider<GoRouter>((ref) {
  // authState 변경 시 라우터 redirect가 재평가되도록 watch
  ref.watch(authStateProvider);
  return _buildRouter(ref);
});

GoRouter _buildRouter(Ref ref) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  observers: [AnalyticsService.instance.observer],
  redirect: (context, state) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    final isOnLogin = state.matchedLocation == '/login';
    final isOnSplash = state.matchedLocation == '/splash';

    // 스플래시는 항상 허용
    if (isOnSplash) return null;
    // Android는 로그인 불필요 — iOS만 Apple Sign In 적용
    if (!Platform.isIOS) {
      if (isOnLogin) return '/';
      return null;
    }
    // iOS: 미로그인 → 로그인 화면으로
    if (!isLoggedIn && !isOnLogin) return '/login';
    // iOS: 로그인 상태인데 로그인 화면 → 홈으로
    if (isLoggedIn && isOnLogin) return '/';

    return null;
  },
  routes: [
    // ── 스플래시 (브랜드 인트로) ──
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    // ── 로그인 ──
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    // ── 바텀 네비게이션 Shell (3탭) ──
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: 홈
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 1: 내 채팅
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chats',
              builder: (context, state) => const MyChatListScreen(),
            ),
          ],
        ),
        // Tab 2: 내 커뮤니티
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/communities',
              builder: (context, state) => const MyCommunityListScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Shell 바깥 (바텀바 없는 전체 화면) ──
    GoRoute(
      path: '/room/:roomId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final roomId = state.pathParameters['roomId'];
        if (roomId == null || !_validIdPattern.hasMatch(roomId)) return '/';
        return null;
      },
      builder: (context, state) {
        // 딥링크: extra(앱 내부) > ?k=(쿼리) > #(프래그먼트) 순으로 비밀번호 추출
        final passwordFromExtra = state.extra as String?;
        final passwordFromQuery = state.uri.queryParameters['k'];
        final fragment = state.uri.fragment;
        final passwordFromFragment =
            fragment.isNotEmpty ? Uri.decodeComponent(fragment) : null;
        return ChatScreen(
          roomId: state.pathParameters['roomId']!,
          initialPassword:
              passwordFromExtra ?? passwordFromQuery ?? passwordFromFragment,
        );
      },
    ),
    // /board/create가 /board/:boardId 보다 위에 있어야 'create'가 boardId로 매칭되지 않음
    GoRoute(
      path: '/board/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BoardCreateScreen(),
    ),
    GoRoute(
      path: '/board/:boardId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final boardId = state.pathParameters['boardId'];
        if (boardId == null || !_validIdPattern.hasMatch(boardId)) return '/';
        return null;
      },
      builder: (context, state) => BoardScreen(
        boardId: state.pathParameters['boardId']!,
      ),
    ),
    GoRoute(
      path: '/blipme',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BlipMeScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── 그룹 채팅 ──
    GoRoute(
      path: '/group/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GroupCreateScreen(),
    ),
    GoRoute(
      path: '/group/:roomId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final roomId = state.pathParameters['roomId'];
        if (roomId == null || !_validIdPattern.hasMatch(roomId)) return '/';
        return null;
      },
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final passwordFromExtra = extra?['password'] as String?;
        final passwordFromQuery = state.uri.queryParameters['k'];
        final fragment = state.uri.fragment;
        final passwordFromFragment =
            fragment.isNotEmpty ? Uri.decodeComponent(fragment) : null;
        return GroupChatScreen(
          roomId: state.pathParameters['roomId']!,
          initialPassword:
              passwordFromExtra ?? passwordFromQuery ?? passwordFromFragment,
          adminToken: extra?['adminToken'] as String?,
          isAdmin: extra?['isAdmin'] as bool? ?? false,
          justCreated: extra?['justCreated'] as bool? ?? false,
        );
      },
    ),

    // ── 예측 (Prediction) ──
    GoRoute(
      path: '/prediction',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PredictionListScreen(),
    ),
    // /prediction/create가 /prediction/:id 보다 위에 있어야 'create'가 id로 매칭되지 않음
    GoRoute(
      path: '/prediction/create',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreatePredictionScreen(),
    ),
    GoRoute(
      path: '/prediction/:id',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final id = state.pathParameters['id'];
        if (id == null || !_validIdPattern.hasMatch(id)) return '/prediction';
        return null;
      },
      builder: (context, state) => PredictionDetailScreen(
        predictionId: state.pathParameters['id']!,
      ),
    ),

    // ── 딥링크: /m/:linkId (BLIP me 방문자) ──
    GoRoute(
      path: '/m/:linkId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final linkId = state.pathParameters['linkId'];
        if (linkId == null || !_validIdPattern.hasMatch(linkId)) return '/';
        // 앱에서는 웹 방문자 페이지 대신 직접 연결 처리
        // BlipMeConnectScreen에서 처리하거나, 웹으로 리다이렉트
        return null;
      },
      builder: (context, state) => _BlipMeConnectRedirect(
        linkId: state.pathParameters['linkId']!,
      ),
    ),

    // ── 딥링크: /{locale}/room, /{locale}/board (next-intl 로캘 프리픽스 제거) ──
    GoRoute(
      path: '/:locale/room/:roomId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final roomId = state.pathParameters['roomId'];
        if (roomId == null || !_validIdPattern.hasMatch(roomId)) return '/';
        // ?k= query param 또는 #fragment 유지 (비밀번호 포함 딥링크)
        final k = state.uri.queryParameters['k'];
        final fragment = state.uri.fragment;
        if (k != null) return '/room/$roomId?k=$k';
        if (fragment.isNotEmpty) return '/room/$roomId#$fragment';
        return '/room/$roomId';
      },
    ),
    GoRoute(
      path: '/:locale/board/create',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) => '/board/create',
    ),
    GoRoute(
      path: '/:locale/board/:boardId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final boardId = state.pathParameters['boardId'];
        if (boardId == null || !_validIdPattern.hasMatch(boardId)) return '/';
        return '/board/$boardId';
      },
    ),
  ],
);

class BlipApp extends ConsumerWidget {
  const BlipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'BLIP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => SecurityOverlay(child: child!),
    );
  }
}

/// BLIP me 딥링크 방문자: API 호출 → 방 생성 → 채팅 화면으로 이동
class _BlipMeConnectRedirect extends StatefulWidget {
  final String linkId;
  const _BlipMeConnectRedirect({required this.linkId});

  @override
  State<_BlipMeConnectRedirect> createState() => _BlipMeConnectRedirectState();
}

class _BlipMeConnectRedirectState extends State<_BlipMeConnectRedirect> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final api = ApiClient();
      final result = await api.connectViaBlipMe(widget.linkId);

      if (!mounted) return;

      if (result['error'] != null) {
        setState(() {
          _loading = false;
          _error = result['error'] as String;
        });
        return;
      }

      final roomId = result['roomId'] as String;
      final password = result['password'] as String;

      // 로컬 저장
      final storage = LocalStorageService();
      final now = DateTime.now().millisecondsSinceEpoch;
      await storage.saveRoom(
        SavedRoom(
          roomId: roomId,
          isCreator: false,
          createdAt: now,
          lastAccessedAt: now,
        ),
        password,
      );

      if (!mounted) return;
      context.go('/room/$roomId', extra: password);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'NETWORK_ERROR';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _loading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Connecting...',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _error ?? 'Something went wrong.',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
      ),
    );
  }
}
