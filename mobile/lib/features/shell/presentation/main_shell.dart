import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/banner_ad_widget.dart';

/// 바텀 네비게이션 Shell (3탭: 홈 / 채팅 / 커뮤니티)
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: Column(
        children: [
          Expanded(child: navigationShell),
          const BannerAdWidget(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor: signalGreen.withValues(alpha: 0.15),
          height: 64,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: ghostGrey),
              selectedIcon: Icon(Icons.home, color: signalGreen),
              label: l10n.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline, color: ghostGrey),
              selectedIcon: Icon(Icons.chat_bubble, color: signalGreen),
              label: l10n.navChat,
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined, color: ghostGrey),
              selectedIcon: Icon(Icons.forum, color: signalGreen),
              label: l10n.navCommunity,
            ),
          ],
        ),
      ),
    );
  }
}
