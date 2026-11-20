import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Firebase Analytics 서비스 (Singleton)
/// - 화면 전환, 주요 사용자 행동 이벤트 추적
/// SDK identifiers and interaction events are disclosed in the privacy policy.
class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  FirebaseAnalytics? _analytics;
  late final NavigatorObserver observer = _AnalyticsRouteObserver(this);
  bool _initialized = false;

  Future<void> init() async {
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);
    _analytics = analytics;
    _initialized = true;
  }

  // ── 화면 추적 ──

  Future<void> logScreenView(String screenName) async {
    if (!_initialized) return;
    await _analytics?.logScreenView(screenName: screenName);
  }

  // ── 채팅방 이벤트 ──

  Future<void> logRoomCreated({required String roomType}) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'room_created',
      parameters: {'room_type': roomType},
    );
  }

  Future<void> logRoomJoined({required String roomType}) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'room_joined',
      parameters: {'room_type': roomType},
    );
  }

  Future<void> logRoomDestroyed({required String roomType}) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'room_destroyed',
      parameters: {'room_type': roomType},
    );
  }

  // ── 메시지/파일 이벤트 ──

  Future<void> logMessageSent({required String roomType}) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'message_sent',
      parameters: {'room_type': roomType},
    );
  }

  Future<void> logFileTransfer({required String fileType}) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'file_transfer',
      parameters: {'file_type': fileType},
    );
  }

  // ── 기능 사용 이벤트 ──

  Future<void> logFeatureUsed(String feature) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'feature_used',
      parameters: {'feature': feature},
    );
  }

  Future<void> logShareLink({required String roomType}) async {
    if (!_initialized) return;
    await _analytics?.logEvent(
      name: 'share_link',
      parameters: {'room_type': roomType},
    );
  }
}

class _AnalyticsRouteObserver extends NavigatorObserver {
  _AnalyticsRouteObserver(this.service);
  final AnalyticsService service;

  void _track(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) {
      service.logScreenView(name).catchError((Object error) {
        debugPrint('[BLIP] Screen analytics failed: $error');
      });
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(route);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _track(previousRoute);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _track(newRoute);
}
