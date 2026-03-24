import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart' as crypto_lib;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/supabase/supabase_client.dart';

/// 수신된 연결 요청
class IncomingConnection {
  final String roomId;
  final String password;
  final int timestamp;

  const IncomingConnection({
    required this.roomId,
    required this.password,
    required this.timestamp,
  });
}

/// BLIP me 상태
class BlipMeState {
  final String? linkId;
  final bool loading;
  final String? error;
  final int useCount;
  final IncomingConnection? incomingConnection;
  final bool listening;

  const BlipMeState({
    this.linkId,
    this.loading = true,
    this.error,
    this.useCount = 0,
    this.incomingConnection,
    this.listening = false,
  });

  BlipMeState copyWith({
    String? linkId,
    bool? loading,
    String? error,
    int? useCount,
    IncomingConnection? incomingConnection,
    bool? listening,
    bool clearLinkId = false,
    bool clearError = false,
    bool clearIncoming = false,
  }) {
    return BlipMeState(
      linkId: clearLinkId ? null : (linkId ?? this.linkId),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      useCount: useCount ?? this.useCount,
      incomingConnection: clearIncoming
          ? null
          : (incomingConnection ?? this.incomingConnection),
      listening: listening ?? this.listening,
    );
  }
}

/// ownerToken → SHA-256 해시 (웹과 동일)
Future<String> _hashOwnerToken(String token) async {
  final bytes = utf8.encode(token);
  final digest = crypto_lib.sha256.convert(bytes);
  return digest.toString();
}

/// ownerToken 생성 (32바이트 hex)
String _generateOwnerToken() {
  final random = Random.secure();
  final bytes = Uint8List(32);
  for (int i = 0; i < 32; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

class BlipMeNotifier extends StateNotifier<BlipMeState> {
  final _api = ApiClient();
  final _storage = LocalStorageService();
  String? _ownerTokenHash;
  RealtimeChannel? _channel;

  BlipMeNotifier() : super(const BlipMeState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _storage.getBlipMeOwnerToken();
      if (token == null) {
        state = state.copyWith(loading: false);
        return;
      }

      _ownerTokenHash = await _hashOwnerToken(token);

      final result = await _api.getMyBlipMeLink(_ownerTokenHash!);
      if (result['linkId'] != null) {
        final linkId = result['linkId'] as String;
        final useCount = (result['useCount'] as num?)?.toInt() ?? 0;
        await _storage.saveBlipMeLinkId(linkId);
        state = state.copyWith(
          linkId: linkId,
          useCount: useCount,
          loading: false,
        );
        _subscribeRealtime(linkId);
      } else {
        await _storage.removeBlipMeLinkId();
        state = state.copyWith(loading: false);
      }
    } catch (e) {
      debugPrint('[BlipMe] init error: $e');
      state = state.copyWith(loading: false);
    }
  }

  Future<String> _ensureOwnerToken() async {
    if (_ownerTokenHash != null) return _ownerTokenHash!;

    var token = await _storage.getBlipMeOwnerToken();
    if (token == null) {
      token = _generateOwnerToken();
      await _storage.saveBlipMeOwnerToken(token);
    }
    _ownerTokenHash = await _hashOwnerToken(token);
    return _ownerTokenHash!;
  }

  void _subscribeRealtime(String linkId) {
    if (!isSupabaseInitialized) return;

    _channel?.unsubscribe();
    _channel = supabase.channel('blipme:$linkId');

    _channel!
        .onBroadcast(
          event: 'incoming',
          callback: (payload) {
            final data = payload;
            if (data['roomId'] != null && data['password'] != null) {
              state = state.copyWith(
                incomingConnection: IncomingConnection(
                  roomId: data['roomId'] as String,
                  password: data['password'] as String,
                  timestamp: (data['timestamp'] as num?)?.toInt() ??
                      DateTime.now().millisecondsSinceEpoch,
                ),
                useCount: state.useCount + 1,
              );
            }
          },
        )
        .subscribe((status, _) {
      if (mounted) {
        state = state.copyWith(
          listening: status == RealtimeSubscribeStatus.subscribed,
        );
      }
    });
  }

  void _unsubscribeRealtime() {
    _channel?.unsubscribe();
    _channel = null;
    if (mounted) {
      state = state.copyWith(listening: false);
    }
  }

  Future<void> createLink() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final tokenHash = await _ensureOwnerToken();
      final result = await _api.createBlipMeLink(tokenHash);

      if (result['error'] != null) {
        state = state.copyWith(
          error: result['error'] as String,
          loading: false,
        );
        return;
      }

      final linkId = result['linkId'] as String;
      await _storage.saveBlipMeLinkId(linkId);
      state = state.copyWith(
        linkId: linkId,
        useCount: 0,
        loading: false,
      );
      _subscribeRealtime(linkId);
    } catch (e) {
      state = state.copyWith(error: 'NETWORK_ERROR', loading: false);
    }
  }

  Future<void> deleteLink() async {
    if (state.linkId == null || _ownerTokenHash == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await _api.deleteBlipMeLink(
        linkId: state.linkId!,
        ownerTokenHash: _ownerTokenHash!,
      );

      if (result['success'] != true) {
        state = state.copyWith(
          error: result['error'] as String? ?? 'DELETE_FAILED',
          loading: false,
        );
        return;
      }

      _unsubscribeRealtime();
      await _storage.removeBlipMeLinkId();
      state = state.copyWith(
        clearLinkId: true,
        useCount: 0,
        loading: false,
      );
    } catch (e) {
      state = state.copyWith(error: 'NETWORK_ERROR', loading: false);
    }
  }

  Future<void> regenerateLink() async {
    if (state.linkId == null || _ownerTokenHash == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await _api.regenerateBlipMeLink(
        oldLinkId: state.linkId!,
        ownerTokenHash: _ownerTokenHash!,
      );

      if (result['error'] != null) {
        state = state.copyWith(
          error: result['error'] as String,
          loading: false,
        );
        return;
      }

      _unsubscribeRealtime();
      final newLinkId = result['linkId'] as String;
      await _storage.saveBlipMeLinkId(newLinkId);
      state = state.copyWith(
        linkId: newLinkId,
        useCount: 0,
        loading: false,
      );
      _subscribeRealtime(newLinkId);
    } catch (e) {
      state = state.copyWith(error: 'NETWORK_ERROR', loading: false);
    }
  }

  void clearIncoming() {
    state = state.copyWith(clearIncoming: true);
  }

  @override
  void dispose() {
    _unsubscribeRealtime();
    super.dispose();
  }
}

final blipMeProvider =
    StateNotifierProvider<BlipMeNotifier, BlipMeState>((ref) {
  return BlipMeNotifier();
});
