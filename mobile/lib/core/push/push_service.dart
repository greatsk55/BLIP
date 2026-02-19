import 'package:firebase_messaging/firebase_messaging.dart';

import '../network/api_client.dart';

/// 백그라운드 메시지 핸들러 (top-level function 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서는 최소 처리만 (알림은 OS가 자동 표시)
}

/// FCM 푸시 알림 서비스
class PushService {
  static final PushService _instance = PushService._();
  static PushService get instance => _instance;
  PushService._();

  final ApiClient _api = ApiClient();
  String? _fcmToken;
  bool _initialized = false;

  /// 앱 시작 시 초기화
  Future<void> init() async {
    if (_initialized) return;
    try {
      final messaging = FirebaseMessaging.instance;

      // 알림 권한 요청
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // FCM 토큰 가져오기
      _fcmToken = await messaging.getToken();

      // 토큰 갱신 리스너
      messaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
      });

      // 메시지 핸들러 설정
      _setupMessageHandlers();

      _initialized = true;
    } catch (_) {
      // Firebase 초기화 실패 시 무시 (푸시는 optional)
    }
  }

  /// FCM 토큰 (캐시)
  String? get token => _fcmToken;

  /// Firebase 사용 가능 여부
  bool get isAvailable => _fcmToken != null;

  /// 특정 Room에 FCM 토큰 등록
  Future<void> registerForRoom(String roomId, String authKeyHash) async {
    if (_fcmToken == null) return;
    try {
      await _api.registerPushToken(
        roomId: roomId,
        fcmToken: _fcmToken!,
        authKeyHash: authKeyHash,
      );
    } catch (_) {
      // 실패 시 무시 (푸시는 optional)
    }
  }

  /// 상대방에게 푸시 발송 요청
  Future<bool> sendContactNotification({
    required String roomId,
    required String authKeyHash,
  }) async {
    try {
      final result = await _api.sendPushNotification(
        roomId: roomId,
        authKeyHash: authKeyHash,
      );
      return result['error'] == null;
    } catch (_) {
      return false;
    }
  }

  /// 포그라운드/백그라운드 메시지 핸들러 설정
  void _setupMessageHandlers() {
    // 백그라운드 핸들러
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    // 포그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // 포그라운드에서는 앱 내 알림으로 처리 가능
      // (현재는 별도 처리 없음 — 필요 시 로컬 알림 추가)
    });

    // 알림 탭으로 앱 진입
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // 딥링크 데이터가 있으면 해당 화면으로 이동 가능
      // (GoRouter가 딥링크를 자동 처리하므로 별도 로직 불필요)
    });
  }
}
