import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/keys.dart';
import '../../../core/crypto/symmetric.dart';
import '../../../core/crypto/encrypt.dart';
import '../../../core/network/api_client.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/username.dart';
import '../domain/models/group_message.dart';
import '../domain/models/group_participant.dart';

/// 그룹 채팅 상태
enum GroupChatStatus {
  connecting,
  chatting,
  destroyed,
  kicked,
  error,
}

/// 그룹 채팅 상태 클래스
class GroupChatState {
  final List<GroupMessage> messages;
  final GroupChatStatus status;
  final String myUsername;
  final String myId;
  final List<GroupParticipant> participants;
  final bool isAdmin;

  const GroupChatState({
    this.messages = const [],
    this.status = GroupChatStatus.connecting,
    this.myUsername = '',
    this.myId = '',
    this.participants = const [],
    this.isAdmin = false,
  });

  GroupChatState copyWith({
    List<GroupMessage>? messages,
    GroupChatStatus? status,
    String? myUsername,
    String? myId,
    List<GroupParticipant>? participants,
    bool? isAdmin,
  }) {
    return GroupChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      myUsername: myUsername ?? this.myUsername,
      myId: myId ?? this.myId,
      participants: participants ?? this.participants,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}

/// 그룹 채팅 최대 표시 메시지 수
const _maxVisibleMessages = 50;

List<GroupMessage> _limitMessages(List<GroupMessage> messages) {
  if (messages.length <= _maxVisibleMessages) return messages;
  return messages.sublist(messages.length - _maxVisibleMessages);
}

/// 그룹 채팅 파라미터
class GroupChatParams {
  final String roomId;
  final String password;
  final bool isAdmin;
  final String? adminToken;

  const GroupChatParams({
    required this.roomId,
    required this.password,
    this.isAdmin = false,
    this.adminToken,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupChatParams &&
          roomId == other.roomId &&
          password == other.password;

  @override
  int get hashCode => roomId.hashCode ^ password.hashCode;
}

/// GroupChatNotifier: Supabase Realtime + 대칭키 암호화
class GroupChatNotifier extends StateNotifier<GroupChatState> {
  final GroupChatParams params;
  final ApiClient _api;
  final LocalStorageService _storage = LocalStorageService();

  RealtimeChannel? _channel;
  Uint8List? _symmetricKey;
  String? _authKeyHash;
  bool _selfTracked = false;

  GroupChatNotifier({
    required this.params,
    ApiClient? api,
  })  : _api = api ?? ApiClient(),
        super(GroupChatState(
          myUsername: generateUsername(),
          myId: const Uuid().v4(),
          isAdmin: params.isAdmin,
        )) {
    _loadHistory();
    _init();
  }

  /// 로컬 히스토리 로드
  Future<void> _loadHistory() async {
    final saved = await _storage.getChatMessages(params.roomId);
    if (saved.isNotEmpty && mounted) {
      state = state.copyWith(
        messages: saved
            .map((m) => GroupMessage.fromJson(m, myId: state.myId))
            .toList(),
      );
    }
  }

  /// 메시지 로컬 저장
  Future<void> _persistMessages() async {
    await _storage.saveChatMessages(
      params.roomId,
      state.messages.map((m) => m.toJson()).toList(),
    );
  }

  String? get authKeyHash => _authKeyHash;

  Future<void> _init() async {
    try {
      // PBKDF2로 대칭키 유도 — Isolate에서 실행 (UI 블로킹 방지)
      final derived = await deriveKeysFromPasswordAsync(params.password, params.roomId);
      _symmetricKey = derived.encryptionSeed;
      _authKeyHash = hashAuthKey(derived.authKey);

      // Supabase 채널 (group:{roomId})
      _channel = supabase.channel(
        'group:${params.roomId}',
        opts: const RealtimeChannelConfig(self: false),
      );

      _setupListeners();

      _channel!.subscribe((status, [error]) async {
        debugPrint('[GroupChat] subscribe: status=$status, error=$error');
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _channel!.track({
            'userId': state.myId,
            'username': state.myUsername,
            'joinedAt': DateTime.now().millisecondsSinceEpoch,
            'isAdmin': params.isAdmin,
          });
          _selfTracked = true;

          if (mounted) {
            state = state.copyWith(status: GroupChatStatus.chatting);
          }
        }
      });
    } catch (_) {
      if (mounted) {
        state = state.copyWith(status: GroupChatStatus.error);
      }
    }
  }

  /// payload unwrap (Supabase Dart SDK 구조)
  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    if (raw.containsKey('payload') && raw['payload'] is Map<String, dynamic>) {
      return raw['payload'] as Map<String, dynamic>;
    }
    return raw;
  }

