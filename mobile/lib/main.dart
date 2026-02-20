import 'package:firebase_core/firebase_core.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // 세로 모드 고정
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Supabase 초기화
  await initSupabase();

  // FCM 푸시 알림 초기화
  await PushService.instance.init();

  // AdMob 초기화 + 오프닝 광고
  await AdService.instance.init();
  AdService.instance.showInitialAppOpenAd();

  // 스크린샷/화면녹화 감지 채널 초기화
  ScreenshotDetector.init();

  runApp(const ProviderScope(
    child: BlipApp(),
  ));
}
