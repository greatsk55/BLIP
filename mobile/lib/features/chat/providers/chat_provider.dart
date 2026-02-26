import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/crypto/crypto.dart';
import '../../../core/network/api_client.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/utils/username.dart';
import '../domain/models/message.dart';

/// 채팅 상태 (web: ChatStatus)
enum ChatStatus {
  loading,
  passwordRequired,
  created,
  connecting,
  chatting,
  destroyed,
  expired,
  roomFull,
  error,
}

/// 채팅 상태 클래스
class ChatState {
  final List<DecryptedMessage> messages;
  final ChatStatus status;
  final String myUsername;
  final String myId;
  final String? peerUsername;
  final bool peerConnected;
  final bool isInitiator;

  const ChatState({
    this.messages = const [],
    this.status = ChatStatus.connecting,
    this.myUsername = '',
    this.myId = '',
    this.peerUsername,
    this.peerConnected = false,
    this.isInitiator = false,
  });

  ChatState copyWith({
    List<DecryptedMessage>? messages,
    ChatStatus? status,
    String? myUsername,
    String? myId,
    String? peerUsername,
    bool? peerConnected,
    bool? isInitiator,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      myUsername: myUsername ?? this.myUsername,
      myId: myId ?? this.myId,
      peerUsername: peerUsername ?? this.peerUsername,
      peerConnected: peerConnected ?? this.peerConnected,
      isInitiator: isInitiator ?? this.isInitiator,
    );
  }
}

/// 화면에 유지할 최대 메시지 수 (web: MAX_VISIBLE_MESSAGES)
const _maxVisibleMessages = 4;

/// 메시지 배열을 최대 N개로 유지 (오래된 미디어 메모리 해제)
List<DecryptedMessage> _limitMessages(List<DecryptedMessage> messages) {
  if (messages.length <= _maxVisibleMessages) return messages;
  return messages.sublist(messages.length - _maxVisibleMessages);
}

/// ChatNotifier: useChat.ts → Riverpod StateNotifier
/// Supabase Broadcast + Presence + ECDH 키교환 + E2EE 메시지
class ChatNotifier extends StateNotifier<ChatState> {
  final String roomId;
  final String password;
  final ApiClient _api;

  RealtimeChannel? _channel;
  BlipKeyPair? _keyPair;
  Uint8List? _sharedSecret;
  bool _selfTracked = false;

  /// 10분 비활성 시 방 자동 파쇄 타이머
  /// 메시지 송수신 또는 키 교환 시 리셋
  static const _inactivityTimeout = Duration(minutes: 10);
  Timer? _inactivityTimer;

  /// WebRTC 연결에 필요한 값 외부 노출
  RealtimeChannel? get channel => _channel;
  Uint8List? get sharedSecret => _sharedSecret;

  /// WebRTC 시그널링 포워딩 콜백 (subscribe 전에 등록, webrtc_provider가 설정)
  void Function(Map<String, dynamic>)? onWebrtcOffer;
  void Function(Map<String, dynamic>)? onWebrtcAnswer;
  void Function(Map<String, dynamic>)? onWebrtcIce;

  ChatNotifier({
    required this.roomId,
    required this.password,
    ApiClient? api,
  })  : _api = api ?? ApiClient(),
        super(ChatState(
          myUsername: generateUsername(),
          myId: const Uuid().v4(),
        )) {
    _init();
  }

