import 'dart:async';

import 'package:flutter/services.dart';

/// 네이티브 스크린샷/화면녹화 감지 리스너.
///
/// iOS: `userDidTakeScreenshotNotification` + `capturedDidChangeNotification`
/// Android 14+: `ScreenCaptureCallback`
/// Android <14: 네이티브 API 미지원 (감지 불가)
class ScreenshotDetector {
  static const _channel = MethodChannel('com.bakkum.blip/screenshot');
  static final _screenshotController = StreamController<void>.broadcast();
  static final _recordingController = StreamController<bool>.broadcast();
  static bool _initialized = false;

  /// 스크린샷 감지 이벤트 스트림
  static Stream<void> get onScreenshot => _screenshotController.stream;

  /// 화면 녹화 상태 변경 스트림 (true = 녹화 중)
  static Stream<bool> get onScreenRecording => _recordingController.stream;

  /// 플랫폼 채널 리스너 등록 (앱 시작 시 1회 호출)
  static void init() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onScreenshot':
          _screenshotController.add(null);
          break;
        case 'onScreenRecording':
          final isCaptured = call.arguments as bool? ?? false;
          _recordingController.add(isCaptured);
          break;
      }
    });
  }

  /// 리소스 해제 (테스트용)
  static void dispose() {
    _screenshotController.close();
    _recordingController.close();
    _initialized = false;
  }
}
