import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' hide MessageType;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'dart:io';

import '../../../core/constants/app_constants.dart';
import '../../../core/crypto/crypto.dart';
import '../../../core/media/chunk.dart';
import '../../../core/media/media_processor.dart' show generateVideoThumbnail;
import '../../../core/network/api_client.dart';
import '../domain/models/message.dart';
import 'chat_provider.dart';

/// WebRTC 연결 상태
enum WebRtcStatus { idle, connecting, connected, failed }

/// WebRTC 상태
class WebRtcState {
  final WebRtcStatus status;
  final String? error;

  const WebRtcState({
    this.status = WebRtcStatus.idle,
    this.error,
  });

  WebRtcState copyWith({WebRtcStatus? status, String? error}) {
    return WebRtcState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// 수신 중인 파일 전송 추적
class _IncomingTransfer {
  final FileTransferHeader header;
  final Map<int, Uint8List> chunks = {};
  int receivedCount = 0;

  _IncomingTransfer(this.header);
}

/// WebRTC DataChannel P2P 미디어 전송
/// web: useWebRTC.ts 동일 바이너리 프로토콜 (상호운용)
class WebRtcNotifier extends StateNotifier<WebRtcState> {
  final ChatNotifier chatNotifier;
  final ApiClient _api;

  RTCPeerConnection? _pc;
  RTCDataChannel? _dc;
  bool _pcReady = false;

  // 시그널링 큐 (PeerConnection 준비 전 도착한 신호)
  final List<Map<String, dynamic>> _pendingSignals = [];

  // 수신 중인 전송 추적
  final Map<String, _IncomingTransfer> _incomingTransfers = {};

  // 흐름 제어
  Completer<void>? _bufferDrain;
  static const _sendDelayMs = 5; // bufferedAmount 미지원 시 청크간 딜레이 (ms)

  WebRtcNotifier({
    required this.chatNotifier,
    ApiClient? api,
  })  : _api = api ?? ApiClient(),
        super(const WebRtcState()) {
    _init();
  }

  Uint8List? get _sharedSecret => chatNotifier.sharedSecret;
  RealtimeChannel? get _channel => chatNotifier.channel;

  Future<void> _init() async {
    if (_channel == null || _sharedSecret == null) return;

    state = state.copyWith(status: WebRtcStatus.connecting);

    // 1. 시그널링 리스너를 먼저 등록 (race condition 방지)
    _setupSignalingListeners();

    try {
      // 2. TURN 자격증명 가져오기
      final turnResult = await _api.fetchTurnCredentials();
      final iceServers = (turnResult['iceServers'] as List?) ?? [];

      // 3. PeerConnection 생성 (TURN-only)
      final config = <String, dynamic>{
        'iceServers': iceServers
            .map((s) => {
                  'urls': s['urls'],
                  if (s['username'] != null) 'username': s['username'],
                  if (s['credential'] != null) 'credential': s['credential'],
                })
            .toList(),
        'iceTransportPolicy': 'relay', // TURN-only (IP 노출 방지)
      };

      _pc = await createPeerConnection(config);
      _pcReady = true;

      // 4. ICE candidate 수집 → 암호화 후 브로드캐스트
      _pc!.onIceCandidate = (candidate) {
        if (_channel == null || _sharedSecret == null) return;
        final encrypted = encryptMessage(
          jsonEncode({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          }),
          _sharedSecret!,
        );
        _channel!.sendBroadcastMessage(
          event: 'webrtc_ice',
          payload: encrypted.toJson(),
        );
      };

      // 5. Initiator vs Responder
      final isInitiator = chatNotifier.state.isInitiator;

      if (isInitiator) {
        // DataChannel 생성 (ordered: true)
        _dc = await _pc!.createDataChannel(
          'file-transfer',
          RTCDataChannelInit()..ordered = true,
          // maxRetransmits 미설정 → SCTP 완전 신뢰성 모드
          // (bufferedAmount 미지원 환경에서 청크 드롭 방지)
        );
        _setupDataChannel(_dc!);

        // Offer 생성 → 암호화 후 브로드캐스트
        final offer = await _pc!.createOffer();
        await _pc!.setLocalDescription(offer);
        final encrypted = encryptMessage(
          jsonEncode({'type': offer.type, 'sdp': offer.sdp}),
          _sharedSecret!,
        );
        _channel!.sendBroadcastMessage(
          event: 'webrtc_offer',
          payload: encrypted.toJson(),
        );
      } else {
        // Responder: DataChannel은 ondatachannel에서 받음
        _pc!.onDataChannel = (channel) {
          _dc = channel;
          _setupDataChannel(_dc!);
        };
      }

      // 6. 대기 중인 시그널 처리
      _flushPendingSignals();
    } catch (e) {
      state = state.copyWith(
        status: WebRtcStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Supabase broadcast payload에서 ciphertext/nonce 추출.
  /// 중첩 깊이에 상관없이 최대 3단계 .payload를 unwrap한다.
  /// self: false 설정으로 자기 메시지는 수신하지 않으므로 senderId 체크 불필요.
  static Map<String, dynamic>? _extractCrypto(Map<String, dynamic> raw) {
    Map<String, dynamic> obj = raw;
    for (var i = 0; i < 3; i++) {
      if (obj.containsKey('ciphertext') && obj.containsKey('nonce')) return obj;
      if (obj.containsKey('payload') && obj['payload'] is Map<String, dynamic>) {
        obj = obj['payload'] as Map<String, dynamic>;
      } else {
        break;
      }
    }
    if (obj.containsKey('ciphertext') && obj.containsKey('nonce')) return obj;
    return null;
  }

  /// 시그널링 리스너 등록 — chatNotifier의 포워딩 콜백 사용 (subscribe 전에 등록됨)
  void _setupSignalingListeners() {
    chatNotifier.onWebrtcOffer = (raw) {
      final crypto = _extractCrypto(raw);
      if (crypto == null) return;
      if (_pcReady) {
        _processOffer(crypto);
      } else {
        _pendingSignals.add({'type': 'offer', 'payload': crypto});
      }
    };

    chatNotifier.onWebrtcAnswer = (raw) {
      final crypto = _extractCrypto(raw);
      if (crypto == null) return;
      if (_pcReady) {
        _processAnswer(crypto);
      } else {
        _pendingSignals.add({'type': 'answer', 'payload': crypto});
      }
    };

    chatNotifier.onWebrtcIce = (raw) {
      final crypto = _extractCrypto(raw);
      if (crypto == null) return;
      if (_pcReady) {
        _processIce(crypto);
      } else {
        _pendingSignals.add({'type': 'ice', 'payload': crypto});
      }
    };
  }

  /// 대기 시그널 플러시
  void _flushPendingSignals() {
    for (final signal in _pendingSignals) {
      switch (signal['type']) {
        case 'offer':
          _processOffer(signal['payload'] as Map<String, dynamic>);
        case 'answer':
          _processAnswer(signal['payload'] as Map<String, dynamic>);
        case 'ice':
          _processIce(signal['payload'] as Map<String, dynamic>);
      }
    }
    _pendingSignals.clear();
  }

  /// Offer 수신 처리 (Responder)
  Future<void> _processOffer(Map<String, dynamic> payload) async {
    if (_pc == null || _sharedSecret == null) return;

    final decrypted = decryptMessage(
      EncryptedPayload.fromJson(payload),
      _sharedSecret!,
    );
    if (decrypted == null) return;

    final sdp = jsonDecode(decrypted) as Map<String, dynamic>;
    await _pc!.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String),
    );

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    final encrypted = encryptMessage(
      jsonEncode({'type': answer.type, 'sdp': answer.sdp}),
      _sharedSecret!,
    );
    _channel?.sendBroadcastMessage(
      event: 'webrtc_answer',
      payload: encrypted.toJson(),
    );
  }

  /// Answer 수신 처리 (Initiator)
  Future<void> _processAnswer(Map<String, dynamic> payload) async {
    if (_pc == null || _sharedSecret == null) return;

    final decrypted = decryptMessage(
      EncryptedPayload.fromJson(payload),
      _sharedSecret!,
    );
    if (decrypted == null) return;

    final sdp = jsonDecode(decrypted) as Map<String, dynamic>;
    await _pc!.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String),
    );
  }

  /// ICE candidate 수신 처리
  Future<void> _processIce(Map<String, dynamic> payload) async {
    if (_pc == null || _sharedSecret == null) return;

    final decrypted = decryptMessage(
      EncryptedPayload.fromJson(payload),
      _sharedSecret!,
    );
    if (decrypted == null) return;

    final ice = jsonDecode(decrypted) as Map<String, dynamic>;
    await _pc!.addCandidate(RTCIceCandidate(
      ice['candidate'] as String?,
      ice['sdpMid'] as String?,
      ice['sdpMLineIndex'] as int?,
    ));
  }

  /// DataChannel 이벤트 설정
  void _setupDataChannel(RTCDataChannel dc) {
    dc.onDataChannelState = (state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        if (mounted) {
          this.state = this.state.copyWith(status: WebRtcStatus.connected);
        }
      } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
        if (mounted) {
          this.state = this.state.copyWith(status: WebRtcStatus.idle);
        }
      }
    };