  Future<void> _init() async {
    try {
      // 1. ECDH 키쌍 생성 (랜덤 → Perfect Forward Secrecy)
      _keyPair = generateKeyPair();

      // 2. Supabase 채널 구독
      _channel = supabase.channel(
        'room:$roomId',
        opts: const RealtimeChannelConfig(self: false),
      );

      _setupBroadcastListeners();
      _setupPresenceListeners();

      // 3. 채널 구독 시작
      _channel!.subscribe((status, [error]) async {
        debugPrint('[Chat] subscribe callback: status=$status, error=$error');
        if (status == RealtimeSubscribeStatus.subscribed) {
          // Presence에 자신 등록
          await _channel!.track({
            'userId': state.myId,
            'username': state.myUsername,
            'publicKey': publicKeyToString(_keyPair!.publicKey),
            'joinedAt': DateTime.now().millisecondsSinceEpoch,
          });
          _selfTracked = true;

          // 공개키 브로드캐스트 (Presence sync보다 빠른 교환)
          await _channel!.sendBroadcastMessage(
            event: 'key_exchange',
            payload: {
              'userId': state.myId,
              'username': state.myUsername,
              'publicKey': publicKeyToString(_keyPair!.publicKey),
            },
          );

          if (mounted) {
            state = state.copyWith(status: ChatStatus.chatting);
          }
        }
      });
    } catch (_) {
      if (mounted) {
        state = state.copyWith(status: ChatStatus.error);
      }
    }
  }

  /// onBroadcast 콜백의 payload에서 실제 데이터 추출.
  /// Supabase Dart SDK는 { event, payload, type } 구조로 전달 →
  /// 실제 데이터는 payload['payload']에 있음.
  static Map<String, dynamic> _unwrapPayload(Map<String, dynamic> raw) {
    if (raw.containsKey('payload') && raw['payload'] is Map<String, dynamic>) {
      return raw['payload'] as Map<String, dynamic>;
    }
    return raw;
  }

