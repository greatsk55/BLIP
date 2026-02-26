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
import 'core/supabase/supabase_client.dart';
import 'firebase_options.dart';

void main() async {
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

  // 2) Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('[BLIP] Firebase init failed: $e');
  }

  // 3) Supabase 초기화
  try {
    await initSupabase();
  } catch (e) {
    debugPrint('[BLIP] Supabase init failed: $e');
  }

  // 4) FCM 푸시 알림 초기화
  try {
    await PushService.instance.init();
  } catch (e) {
    debugPrint('[BLIP] PushService init failed: $e');
  }

  // 5) AdMob 초기화
  try {
    await AdService.instance.init();
  } catch (e) {
    debugPrint('[BLIP] AdService init failed: $e');
  }

  // 6) 스크린샷/화면녹화 감지 채널 초기화
  try {
    ScreenshotDetector.init();
  } catch (e) {
    debugPrint('[BLIP] ScreenshotDetector init failed: $e');
  }

  runApp(const ProviderScope(
    child: BlipApp(),
  ));
}
