import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'screenshot_detector.dart';

/// 보안 오버레이: 앱 백그라운드 전환 + 스크린샷/화면녹화 감지 시 블러
class SecurityOverlay extends StatefulWidget {
  final Widget child;

  const SecurityOverlay({super.key, required this.child});

  @override
  State<SecurityOverlay> createState() => _SecurityOverlayState();
}

class _SecurityOverlayState extends State<SecurityOverlay>
    with WidgetsBindingObserver {
  /// 앱 백그라운드 전환
  bool _lifecycleObscured = false;

  /// 화면 녹화 중 (네이티브 감지)
  bool _recordingObscured = false;

  /// 스크린샷 감지 후 일시적 블러
  bool _screenshotObscured = false;

  Timer? _screenshotTimer;
  StreamSubscription<void>? _screenshotSub;
  StreamSubscription<bool>? _recordingSub;

  bool get _obscured =>
      _lifecycleObscured || _recordingObscured || _screenshotObscured;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 스크린샷 감지 → 3초간 블러
    _screenshotSub = ScreenshotDetector.onScreenshot.listen((_) {
      _triggerScreenshotBlur();
    });

    // 화면 녹화 시작/종료 → 녹화 중이면 계속 블러
    _recordingSub = ScreenshotDetector.onScreenRecording.listen((isCaptured) {
      if (mounted) {
        setState(() => _recordingObscured = isCaptured);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenshotTimer?.cancel();
    _screenshotSub?.cancel();
    _recordingSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _lifecycleObscured = state == AppLifecycleState.inactive ||
          state == AppLifecycleState.hidden ||
          state == AppLifecycleState.paused;
    });
  }

  /// 스크린샷 감지 시 3초간 블러 (웹 useScreenProtection과 동일한 UX)
  void _triggerScreenshotBlur() {
    if (!mounted) return;

    setState(() => _screenshotObscured = true);

    _screenshotTimer?.cancel();
    _screenshotTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _screenshotObscured = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_obscured)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: Colors.white38,
                      ),
                      if (_screenshotObscured && !_lifecycleObscured && !_recordingObscured)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Screenshot detected',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