    dc.onMessage = (message) {
      if (message.isBinary) {
        _handleBinaryMessage(message.binary);
      }
    };

    // 흐름 제어: bufferedAmountLow 콜백
    dc.bufferedAmountLowThreshold = AppConstants.chunkSize * 4;
    dc.onBufferedAmountLow = (_) {
      _bufferDrain?.complete();
      _bufferDrain = null;
    };
  }

  /// 바이너리 메시지 수신 처리
  void _handleBinaryMessage(Uint8List data) {
    if (data.isEmpty) return;

    final packetType = data[0];
    switch (packetType) {
      case AppConstants.packetHeader:
        _handleHeader(data);
      case AppConstants.packetChunk:
        _handleChunk(data);
      case AppConstants.packetDone:
        _handleDone(data);
      case AppConstants.packetCancel:
        _handleCancel(data);
    }
  }

  /// HEADER 패킷 수신 (0x01)
  /// [1B type][JSON({ciphertext, nonce})]
  void _handleHeader(Uint8List data) {
    if (_sharedSecret == null) return;

    // 웹은 HEADER를 [0x01][UTF-8 JSON(encryptMessage result)] 로 보냄
    String? headerJson;
    try {
      headerJson = utf8.decode(data.sublist(1));
    } catch (_) {
      return;
    }

    final headerData = jsonDecode(headerJson) as Map<String, dynamic>;

    // 암호화된 헤더 복호화
    if (!headerData.containsKey('ciphertext') ||
        !headerData.containsKey('nonce')) {
      return;
    }

    final decryptedHeader = decryptMessage(
      EncryptedPayload.fromJson(headerData),
      _sharedSecret!,
    );
    if (decryptedHeader == null) return;

    final header = FileTransferHeader.fromJson(
      jsonDecode(decryptedHeader) as Map<String, dynamic>,
    );
    _incomingTransfers[header.transferId] = _IncomingTransfer(header);

    // 수신 시작 메시지
    final type = header.mimeType.startsWith('video')
        ? MessageType.video
        : MessageType.image;
    chatNotifier.addMediaMessage(DecryptedMessage(
      id: header.transferId,
      senderId: 'peer',
      senderName: chatNotifier.state.peerUsername ?? 'PEER',
      content: header.fileName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isMine: false,
      type: type,
      mediaMetadata: MediaMetadata(
        fileName: header.fileName,
        mimeType: header.mimeType,
        size: header.totalSize,
      ),
      transferProgress: 0.0,
    ));
  }

  /// CHUNK 패킷 수신 (0x02)
  void _handleChunk(Uint8List data) {
    if (_sharedSecret == null) return;

    // [1B type][36B transferId][4B index][24B nonce][ciphertext]
    const offset = 1;
    final transferIdBytes =
        data.sublist(offset, offset + AppConstants.transferIdSize);
    final transferId =
        utf8.decode(transferIdBytes).replaceAll('\x00', '');

    final indexBytes = data.sublist(
        offset + AppConstants.transferIdSize,
        offset + AppConstants.transferIdSize + 4);
    final chunkIndex = ByteData.sublistView(Uint8List.fromList(indexBytes))
        .getUint32(0, Endian.big);

    final nonceStart = offset + AppConstants.transferIdSize + 4;
    final nonce = data.sublist(nonceStart, nonceStart + 24);
    final ciphertext = data.sublist(nonceStart + 24);

    // 복호화
    final decryptedChunk = decryptFileChunk(ciphertext, nonce, _sharedSecret!);
    if (decryptedChunk == null) return;

    final transfer = _incomingTransfers[transferId];
    if (transfer == null) return;

    transfer.chunks[chunkIndex] = decryptedChunk;
    transfer.receivedCount++;

    // 진행률 업데이트
    final progress = transfer.receivedCount / transfer.header.totalChunks;
    chatNotifier.updateTransferProgress(transferId, progress);
  }

  /// DONE 패킷 수신 (0x03)
  Future<void> _handleDone(Uint8List data) async {
    // [1B type][36B transferId][checksum]
    const offset = 1;
    final transferIdBytes =
        data.sublist(offset, offset + AppConstants.transferIdSize);
    final transferId =
        utf8.decode(transferIdBytes).replaceAll('\x00', '');

    final checksumBytes = data.sublist(offset + AppConstants.transferIdSize);
    final expectedChecksum = utf8.decode(checksumBytes);

    final transfer = _incomingTransfers.remove(transferId);
    if (transfer == null) return;

    try {
      // 청크 누락 사전 검사 (디버그 로그)
      for (var i = 0; i < transfer.header.totalChunks; i++) {
        if (!transfer.chunks.containsKey(i)) {
          debugPrint('[WebRTC] Missing chunk $i/${transfer.header.totalChunks} '
              'for ${transfer.header.fileName}');
        }
      }

      final assembled =
          reassembleChunks(transfer.chunks, transfer.header.totalChunks);

      // 체크섬 검증
      if (!verifyChecksum(assembled, expectedChecksum)) {
        debugPrint('[WebRTC] Checksum mismatch for ${transfer.header.fileName}');
        _showTransferError(transferId, transfer.header.fileName);
        return;
      }

      // 동영상이면 썸네일 생성 (임시 파일 → VideoCompress → 삭제)
      final isVideo = transfer.header.mimeType.startsWith('video');
      Uint8List? thumbnailBytes;
      if (isVideo) {
        try {
          final dir = Directory.systemTemp;
          final tempFile = File(
            '${dir.path}/blip_thumb_${DateTime.now().millisecondsSinceEpoch}.mp4',
          );
          await tempFile.writeAsBytes(assembled);
          thumbnailBytes = await generateVideoThumbnail(tempFile.path);
          tempFile.delete().ignore();
        } catch (_) {
          // 썸네일 실패해도 전송 완료는 정상 처리
        }
      }

      // 미디어 메시지 완료
      chatNotifier.addMediaMessage(DecryptedMessage(
        id: transferId,
        senderId: 'peer',
        senderName: chatNotifier.state.peerUsername ?? 'PEER',
        content: transfer.header.fileName,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isMine: false,
        type: isVideo ? MessageType.video : MessageType.image,
        mediaBytes: assembled,
        mediaThumbnailBytes: thumbnailBytes,
        mediaMetadata: MediaMetadata(
          fileName: transfer.header.fileName,
          mimeType: transfer.header.mimeType,
          size: transfer.header.totalSize,
        ),
        transferProgress: 1.0,
      ));
    } catch (e) {
      debugPrint('[WebRTC] DONE error: $e');
      _showTransferError(transferId, transfer.header.fileName);
    }
  }

  /// CANCEL 패킷 수신 (0x05)
  void _handleCancel(Uint8List data) {
    const offset = 1;
    final transferIdBytes =
        data.sublist(offset, offset + AppConstants.transferIdSize);
    final transferId =
        utf8.decode(transferIdBytes).replaceAll('\x00', '');
    _incomingTransfers.remove(transferId);
  }

  /// 파일 전송 (이미지/비디오)
  /// [thumbnailBytes] — 동영상 썸네일 (로컬 표시용, 전송하지 않음)
  Future<void> sendFile(
    Uint8List fileData,
    String fileName,
    String mimeType, {
    Uint8List? thumbnailBytes,
  }) async {
    if (_dc == null ||
        _dc!.state != RTCDataChannelState.RTCDataChannelOpen ||
        _sharedSecret == null) {
      return;
    }

    final transferId = const Uuid().v4();
    final chunks = splitIntoChunks(fileData);
    final checksum = computeChecksum(fileData);

    final header = FileTransferHeader(
      transferId: transferId,
      fileName: fileName,
      mimeType: mimeType,
      totalSize: fileData.length,
      totalChunks: chunks.length,
      checksum: checksum,
    );

    // 1. 내 메시지에 전송 시작 표시
    final type = mimeType.startsWith('video') ? MessageType.video : MessageType.image;
    chatNotifier.addMediaMessage(DecryptedMessage(
      id: transferId,
      senderId: chatNotifier.state.myId,
      senderName: chatNotifier.state.myUsername,
      content: fileName,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isMine: true,
      type: type,
      mediaBytes: fileData,
      mediaThumbnailBytes: thumbnailBytes,
      mediaMetadata: MediaMetadata(
        fileName: fileName,
        mimeType: mimeType,
        size: fileData.length,
      ),
      transferProgress: 0.0,
    ));

    // 2. HEADER 패킷 전송
    final headerEncrypted = encryptMessage(
      jsonEncode(header.toJson()),
      _sharedSecret!,
    );
    final headerPayload = utf8.encode(jsonEncode(headerEncrypted.toJson()));
    final headerPacket = Uint8List(1 + headerPayload.length);
    headerPacket[0] = AppConstants.packetHeader;
    headerPacket.setRange(1, headerPacket.length, headerPayload);
    _dc!.send(RTCDataChannelMessage.fromBinary(headerPacket));

    // 3. CHUNK 패킷 전송 (흐름 제어 포함)
    for (var i = 0; i < chunks.length; i++) {
      // 흐름 제어: bufferedAmount 지원 여부에 따라 분기
      final buffered = _dc!.bufferedAmount;
      if (buffered != null && buffered > 0) {
        // bufferedAmount 지원 → web과 동일한 while 루프
        while (_dc != null &&
            _dc!.bufferedAmount != null &&
            _dc!.bufferedAmount! >
                AppConstants.chunkSize * AppConstants.windowSize) {
          _bufferDrain = Completer<void>();
          await _bufferDrain!.future.timeout(
            const Duration(seconds: 10),
            onTimeout: () {}, // 타임아웃 시 강제 진행
          );
        }
      } else {
        // bufferedAmount 미지원 (null/0) → 매 청크마다 딜레이 (SCTP 과부하 방지)
        if (i > 0) {
          await Future.delayed(Duration(milliseconds: _sendDelayMs));
        }
      }

      final encrypted = encryptFileChunk(chunks[i], _sharedSecret!);

      // [1B type][36B transferId][4B index][24B nonce][ciphertext]
      final transferIdPadded = Uint8List(AppConstants.transferIdSize);
      final transferIdBytes = utf8.encode(transferId);
      for (var j = 0; j < transferIdBytes.length && j < AppConstants.transferIdSize; j++) {
        transferIdPadded[j] = transferIdBytes[j];
      }

      final indexBytes = Uint8List(4);
      ByteData.sublistView(indexBytes).setUint32(0, i, Endian.big);

      final chunkPacket = Uint8List(
        1 + AppConstants.transferIdSize + 4 + 24 + encrypted.ciphertext.length,
      );
      var offset = 0;
      chunkPacket[offset++] = AppConstants.packetChunk;
      chunkPacket.setRange(offset, offset + AppConstants.transferIdSize, transferIdPadded);
      offset += AppConstants.transferIdSize;
      chunkPacket.setRange(offset, offset + 4, indexBytes);
      offset += 4;
      chunkPacket.setRange(offset, offset + 24, encrypted.nonce);
      offset += 24;
      chunkPacket.setRange(offset, offset + encrypted.ciphertext.length, encrypted.ciphertext);

      _dc!.send(RTCDataChannelMessage.fromBinary(chunkPacket));

      // 진행률 업데이트
      chatNotifier.updateTransferProgress(
        transferId,
        (i + 1) / chunks.length,
      );
    }

    // 4. DONE 패킷 전송
    final checksumBytes = utf8.encode(checksum);
    final transferIdPadded = Uint8List(AppConstants.transferIdSize);
    final transferIdBytes = utf8.encode(transferId);
    for (var j = 0; j < transferIdBytes.length && j < AppConstants.transferIdSize; j++) {
      transferIdPadded[j] = transferIdBytes[j];
    }

    final donePacket = Uint8List(1 + AppConstants.transferIdSize + checksumBytes.length);
    donePacket[0] = AppConstants.packetDone;
    donePacket.setRange(1, 1 + AppConstants.transferIdSize, transferIdPadded);
    donePacket.setRange(
      1 + AppConstants.transferIdSize,
      donePacket.length,
      checksumBytes,
    );
    _dc!.send(RTCDataChannelMessage.fromBinary(donePacket));
  }

  /// 전송 실패 시 에러 메시지로 교체 (HEADER placeholder → 에러 표시)
  void _showTransferError(String transferId, String fileName) {
    chatNotifier.addMediaMessage(DecryptedMessage(
      id: transferId,
      senderId: 'system',
      senderName: 'SYSTEM',
      content: '⚠ $fileName transfer failed',
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isMine: false,
    ));
  }

  /// WebRTC 연결 종료
  void cleanup() {
    // 시그널링 콜백 해제
    chatNotifier.onWebrtcOffer = null;
    chatNotifier.onWebrtcAnswer = null;
    chatNotifier.onWebrtcIce = null;

    _dc?.close();
    _dc = null;
    _pc?.close();
    _pc = null;
    _pcReady = false;
    _pendingSignals.clear();
    _incomingTransfers.clear();
    _bufferDrain?.complete();
    _bufferDrain = null;
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}

/// WebRtcNotifier Provider
/// ChatNotifier에 의존 (channel + sharedSecret)
/// peerConnected를 select 감시 → true가 되면 provider 재생성 →
/// 이 시점에 sharedSecret이 있으므로 _init()이 정상 작동
/// keepAlive: ImagePicker 등 임시 background 전환 시 dispose 방지
final webRtcNotifierProvider = StateNotifierProvider.autoDispose
    .family<WebRtcNotifier, WebRtcState, ({String roomId, String password})>(
  (ref, params) {
    final link = ref.keepAlive();
    // peerConnected 변경 시에만 재생성 (메시지 수신으로는 재생성 안 함)
    ref.watch(chatNotifierProvider(params).select((s) => s.peerConnected));
    final chatNotifier =
        ref.read(chatNotifierProvider(params).notifier);
    ref.onDispose(() => link.close());
    return WebRtcNotifier(chatNotifier: chatNotifier);
  },
);
