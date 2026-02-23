import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

/// 다국어 "Talk. Then Vanish." 스플래시 화면
/// iOS LaunchScreen(정적) 이후 Flutter에서 보여주는 브랜드 인트로
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── 다국어 슬로건 (heroTitle 기준) ──
  static const _slogans = [
    'Talk. Then Vanish.',
    '말하고, 사라지세요.',
    '話して、消える。',
    '交谈。然后消失。',
    'Habla. Luego desaparece.',
    'Parlez. Puis disparaissez.',
    'Reden. Dann verschwinden.',
  ];

  // ── 애니메이션 컨트롤러 ──
  late final AnimationController _logoController;
  late final AnimationController _sloganController;
  late final AnimationController _glowController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _sloganFade;
  late final Animation<double> _sloganBlur;
  late final Animation<double> _glowAnim;

  int _sloganIndex = 0;
  Timer? _sloganTimer;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // 로고 페이드인 + 스케일
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // 슬로건 페이드인/블러 아웃
    _sloganController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _sloganFade = CurvedAnimation(
      parent: _sloganController,
      curve: Curves.easeOut,
    );
    _sloganBlur = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _sloganController, curve: Curves.easeIn),
    );

    // 글로우 펄스
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _startSequence();
  }

  void _startSequence() async {
    // 1) 로고 페이드인
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    // 2) 첫 슬로건 표시 (로고 후 500ms)
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    _sloganController.forward();

    // 3) 슬로건 순환 시작
    _sloganTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      _cycleSlogan();
    });

    // 4) 3.5초 후 메인으로 전환
    await Future.delayed(const Duration(milliseconds: 3500));
    _navigate();
  }

  void _cycleSlogan() async {
    // 블러 아웃
    _sloganController.reverse();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _sloganIndex = (_sloganIndex + 1) % _slogans.length;
    });

    // 페이드인
    _sloganController.forward();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go('/');
  }

  @override
  void dispose() {
    _sloganTimer?.cancel();
    _logoController.dispose();
    _sloganController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlackDark,
      body: GestureDetector(
        onTap: _navigate, // 탭하면 즉시 스킵
        behavior: HitTestBehavior.opaque,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              // ── BLIP 로고 + 글로우 ──
              AnimatedBuilder(
                animation: Listenable.merge([_logoFade, _glowAnim]),
                builder: (context, child) => Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: _buildLogo(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // ── 다국어 슬로건 ──
              SizedBox(
                height: 40,
                child: AnimatedBuilder(
                  animation: _sloganController,
                  builder: (context, child) => Opacity(
                    opacity: _sloganFade.value,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: _sloganController.status ==
                                AnimationStatus.reverse
                            ? _sloganBlur.value
                            : 0.0,
                        sigmaY: _sloganController.status ==
                                AnimationStatus.reverse
                            ? _sloganBlur.value
                            : 0.0,
                      ),
                      child: Text(
                        _slogans[_sloganIndex],
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: AppColors.ghostGreyDark,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 4),
              // ── 하단 안내 ──
              FadeTransition(
                opacity: _logoFade,
                child: Text(
                  'End-to-End Encrypted',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ghostGreyDark.withValues(alpha: 0.5),
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, child) => ShaderMask(
        shaderCallback: (bounds) => RadialGradient(
          colors: [
            AppColors.signalGreenDark,
            AppColors.signalGreenDark
                .withValues(alpha: 0.4 + _glowAnim.value * 0.6),
          ],
        ).createShader(bounds),
        child: const Text(
          'BLIP',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 12,
          ),
        ),
      ),
    );
  }
}
