import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// HTTP API 클라이언트 (웹 서버 API Route 호출용)
class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        // 네트워크 에러 통일 처리
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: 'NETWORK_TIMEOUT',
            type: error.type,
          ));
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;

  // ─── Room API ───

  Future<Map<String, dynamic>> createRoom() async {
    final response = await _dio.post('/api/room/create');
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPassword(String roomId, String password) async {
    final response = await _dio.post('/api/room/verify', data: {
      'roomId': roomId,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getRoomStatus(String roomId) async {
    final response = await _dio.post('/api/room/status', data: {
      'roomId': roomId,
    });
    return response.data;
  }

  Future<void> updateParticipantCount(String roomId, int count) async {
    await _dio.post('/api/room/participant', data: {
      'roomId': roomId,
      'count': count,
    });
  }

  Future<void> leaveRoom(String roomId) async {
    await _dio.post('/api/room/leave', data: {
      'roomId': roomId,
    });
  }

  Future<void> destroyRoom(String roomId) async {
    await _dio.post('/api/room/destroy', data: {
      'roomId': roomId,
    });
  }

  Future<Map<String, dynamic>> fetchTurnCredentials() async {
    final response = await _dio.get('/api/turn-credentials');
    return response.data;
  }

  // ─── Board API ───

  Future<Map<String, dynamic>> createBoard({
    required String encryptedName,
    required String encryptedNameNonce,
  }) async {
    final response = await _dio.post('/api/board/create', data: {
      'encryptedName': encryptedName,
      'encryptedNameNonce': encryptedNameNonce,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updateBoardName({
    required String boardId,
    required String authKeyHash,
    required String encryptedName,
    required String encryptedNameNonce,
  }) async {
    final response = await _dio.post('/api/board/update-name', data: {
      'boardId': boardId,
      'authKeyHash': authKeyHash,
      'encryptedName': encryptedName,
      'encryptedNameNonce': encryptedNameNonce,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> joinBoard(String boardId, String password) async {
    final response = await _dio.post('/api/board/join', data: {
      'boardId': boardId,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getBoardMeta(String boardId, String authKeyHash) async {
    final response = await _dio.post('/api/board/meta', data: {
      'boardId': boardId,
      'authKeyHash': authKeyHash,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getPosts({
    required String boardId,
    required String authKeyHash,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _dio.post('/api/board/posts', data: {
      'boardId': boardId,
      'authKeyHash': authKeyHash,
      if (cursor != null) 'cursor': cursor,
      'limit': limit,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createPost({
    required String boardId,
    required String authKeyHash,
    required String authorNameEncrypted,
    required String authorNameNonce,
    required String contentEncrypted,
    required String contentNonce,
    String? titleEncrypted,
    String? titleNonce,
  }) async {
    final response = await _dio.post('/api/board/post/create', data: {
      'boardId': boardId,
      'authKeyHash': authKeyHash,
      'authorNameEncrypted': authorNameEncrypted,
      'authorNameNonce': authorNameNonce,
      'contentEncrypted': contentEncrypted,
      'contentNonce': contentNonce,
      if (titleEncrypted != null) 'titleEncrypted': titleEncrypted,
      if (titleNonce != null) 'titleNonce': titleNonce,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> updatePost({
    required String boardId,
    required String postId,
    required String authKeyHash,
    required String authorNameEncrypted,
    required String authorNameNonce,
    required String contentEncrypted,
    required String contentNonce,
    String? titleEncrypted,
    String? titleNonce,
  }) async {
    final response = await _dio.post('/api/board/post/update', data: {
      'boardId': boardId,
      'postId': postId,
      'authKeyHash': authKeyHash,
      'authorNameEncrypted': authorNameEncrypted,
      'authorNameNonce': authorNameNonce,
      'contentEncrypted': contentEncrypted,
      'contentNonce': contentNonce,
      if (titleEncrypted != null) 'titleEncrypted': titleEncrypted,
      if (titleNonce != null) 'titleNonce': titleNonce,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> deletePost({
    required String boardId,
    required String postId,
    required String authKeyHash,
  }) async {
    final response = await _dio.post('/api/board/post/delete', data: {
      'boardId': boardId,
      'postId': postId,
      'authKeyHash': authKeyHash,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> reportPost({
    required String boardId,
    required String postId,
    required String authKeyHash,
    required String reason,
  }) async {
    final response = await _dio.post('/api/board/post/report', data: {
      'boardId': boardId,
      'postId': postId,
      'authKeyHash': authKeyHash,
      'reason': reason,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> adminDeletePost({
    required String boardId,
    required String postId,
    required String adminToken,
  }) async {
    final response = await _dio.post('/api/board/admin/delete', data: {
      'boardId': boardId,
      'postId': postId,
      'adminToken': adminToken,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> destroyBoard({
    required String boardId,
    required String adminToken,
  }) async {
    final response = await _dio.post('/api/board/admin/destroy', data: {
      'boardId': boardId,
      'adminToken': adminToken,
    });
    return response.data;
  }

  // ─── Board Media API ───

  /// 게시판 미디어 업로드 (E2EE 암호화 바이너리 → FormData)
  Future<Map<String, dynamic>> uploadBoardMedia({
    required Uint8List encryptedFile,
    required String boardId,
    required String postId,
    required String authKeyHash,
    required String nonce,
    required String mimeType,
    int? width,
    int? height,
    required int displayOrder,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(encryptedFile, filename: 'media.enc'),
      'boardId': boardId,
      'postId': postId,
      'authKeyHash': authKeyHash,
      'nonce': nonce,
      'mimeType': mimeType,
      if (width != null) 'width': width.toString(),
      if (height != null) 'height': height.toString(),
      'displayOrder': displayOrder.toString(),
    });

    final response = await _dio.post(
      '/api/board/upload-image',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    return response.data;
  }

  /// 게시판 미디어 다운로드 (암호화 바이너리 + nonce 반환)
  Future<({Uint8List encryptedBytes, String nonce})?> getBoardMedia({
    required String imageId,
    required String authKeyHash,
  }) async {
    try {
      final response = await _dio.get(
        '/api/board/image',
        queryParameters: {
          'imageId': imageId,
          'authKeyHash': authKeyHash,
        },
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final nonce = response.headers.value('X-Encrypted-Nonce');
      if (nonce == null) return null;

      return (
        encryptedBytes: Uint8List.fromList(response.data as List<int>),
        nonce: nonce,
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Batch Status API ───

  /// 여러 Room의 상태를 한 번에 확인
  Future<Map<String, String>> batchRoomStatus(List<String> roomIds) async {
    if (roomIds.isEmpty) return {};
    final response = await _dio.post('/api/room/batch-status', data: {
      'roomIds': roomIds,
    });
    final statuses = response.data['statuses'] as Map<String, dynamic>?;
    return statuses?.map((k, v) => MapEntry(k, v as String)) ?? {};
  }

  /// 여러 Board의 상태를 한 번에 확인
  Future<Map<String, String>> batchBoardStatus(List<String> boardIds) async {
    if (boardIds.isEmpty) return {};
    final response = await _dio.post('/api/board/batch-status', data: {
      'boardIds': boardIds,
    });
    final statuses = response.data['statuses'] as Map<String, dynamic>?;
    return statuses?.map((k, v) => MapEntry(k, v as String)) ?? {};
  }

  // ─── Push API ───

  /// FCM 토큰을 Room에 등록
  Future<void> registerPushToken({
    required String roomId,
    required String fcmToken,
    required String authKeyHash,
  }) async {
    await _dio.post('/api/push/register', data: {
      'roomId': roomId,
      'fcmToken': fcmToken,
      'authKeyHash': authKeyHash,
    });
  }

  /// 상대방에게 푸시 알림 발송
  Future<Map<String, dynamic>> sendPushNotification({
    required String roomId,
    required String authKeyHash,
    String? senderTokenHash,
  }) async {
    final response = await _dio.post('/api/push/send', data: {
      'roomId': roomId,
      'authKeyHash': authKeyHash,
      if (senderTokenHash != null) 'senderTokenHash': senderTokenHash,
    });
    return response.data;
  }
}
