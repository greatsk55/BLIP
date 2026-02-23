import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import 'core/constants/app_theme.dart';
import 'core/security/security_overlay.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/chat/presentation/chat_screen.dart';
import 'features/board/presentation/board_screen.dart';
import 'features/board/presentation/board_create_screen.dart';
import 'features/settings/presentation/settings_screen.dart';
import 'features/shell/presentation/main_shell.dart';
import 'features/chat_list/presentation/my_chat_list_screen.dart';
import 'features/community_list/presentation/my_community_list_screen.dart';
import 'features/settings/providers/theme_provider.dart';
import 'features/settings/providers/locale_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// 딥링크 ID 검증: 영숫자 6~32자만 허용 (injection 방지)
final _validIdPattern = RegExp(r'^[a-zA-Z0-9]{6,32}$');

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── 스플래시 (브랜드 인트로) ──
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
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
      builder: (context, state) => ChatScreen(
        roomId: state.pathParameters['roomId']!,
        initialPassword: state.extra as String?,
      ),
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
      path: '/settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),

    // ── 딥링크: /{locale}/room, /{locale}/board (next-intl 로캘 프리픽스 제거) ──
    GoRoute(
      path: '/:locale/room/:roomId',
      parentNavigatorKey: _rootNavigatorKey,
      redirect: (context, state) {
        final roomId = state.pathParameters['roomId'];
        if (roomId == null || !_validIdPattern.hasMatch(roomId)) return '/';
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
      routerConfig: _router,
      builder: (context, child) => SecurityOverlay(child: child!),
    );
  }
}