  void _setupBroadcastListeners() {
    // 공개키 교환 수신
    _channel!.onBroadcast(event: 'key_exchange', callback: (raw) {
      if (!mounted || _keyPair == null) return;
      if (_sharedSecret != null) return; // 이미 교환 완료

      final payload = _unwrapPayload(raw);
      final pubKeyStr = payload['publicKey'] as String?;
      final userIdStr = payload['userId'] as String?;
      final usernameStr = payload['username'] as String?;
      if (pubKeyStr == null || userIdStr == null || usernameStr == null) return;

      final peerPublicKey = stringToPublicKey(pubKeyStr);
      _sharedSecret = computeSharedSecret(peerPublicKey, _keyPair!.secretKey);

      // userId 비교로 WebRTC initiator 결정
      final isInit = state.myId.compareTo(userIdStr) < 0;

      _resetInactivityTimer();

      state = state.copyWith(
        peerUsername: usernameStr,
        peerConnected: true,
        isInitiator: isInit,
        status: ChatStatus.chatting,
        messages: _limitMessages([
          ...state.messages,
          DecryptedMessage(
            id: const Uuid().v4(),
            senderId: 'system',
            senderName: 'SYSTEM',
            content: '$usernameStr CONNECTED',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            isMine: false,
          ),
        ]),
      );
    });

    // 암호화된 메시지 수신
    _channel!.onBroadcast(event: 'message', callback: (raw) {
      if (!mounted || _sharedSecret == null) return;

      final payload = _unwrapPayload(raw);
      final ciphertext = payload['ciphertext'] as String?;
      final nonce = payload['nonce'] as String?;
      if (ciphertext == null || nonce == null) return;

      final decrypted = decryptMessage(
        EncryptedPayload(ciphertext: ciphertext, nonce: nonce),
        _sharedSecret!,
      );

      if (decrypted != null) {
        _resetInactivityTimer();
        state = state.copyWith(
          messages: _limitMessages([
            ...state.messages,
            DecryptedMessage(
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
      }
    });

    // 상대방 퇴장 → 즉시 방 폭파
    _channel!.onBroadcast(event: 'user_left', callback: (_) {
      if (!mounted) return;
      _destroyLocally();
    });

    // WebRTC 시그널링 이벤트 (subscribe 전에 등록 → webrtc_provider로 포워딩)
    _channel!.onBroadcast(event: 'webrtc_offer', callback: (raw) {
      onWebrtcOffer?.call(raw);
    });
    _channel!.onBroadcast(event: 'webrtc_answer', callback: (raw) {
      onWebrtcAnswer?.call(raw);
    });
    _channel!.onBroadcast(event: 'webrtc_ice', callback: (raw) {
      onWebrtcIce?.call(raw);
    });
  }

  /// presenceState()에서 모든 Presence 객체를 평탄화
  List<Presence> _getAllPresences() {
    final states = _channel!.presenceState();
    return states.expand((s) => s.presences).toList();
  }

  void _setupPresenceListeners() {
    // Presence 동기화
    _channel!.onPresenceSync((_) {
      if (!mounted) return;
      if (!_selfTracked) return;
      final users = _getAllPresences();
      debugPrint('[Chat] presenceSync: ${users.length} users');

      // DB participant_count 업데이트
      _api.updateParticipantCount(roomId, users.length).catchError((_) {});

      // 3명 이상 → 후발 참여자 자동 퇴장
      if (users.length > 2) {
        final sorted = [...users]..sort(
            (a, b) => ((a.payload['joinedAt'] as int?) ?? 0)
                .compareTo((b.payload['joinedAt'] as int?) ?? 0),
          );
        final latestUser = sorted.last;
        if (latestUser.payload['userId'] == state.myId) {
          _cleanup();
          if (mounted) state = state.copyWith(status: ChatStatus.roomFull);
          return;
        }
      }

      // 상대방 공개키로 공유 비밀 계산
      final peer = users
          .where((u) => u.payload['userId'] != state.myId)
          .firstOrNull;

      if (peer != null &&
          _keyPair != null &&
          _sharedSecret == null) {
        final peerPubKeyStr = peer.payload['publicKey'] as String?;
        if (peerPubKeyStr != null && peerPubKeyStr.isNotEmpty) {
          final peerPublicKey = stringToPublicKey(peerPubKeyStr);
          _sharedSecret =
              computeSharedSecret(peerPublicKey, _keyPair!.secretKey);
          final isInit = state.myId
                  .compareTo(peer.payload['userId'] as String) <
              0;
          state = state.copyWith(
            peerUsername: peer.payload['username'] as String,
            peerConnected: true,
            isInitiator: isInit,
            status: ChatStatus.chatting,
          );
        }
      }
    });

    // Presence leave: participant_count만 업데이트
    // 방 파쇄는 오직 명시적 EXIT('user_left' broadcast)로만 처리
    // Presence leave는 일시적 이탈(사진 선택, 네트워크 끊김 등)일 수 있으므로
    // 방 파쇄 트리거로 사용하지 않음
    _channel!.onPresenceLeave((payload) {
      if (!mounted || !_selfTracked) return;
      debugPrint('[Chat] presenceLeave: left=${payload.leftPresences.length}, '
          'remaining=${payload.currentPresences.length}');
      _api
          .updateParticipantCount(roomId, payload.currentPresences.length)
          .catchError((_) {});
    });
  }

  /// 메시지 전송
  void sendMessage(String content) {
    if (_channel == null || _sharedSecret == null || content.trim().isEmpty) {
      return;
    }

    _resetInactivityTimer();

    final encrypted = encryptMessage(content.trim(), _sharedSecret!);
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

    // 내 메시지 즉시 표시
    state = state.copyWith(
      messages: _limitMessages([
        ...state.messages,
        DecryptedMessage(
          id: messageId,
          senderId: state.myId,
          senderName: state.myUsername,
          content: content.trim(),
          timestamp: DateTime.now().millisecondsSinceEpoch,
          isMine: true,
        ),
      ]),
    );
  }

  /// 미디어 메시지 추가/교체 (WebRTC에서 호출)
  /// 동일 ID가 이미 있으면 교체 (HEADER→DONE 업데이트), 없으면 추가
  void addMediaMessage(DecryptedMessage message) {
    _resetInactivityTimer();
    final idx = state.messages.indexWhere((m) => m.id == message.id);
    final List<DecryptedMessage> updated;
    if (idx >= 0) {
      // DONE 패킷: 기존 HEADER 메시지를 완성된 미디어로 교체
      updated = [...state.messages];
      updated[idx] = message;
    } else {
      // HEADER 패킷: 새 메시지 추가
      updated = [...state.messages, message];
    }
    state = state.copyWith(messages: _limitMessages(updated));
  }

  /// 전송 진행률 업데이트 (WebRTC에서 호출)
  void updateTransferProgress(String transferId, double progress) {
    state = state.copyWith(
      messages: state.messages.map((msg) {
        return msg.id == transferId
            ? msg.copyWith(transferProgress: progress)
            : msg;
      }).toList(),
    );
  }

  /// 앱 복귀 시 Presence 재등록
  /// 백그라운드 동안 WebSocket이 끊겨 Presence가 해제된 경우 복구
  /// 채널이 아직 재연결 중일 수 있으므로 최대 3회 재시도
  Future<void> reconnectPresence() async {
    if (_channel == null || !mounted) return;

    final trackData = {
      'userId': state.myId,
      'username': state.myUsername,
      'publicKey': _keyPair != null
          ? publicKeyToString(_keyPair!.publicKey)
          : '',
      'joinedAt': DateTime.now().millisecondsSinceEpoch,
    };

    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        await _channel!.track(trackData);
        _selfTracked = true;
        return;
      } catch (_) {
        // 채널이 아직 재연결 중 → 대기 후 재시도
        if (attempt < 2) {
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted || _channel == null) return;
        }
      }
    }
  }

  /// 비활성 타이머 리셋 (메시지 송수신, 키 교환 시 호출)
  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, () {
      if (!mounted) return;
      _destroyLocally();
    });
  }

  /// 명시적 퇴장 (EXIT 버튼)
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
      _channel!.unsubscribe();
      _channel = null;
    }

    _zeroizeKeys();
    state = state.copyWith(
      messages: [],
      status: ChatStatus.destroyed,
      peerConnected: false,
      peerUsername: null,
    );
  }

  /// 내부 파쇄 (상대방 퇴장 또는 비활성 타이머)
  void _destroyLocally() {
    debugPrint('[Chat] _destroyLocally called');
    debugPrint(StackTrace.current.toString());
    _cleanup();
    _api.updateParticipantCount(roomId, 0).catchError((_) {});
    state = state.copyWith(
      messages: [],
      status: ChatStatus.destroyed,
      peerConnected: false,
      peerUsername: null,
    );
  }

  /// 채널 정리
  void _cleanup() {
    _selfTracked = false;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    if (_channel != null) {
      _channel!.untrack();
      _channel!.unsubscribe();
      _channel = null;
    }
    _zeroizeKeys();
  }

  /// 키 메모리 제로화 (보안)
  void _zeroizeKeys() {
    if (_keyPair != null) {
      _keyPair!.secretKey.fillRange(0, _keyPair!.secretKey.length, 0);
      _keyPair = null;
    }
    if (_sharedSecret != null) {
      _sharedSecret!.fillRange(0, _sharedSecret!.length, 0);
      _sharedSecret = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}

/// ChatNotifier Provider (roomId + password 기반)
/// keepAlive: ImagePicker 등 시스템 다이얼로그로 인한 임시 background 전환 시
/// dispose 방지. ChatScreen.dispose()에서 명시적으로 invalidate.
final chatNotifierProvider = StateNotifierProvider.autoDispose
    .family<ChatNotifier, ChatState, ({String roomId, String password})>(
  (ref, params) {
    final link = ref.keepAlive();
    final notifier = ChatNotifier(
      roomId: params.roomId,
      password: params.password,
    );
    ref.onDispose(() => link.close());
    return notifier;
  },
);
