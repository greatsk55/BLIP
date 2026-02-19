import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../network/api_client.dart';
import '../storage/local_storage_service.dart';
import '../storage/models/saved_room.dart';

/// 방 생성 공통 유틸리티 (SSOT)
/// HomeScreen, MyChatListScreen 등에서 공유
class RoomCreator {
  static final _api = ApiClient();

  /// 방을 생성하고 해당 방으로 네비게이션.
  /// [context] 필수, 네비게이션 + 에러 표시에 사용.
  /// 성공 시 true, 실패 시 false 반환.
  static Future<bool> createAndNavigate(BuildContext context) async {
    try {
      final result = await _api.createRoom();
      if (!context.mounted) return false;

      if (result['error'] != null) {
        _showError(context, result['error']);
        return false;
      }

      final roomId = result['roomId'] as String;
      final password = result['password'] as String;

      // 로컬 저장 (채팅 리스트에 표시용)
      final now = DateTime.now().millisecondsSinceEpoch;
      await LocalStorageService().saveRoom(
        SavedRoom(
          roomId: roomId,
          isCreator: true,
          createdAt: now,
          lastAccessedAt: now,
        ),
        password,
      );

      if (!context.mounted) return false;
      context.push('/room/$roomId', extra: password);
      return true;
    } catch (_) {
      if (context.mounted) _showError(context, 'NETWORK_ERROR');
      return false;
    }
  }

  static void _showError(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    final msg = code == 'TOO_MANY_REQUESTS'
        ? l10n.errorRateLimit
        : l10n.errorGeneric;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
