import 'package:flutter/services.dart';

/// 채팅 알림 서비스 (네이티브 시스템 사운드 + 햅틱 피드백)
/// iOS: AudioServicesPlaySystemSound (오디오 세션 간섭 없음)
/// Android: ToneGenerator (WebRTC와 독립적인 STREAM_NOTIFICATION)
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _channel = MethodChannel('com.bakkum.blip/audio');

  /// 메시지 수신 알림 (비프음 + 햅틱)
  Future<void> notifyMessageReceived() async {
    await Future.wait([
      _playBeep(),
      HapticFeedback.mediumImpact(),
    ]);
  }

  /// 메시지 발신 피드백 (가벼운 햅틱만)
  Future<void> notifyMessageSent() async {
    await HapticFeedback.lightImpact();
  }

  /// 네이티브 비프음 재생
  Future<void> _playBeep() async {
    try {
      await _channel.invokeMethod('playBeep');
    } catch (_) {
      // 재생 실패 시 무시 (보안상 중요하지 않음)
    }
  }
}