  void _setupListeners() {
    // 메시지 수신
    _channel!.onBroadcast(event: 'message', callback: (raw) {
      if (!mounted || _symmetricKey == null) return;
      final payload = _unwrap(raw);
      final ciphertext = payload['ciphertext'] as String?;
      final nonce = payload['nonce'] as String?;
      if (ciphertext == null || nonce == null) return;

      final decrypted = decryptSymmetric(
        EncryptedPayload(ciphertext: ciphertext, nonce: nonce),
        _symmetricKey!,
      );

      if (decrypted != null) {
        state = state.copyWith(
          messages: _limitMessages([
            ...state.messages,
            GroupMessage(
              id: (payload['id'] as String?) ?? const Uuid().v4(),
              senderId: (payload['senderId'] as String?) ?? 'unknown',
              senderName: (payload['senderName'] as String?) ?? 'Unknown',
              content: decrypted,
              timestamp: (payload['timestamp'] as int?) ??
                  DateTime.now().millisecondsSinceEpoch,
              isMine: false,
            ),
          ]),
        );
        _persistMessages();
      }
    });

    // 유저 퇴장
    _channel!.onBroadcast(event: 'user_left', callback: (raw) {
      if (!mounted) return;
      final payload = _unwrap(raw);
      state = state.copyWith(
        messages: _limitMessages([
          ...state.messages,
          GroupMessage(
            id: const Uuid().v4(),
            senderId: 'system',
            senderName: 'SYSTEM',
            content: '${payload['username'] ?? 'USER'} LEFT',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isMine: false,
          ),
        ]),
      );
    });

    // 강퇴 수신
    _channel!.onBroadcast(event: 'kick_user', callback: (raw) {
      if (!mounted) return;
      final payload = _unwrap(raw);
      if (payload['userId'] == state.myId) {
        _cleanup();
        state = state.copyWith(status: GroupChatStatus.kicked);
      }
    });

    // 방 폭파
    _channel!.onBroadcast(event: 'room_destroyed', callback: (_) {
      if (!mounted) return;
      _cleanup();
      state = state.copyWith(
        messages: [],
        status: GroupChatStatus.destroyed,
      );
    });

    // Presence 동기화
    _channel!.onPresenceSync((_) {
      if (!mounted || !_selfTracked) return;
      final users = _getAllPresences();
      final participants = users
          .map((p) => GroupParticipant(
                userId: p.payload['userId'] as String? ?? '',
                username: p.payload['username'] as String? ?? '',
                joinedAt: p.payload['joinedAt'] as int?,
                isAdmin: p.payload['isAdmin'] as bool? ?? false,
              ))
          .toList();
      state = state.copyWith(participants: participants);
    });

    // Presence join → 시스템 메시지
    _channel!.onPresenceJoin((payload) {
      if (!mounted) return;
      for (final p in payload.newPresences) {
        final userId = p.payload['userId'] as String?;
        final username = p.payload['username'] as String?;
        if (userId != null && userId != state.myId && username != null) {
          state = state.copyWith(
            messages: _limitMessages([
              ...state.messages,
              GroupMessage(
                id: const Uuid().v4(),
                senderId: 'system',
                senderName: 'SYSTEM',
                content: '$username JOINED',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                isMine: false,
              ),
            ]),
          );
        }
      }
    });
  }

