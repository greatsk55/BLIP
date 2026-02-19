import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/room_creator.dart';
import '../../settings/providers/theme_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _creating = false;

  // ── 애니메이션 컨트롤러 ──
  late final AnimationController _vanishController;
  late final AnimationController _fadeInController;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _ctaFade;
  late final Animation<double> _linkShareFade;

  @override
  void initState() {
    super.initState();

    _vanishController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _vanishController.forward().then((_) => _startVanishLoop());

    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _subtitleFade = CurvedAnimation(
      parent: _fadeInController,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );
    _ctaFade = CurvedAnimation(
      parent: _fadeInController,
      curve: const Interval(0.3, 0.65, curve: Curves.easeOut),
    );
    _linkShareFade = CurvedAnimation(
      parent: _fadeInController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );

    _fadeInController.forward();
  }

  void _startVanishLoop() {
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      _vanishController.reverse().then((_) {
        if (!mounted) return;
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (!mounted) return;
          _vanishController.forward().then((_) {
            if (!mounted) return;
            _startVanishLoop();
          });
        });
      });
    });
  }

  @override
  void dispose() {
    _vanishController.dispose();
    _fadeInController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (_creating) return;
    setState(() => _creating = true);

    try {
      await RoomCreator.createAndNavigate(context);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;
    final glitchRed = AppColors.glitchRed;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      body: Stack(
        children: [
          // ── 배경 글로우 ──
          Positioned(
            top: MediaQuery.of(context).size.height * 0.2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      signalGreen.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ═══════════ §1 HERO ═══════════
                  _buildHeroSection(l10n, signalGreen, ghostGrey, isDark),

                  // ═══════════ §2 PROBLEM ═══════════
                  _buildProblemSection(l10n, ghostGrey, glitchRed, borderColor),

                  // ═══════════ §3 SOLUTION ═══════════
                  _buildSolutionSection(l10n, signalGreen, ghostGrey, glitchRed, borderColor, isDark),

                  // ═══════════ §4 COMMUNITY BOARD ═══════════
                  _buildCommunitySection(l10n, signalGreen, ghostGrey, borderColor, isDark),

                  // ═══════════ §5 PHILOSOPHY ═══════════
                  _buildPhilosophySection(l10n, ghostGrey),

                  // ═══════════ §6 FOOTER ═══════════
                  _buildFooterSection(l10n, signalGreen, ghostGrey, borderColor, isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────── §1 HERO ───────────────
  Widget _buildHeroSection(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 80),

          // Title (vanish loop)
          AnimatedBuilder(
            animation: _vanishController,
            builder: (context, child) {
              final v = _vanishController.value;
              return ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: (1 - v) * 20,
                  sigmaY: (1 - v) * 20,
                  tileMode: TileMode.decal,
                ),
                child: Opacity(opacity: v, child: child),
              );
            },
            child: Text(
              l10n.heroTitle,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: signalGreen,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          FadeTransition(
            opacity: _subtitleFade,
            child: Text(
              l10n.heroSubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ghostGrey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),

          // Create Room CTA
          FadeTransition(
            opacity: _ctaFade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.15),
                end: Offset.zero,
              ).animate(_ctaFade),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: _ScaleOnTap(
                  child: ElevatedButton(
                    onPressed: _creating ? null : _createRoom,
                    child: _creating
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark
                                  ? AppColors.voidBlackDark
                                  : AppColors.white,
                            ),
                          )
                        : Text(l10n.heroCta),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Board CTA
          FadeTransition(
            opacity: _ctaFade,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/board/create'),
                icon: Icon(Icons.forum_outlined, color: signalGreen),
                label: Text(l10n.heroBoardCta),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Link share
          FadeTransition(
            opacity: _linkShareFade,
            child: Text(
              l10n.heroLinkShare,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ghostGrey.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ─────────────── §2 PROBLEM ───────────────
  Widget _buildProblemSection(
    AppLocalizations l10n,
    Color ghostGrey,
    Color glitchRed,
    Color borderColor,
  ) {
    return _ScrollFadeIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: Column(
          children: [
            Text(
              l10n.problemTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.problemDescription,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ghostGrey, height: 1.8),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Glitch bar
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  'ERROR: DATA_PERSISTENCE_DETECTED',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: glitchRed.withValues(alpha: 0.7),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── §3 SOLUTION ───────────────
  Widget _buildSolutionSection(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    Color glitchRed,
    Color borderColor,
    bool isDark,
  ) {
    final features = [
      (Icons.flash_on, l10n.solutionFrictionTitle, l10n.solutionFrictionDesc, signalGreen),
      (Icons.visibility_off, l10n.solutionAnonymityTitle, l10n.solutionAnonymityDesc, signalGreen),
      (Icons.local_fire_department, l10n.solutionDestructionTitle, l10n.solutionDestructionDesc, glitchRed),
      (Icons.timer, l10n.solutionAutoshredTitle, l10n.solutionAutoshredDesc, signalGreen),
      (Icons.shield, l10n.solutionCaptureGuardTitle, l10n.solutionCaptureGuardDesc, glitchRed),
      (Icons.code, l10n.solutionOpensourceTitle, l10n.solutionOpensourceDesc, ghostGrey),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: features.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, title, desc, iconColor) = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: i < features.length - 1 ? 16 : 0),
            child: _ScrollFadeIn(
              delay: Duration(milliseconds: i * 100),
              child: _SolutionCard(
                icon: icon,
                title: title,
                description: desc,
                iconColor: iconColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─────────────── §4 COMMUNITY BOARD ───────────────
  Widget _buildCommunitySection(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    Color borderColor,
    bool isDark,
  ) {
    final features = [
      (Icons.lock, l10n.communityPasswordTitle, l10n.communityPasswordDesc),
      (Icons.visibility_off, l10n.communityServerBlindTitle, l10n.communityServerBlindDesc),
      (Icons.flag, l10n.communityModerationTitle, l10n.communityModerationDesc),
    ];

    return _ScrollFadeIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          children: [
            // Label badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: signalGreen.withValues(alpha: 0.1)),
              ),
              child: Text(
                l10n.communityLabel,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: signalGreen.withValues(alpha: 0.6),
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              l10n.communityTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              l10n.communitySubtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ghostGrey, height: 1.8),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // 3 feature cards
            ...features.map((f) {
              final (icon, title, desc) = f;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade50,
                        ),
                        child: Icon(icon, color: signalGreen, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: ghostGrey, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),

            // CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/board/create'),
                icon: Icon(Icons.arrow_forward, color: signalGreen, size: 18),
                label: Text(
                  l10n.communityCta,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── §5 PHILOSOPHY ───────────────
  Widget _buildPhilosophySection(AppLocalizations l10n, Color ghostGrey) {
    return _ScrollFadeIn(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          children: [
            Text(
              '"${l10n.philosophyText1}"',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.philosophyText2,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: ghostGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── §6 FOOTER ───────────────
  Widget _buildFooterSection(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Column(
        children: [
          // Easter egg
          Text(
            l10n.footerEasterEgg,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: ghostGrey.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),

          // Settings row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggle(),
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: ghostGrey,
                  size: 20,
                ),
              ),
              IconButton(
                onPressed: () => context.push('/settings'),
                icon: Icon(Icons.settings, color: ghostGrey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Support Protocol
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://buymeacoffee.com/ryokai'),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(4),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.coffee, size: 14, color: ghostGrey),
                  const SizedBox(width: 8),
                  Text(
                    l10n.footerSupportProtocol,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: ghostGrey,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Copyright
          Text(
            l10n.footerCopyright,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: ghostGrey.withValues(alpha: 0.4),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.footerNoRights,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: ghostGrey.withValues(alpha: 0.4),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────── 스크롤 진입 시 페이드인 (whileInView) ───────────────
class _ScrollFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _ScrollFadeIn({
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<_ScrollFadeIn> createState() => _ScrollFadeInState();
}

class _ScrollFadeInState extends State<_ScrollFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_triggered) return;
    if (info.visibleFraction > 0.15) {
      _triggered = true;
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: widget.child,
        ),
      ),
    );
  }
}

// ── 간단한 가시성 감지 (외부 패키지 없이) ──
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final void Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class VisibilityInfo {
  final double visibleFraction;
  const VisibilityInfo({required this.visibleFraction});
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  void _check() {
    if (!mounted) return;
    final renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      _scheduleCheck();
      return;
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;

    final visibleTop = position.dy.clamp(0, screenHeight);
    final visibleBottom = (position.dy + size.height).clamp(0, screenHeight);
    final visibleHeight = (visibleBottom - visibleTop).clamp(0, size.height);
    final fraction = size.height > 0 ? visibleHeight / size.height : 0.0;

    widget.onVisibilityChanged(VisibilityInfo(visibleFraction: fraction));
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

// ─────────────── 탭 스케일 애니메이션 ───────────────
class _ScaleOnTap extends StatefulWidget {
  final Widget child;

  const _ScaleOnTap({required this.child});

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// ─────────────── Solution 카드 ───────────────
class _SolutionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color iconColor;
  final Color borderColor;
  final bool isDark;

  const _SolutionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.iconColor,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.ghostGreyDark
                      : AppColors.ghostGreyLight,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
