import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics 서비스 (Singleton)
/// - 화면 전환, 주요 사용자 행동 이벤트 추적
/// - 개인정보 수집 없음 (BLIP 철학 준수)
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  late final FirebaseAnalytics _analytics;
  bool _initialized = false;

  Future<void> init() async {
    _analytics = FirebaseAnalytics.instance;
    // 개인 식별 정보 수집 비활성화
    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    _initialized = true;
  }

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── 화면 추적 ──

  Future<void> logScreenView(String screenName) async {
    if (!_initialized) return;
    await _analytics.logScreenView(screenName: screenName);
  }

  // ── 채팅방 이벤트 ──

  Future<void> logRoomCreated({required String roomType}) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'room_created',
      parameters: {'room_type': roomType},
    );
  }

  Future<void> logRoomJoined({required String roomType}) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'room_joined',
      parameters: {'room_type': roomType},
    );
  }

  Future<void> logRoomDestroyed({required String roomType}) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'room_destroyed',
      parameters: {'room_type': roomType},
    );
  }

  // ── 메시지/파일 이벤트 ──

  Future<void> logMessageSent({required String roomType}) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'message_sent',
      parameters: {'room_type': roomType},
    );
  }

  Future<void> logFileTransfer({required String fileType}) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'file_transfer',
      parameters: {'file_type': fileType},
    );
  }

  // ── 기능 사용 이벤트 ──

  Future<void> logFeatureUsed(String feature) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'feature_used',
      parameters: {'feature': feature},
    );
  }

  Future<void> logShareLink({required String roomType}) async {
    if (!_initialized) return;
    await _analytics.logEvent(
      name: 'share_link',
      parameters: {'room_type': roomType},
    );
  }
}