  List<Presence> _getAllPresences() {
    final states = _channel!.presenceState();
    return states.expand((s) => s.presences).toList();
  }

  /// 메시지 전송
  void sendMessage(String content) {
    if (_channel == null || _symmetricKey == null || content.trim().isEmpty) {
      return;
    }

    final encrypted = encryptSymmetric(content.trim(), _symmetricKey!);
    final messageId = const Uuid().v4();

    _channel!.sendBroadcastMessage(
      event: 'message',
      payload: {
        'id': messageId,
        'senderId': state.myId,
        'senderName': state.myUsername,
        'ciphertext': encrypted.ciphertext,
        'nonce': encrypted.nonce,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );

    state = state.copyWith(
      messages: _limitMessages([
        ...state.messages,
        GroupMessage(
          id: messageId,
          senderId: state.myId,
          senderName: state.myUsername,
          content: content.trim(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isMine: true,
        ),
      ]),
    );
    _persistMessages();
  }

  /// 강퇴 (관리자 → broadcast)
  void kickUser(String userId) {
    if (_channel == null || !params.isAdmin) return;
    _channel!.sendBroadcastMessage(
      event: 'kick_user',
      payload: {
        'userId': userId,
        'adminId': state.myId,
      },
    );
  }

  /// 방 폭파 (관리자 → broadcast + API)
  Future<void> destroyRoom() async {
    if (!params.isAdmin || params.adminToken == null) return;

    _channel?.sendBroadcastMessage(
      event: 'room_destroyed',
      payload: {'adminId': state.myId},
    );

    try {
      await _api.groupAdmin(
        roomId: params.roomId,
        adminToken: params.adminToken!,
        action: 'destroy',
      );
    } catch (_) {}

    _cleanup();
    state = state.copyWith(
      messages: [],
      status: GroupChatStatus.destroyed,
    );
  }

  /// 퇴장 (완전히 나가기 - user_left 전송 + API leave)
  void disconnect() {
    if (_channel != null) {
      _channel!.untrack();
      _channel!.sendBroadcastMessage(
        event: 'user_left',
        payload: {
          'userId': state.myId,
          'username': state.myUsername,
        },
      );
    }

    // API leave 호출
    if (_authKeyHash != null) {
      _api
          .groupLeave(roomId: params.roomId, authKeyHash: _authKeyHash!)
          .catchError((_) {});
    }

    _cleanup();
    state = state.copyWith(
      messages: [],
      status: GroupChatStatus.destroyed,
    );
  }

  /// 페이지만 나가기 (채널 정리만, user_left/API leave 안 보냄)
  void softDisconnect() {
    _selfTracked = false;
    if (_channel != null) {
      _channel!.untrack();
      _channel!.unsubscribe();
      _channel = null;
    }
    if (_symmetricKey != null) {
      _symmetricKey!.fillRange(0, _symmetricKey!.length, 0);
      _symmetricKey = null;
    }
  }

  /// 앱 복귀 시 Presence 재등록
  Future<void> reconnectPresence() async {
    if (_channel == null || !mounted) return;

    final trackData = {
      'userId': state.myId,
      'username': state.myUsername,
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
      'isAdmin': params.isAdmin,
    };

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _channel!.track(trackData);
        _selfTracked = true;
        return;
      } catch (_) {
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted || _channel == null) return;
        }
      }
    }
  }

  void _cleanup() {
    _selfTracked = false;
    if (_channel != null) {
      _channel!.untrack();
      _channel!.unsubscribe();
      _channel = null;
    }
    if (_symmetricKey != null) {
      _symmetricKey!.fillRange(0, _symmetricKey!.length, 0);
      _symmetricKey = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

/// GroupChatNotifier Provider
final groupChatNotifierProvider = StateNotifierProvider.autoDispose
    .family<GroupChatNotifier, GroupChatState, GroupChatParams>(
  (ref, params) {
    final link = ref.keepAlive();
    final notifier = GroupChatNotifier(params: params);
    ref.onDispose(() => link.close());
    return notifier;
  },
);
