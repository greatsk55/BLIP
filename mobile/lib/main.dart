import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/push/push_service.dart';
import 'core/security/screenshot_detector.dart';
import 'core/services/ad_service.dart';
import 'core/services/analytics_service.dart';
import 'core/supabase/supabase_client.dart';
import 'core/widgets/deferred_startup.dart';

Future<void> main() async {
  // 최상위 에러 핸들러 — 어떤 초기화가 실패해도 앱은 열려야 함
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[BLIP] FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[BLIP] PlatformError: $error\n$stack');
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 각 초기화를 개별 try-catch로 감싸서 하나 실패해도 나머지 계속 진행
  // 1) 환경변수 로드
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[BLIP] dotenv load failed: $e');
  }

  // Only app configuration and chat transport precede the first screen.
  try {
    await initSupabase().timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[BLIP] Supabase init failed: $e');
  }

  // 8) 스크린샷/화면녹화 감지 채널 초기화
  try {
    ScreenshotDetector.init();
  } catch (e) {
    debugPrint('[BLIP] ScreenshotDetector init failed: $e');
  }

  runApp(
    ProviderScope(
      child: DeferredStartup(
        initialize: _initializeOptionalServices,
        child: const BlipApp(),
      ),
    ),
  );
}

Future<void> _initializeOptionalServices() async {
  await Future.wait([
    _initializeFirebaseServices(),
    _startOptional('AdService', AdService.instance.init),
  ]);
}

Future<void> _initializeFirebaseServices() async {
  try {
    // Native GoogleService-Info.plist / google-services.json supply the options.
    await Firebase.initializeApp().timeout(const Duration(seconds: 10));
    await Future.wait([
      _startOptional('Analytics', AnalyticsService.instance.init),
      _startOptional('PushService', PushService.instance.init),
    ]);
  } catch (error) {
    debugPrint('[BLIP] Firebase startup failed: $error');
  }
}

Future<void> _startOptional(String name, Future<void> Function() start) async {
  try {
    await start().timeout(const Duration(seconds: 35));
  } catch (error) {
    debugPrint('[BLIP] $name startup failed: $error');
  }
}
