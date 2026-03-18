import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 인앱 리뷰 유도 서비스 (SSOT)
///
/// "기분 좋은 타이밍" 전략:
/// - 성공적인 채팅(피어와 연결 + 메시지 교환) 3회 완료 후 첫 리뷰 요청
/// - 이후 7회마다 재요청 (영구 닫기하지 않은 경우)
/// - 최소 7일 간격으로만 요청
///
/// Google Play / App Store 네이티브 리뷰 다이얼로그 사용
class ReviewService {
  static const _successfulChatsKey = 'blip_review_successful_chats';
  static const _lastPromptKey = 'blip_review_last_prompt_at';
  static const _dismissedKey = 'blip_review_dismissed';

  static const _minSuccessfulChats = 3;
  static const _promptIntervalChats = 7;
  static const _minPromptGapMs = 7 * 24 * 60 * 60 * 1000; // 7일

  /// 싱글턴
  static final ReviewService _instance = ReviewService._();
  factory ReviewService() => _instance;
  ReviewService._();

  final InAppReview _inAppReview = InAppReview.instance;

  /// 성공적인 채팅 완료 시 호출
  /// 조건 충족 시 네이티브 리뷰 다이얼로그 표시
  Future<void> recordSuccessfulChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 영구 닫기한 경우 무시
      if (prefs.getBool(_dismissedKey) ?? false) return;

      // 성공 횟수 증가
      final count = (prefs.getInt(_successfulChatsKey) ?? 0) + 1;
      await prefs.setInt(_successfulChatsKey, count);

      // 조건 체크: 첫 N번째 또는 이후 매 M번째
      final shouldPrompt = count == _minSuccessfulChats ||
          (count > _minSuccessfulChats &&
              (count - _minSuccessfulChats) % _promptIntervalChats == 0);

      if (!shouldPrompt) return;

      // 최소 간격 체크
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastPrompt = prefs.getInt(_lastPromptKey) ?? 0;
      if (lastPrompt > 0 && now - lastPrompt < _minPromptGapMs) return;

      // 네이티브 리뷰 가능 여부 확인
      if (await _inAppReview.isAvailable()) {
        await prefs.setInt(_lastPromptKey, now);
        await _inAppReview.requestReview();
        debugPrint('[ReviewService] In-app review requested (chat #$count)');
      } else {
        debugPrint('[ReviewService] In-app review not available');
      }
    } catch (e) {
      debugPrint('[ReviewService] Error: $e');
    }
  }

  /// "다시 보지 않기" (설정에서 호출 가능)
  Future<void> dismissForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
  }

  /// 리뷰 상태 리셋 (테스트용)
  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_successfulChatsKey);
    await prefs.remove(_lastPromptKey);
    await prefs.remove(_dismissedKey);
  }
}
