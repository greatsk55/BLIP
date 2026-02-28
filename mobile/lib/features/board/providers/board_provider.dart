import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/crypto/crypto.dart';
import '../../../core/media/media_processor.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_board.dart';
import '../../../core/utils/username.dart';
import '../domain/models/board_comment.dart';
import '../domain/models/board_post.dart';

/// 게시판 상태 (web: BoardStatus)
enum BoardStatus {
  loading,
  passwordRequired,
  created,
  browsing,
  destroyed,
  error,
}

/// 게시판 상태 클래스
class BoardState {
  final BoardStatus status;
  final String? boardName;
  final String? boardSubtitle;
  final List<DecryptedPost> posts;
  final bool hasMore;
  final String myUsername;
  final bool isPasswordSaved;
  final String? adminToken;
  final String? errorCode;

  // 댓글 상태
  final Map<String, List<DecryptedComment>> comments;
  final Map<String, bool> commentsHasMore;
  final bool commentsLoading;

  const BoardState({
    this.status = BoardStatus.loading,
    this.boardName,
    this.boardSubtitle,
    this.posts = const [],
    this.hasMore = false,
    this.myUsername = '',
    this.isPasswordSaved = false,
    this.adminToken,
    this.errorCode,
    this.comments = const {},
    this.commentsHasMore = const {},
    this.commentsLoading = false,
  });

  BoardState copyWith({
    BoardStatus? status,
    String? boardName,
    String? boardSubtitle,
    bool clearSubtitle = false,
    List<DecryptedPost>? posts,
    bool? hasMore,
    String? myUsername,
    bool? isPasswordSaved,
    String? adminToken,
    bool clearAdminToken = false,
    String? errorCode,
    Map<String, List<DecryptedComment>>? comments,
    Map<String, bool>? commentsHasMore,
    bool? commentsLoading,
  }) {
    return BoardState(
      status: status ?? this.status,
      boardName: boardName ?? this.boardName,
      boardSubtitle: clearSubtitle ? null : (boardSubtitle ?? this.boardSubtitle),
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      myUsername: myUsername ?? this.myUsername,
      isPasswordSaved: isPasswordSaved ?? this.isPasswordSaved,
      adminToken: clearAdminToken ? null : (adminToken ?? this.adminToken),
      errorCode: errorCode ?? this.errorCode,
      comments: comments ?? this.comments,
      commentsHasMore: commentsHasMore ?? this.commentsHasMore,
      commentsLoading: commentsLoading ?? this.commentsLoading,
    );
  }
}

/// 저장소 키 상수
const _storagePrefix = 'blip-board-';
const _adminPrefix = 'blip-board-admin-';
const _usernamePrefix = 'blip-board-user-';
const _encryptionKeyPrefix = 'blip-board-key-';
const _eauthPrefix = 'blip-board-eauth-';

/// BoardNotifier: useBoard.ts → Riverpod StateNotifier
/// 대칭키 E2EE + flutter_secure_storage (iOS Keychain / Android KeyStore)
class BoardNotifier extends StateNotifier<BoardState> {
  final String boardId;
  final ApiClient _api;
  final FlutterSecureStorage _secureStorage;

  Uint8List? _encryptionKey;
  String? _authKeyHash;
  String? _cursor;
  bool _loading = false;
  final Map<String, String?> _commentCursors = {};

  BoardNotifier({
    required this.boardId,
    ApiClient? api,
    FlutterSecureStorage? secureStorage,
  })  : _api = api ?? ApiClient(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(const BoardState()) {
    _init();
  }

  Future<void> _init() async {
    // 사용자명 복원 또는 생성
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('$_usernamePrefix$boardId');
    final username = savedUsername ?? generateUsername();
    if (savedUsername == null) {
      await prefs.setString('$_usernamePrefix$boardId', username);
    }

    // 관리자 토큰 복원
    final savedToken =
        await _secureStorage.read(key: '$_adminPrefix$boardId');

    state = state.copyWith(
      myUsername: username,
      adminToken: savedToken,
    );

    // 3가지 인증 경로 (web useBoard.ts와 동일)

    // 1순위: 저장된 encryptionKey (초대코드로 참여한 멤버)
    final savedKeyB64 =
        await _secureStorage.read(key: '$_encryptionKeyPrefix$boardId');
    final savedEAuth =
        await _secureStorage.read(key: '$_eauthPrefix$boardId');
    if (savedKeyB64 != null && savedEAuth != null) {
      try {
        final savedKey = base64Decode(savedKeyB64);
        final error = await _authenticateWithKey(
            Uint8List.fromList(savedKey), savedEAuth);
        if (error == null) return;
      } catch (_) {
        // 키 파싱 실패 → 다음 경로로
      }
    }

    // 2순위: 저장된 비밀번호 (password로 참여한 멤버)
    final savedPassword =
        await _secureStorage.read(key: '$_storagePrefix$boardId');
    if (savedPassword != null) {
      state = state.copyWith(isPasswordSaved: true);
      final error = await authenticate(savedPassword, isSaved: true);
      if (error == null) return;
    }

    // 3순위: 비밀번호 입력으로 (초대 코드는 딥링크 핸들러에서 별도 호출)
    state = state.copyWith(status: BoardStatus.passwordRequired);
  }

  /// 비밀번호 인증
  Future<String?> authenticate(String password, {bool isSaved = false}) async {
    try {
      final derived = deriveKeysFromPassword(password, boardId);
      final keyHash = hashAuthKey(derived.authKey);

      // 서버 인증
      final meta = await _api.getBoardMeta(boardId, keyHash);

      if (meta['error'] != null) {
        if (isSaved) {
          await _secureStorage.delete(key: '$_storagePrefix$boardId');
          state = state.copyWith(isPasswordSaved: false);
        }
        state = state.copyWith(status: BoardStatus.passwordRequired);
        return meta['error'] as String;
      }

      if (meta['status'] == 'destroyed') {
        state = state.copyWith(status: BoardStatus.destroyed);
        return 'BOARD_DESTROYED';
      }

      // 인증 성공
      _encryptionKey = derived.encryptionSeed;
      _authKeyHash = keyHash;

      // 비밀번호 보안 저장 (flutter_secure_storage)
      if (!isSaved) {
        await _secureStorage.write(
          key: '$_storagePrefix$boardId',
          value: password,
        );
        state = state.copyWith(isPasswordSaved: true);
      }

      // encryptionKey + eAuth도 저장 (초대 코드 갱신 후에도 접속 유지)
      final eAuthHash = hashEncryptionKeyForAuth(derived.encryptionSeed);
      await _secureStorage.write(
        key: '$_encryptionKeyPrefix$boardId',
        value: base64Encode(derived.encryptionSeed),
      );
      await _secureStorage.write(
        key: '$_eauthPrefix$boardId',
        value: eAuthHash,
      );

      // 레거시 마이그레이션: 서버에 encryption_key_auth_hash 설정
      _api.updateEncryptionKeyAuthHash(
        boardId: boardId,
        authKeyHash: keyHash,
        encryptionKeyAuthHash: eAuthHash,
      ).ignore();

      // 메타데이터 적용 (공통 헬퍼)
      _applyMeta(meta);

      // 게시글 로드
      await _loadPosts();
      return null;
    } catch (_) {
      state = state.copyWith(status: BoardStatus.error);
      return 'AUTHENTICATION_FAILED';
    }
  }

  /// 저장된 encryptionKey로 인증
  Future<String?> _authenticateWithKey(
    Uint8List encryptionSeed,
    String eAuthHash,
  ) async {
    try {
      final meta = await _api.getBoardMeta(boardId, eAuthHash);

      if (meta['error'] != null) {
        // 저장된 키가 무효 → 삭제
        await _secureStorage.delete(key: '$_encryptionKeyPrefix$boardId');
        await _secureStorage.delete(key: '$_eauthPrefix$boardId');
        return meta['error'] as String;
      }

      if (meta['status'] == 'destroyed') {
        state = state.copyWith(status: BoardStatus.destroyed);
        return 'BOARD_DESTROYED';
      }

      _encryptionKey = encryptionSeed;
      _authKeyHash = eAuthHash;

      _applyMeta(meta);
      await _loadPosts();
      return null;
    } catch (_) {
      return 'KEY_AUTH_FAILED';
    }
  }

  /// 초대 코드로 인증 (딥링크 핸들러에서 호출)
  Future<String?> authenticateWithInviteCode(String inviteCode) async {
    try {
      // 1. 초대 코드 해시 → 서버 검증
      final codeHash = hashInviteCode(inviteCode);
      final joinResult = await _api.joinBoardViaInviteCode(
        boardId: boardId,
        inviteCodeHash: codeHash,
      );

      if (joinResult['error'] != null) return joinResult['error'] as String;

      // 2. wrapping key 유도 → unwrap
      final wrappingKey = deriveWrappingKey(inviteCode, boardId);
      final encryptionSeed = unwrapEncryptionKey(
        joinResult['wrappedEncryptionKey'] as String,
        joinResult['wrappedKeyNonce'] as String,
        wrappingKey,
      );

      if (encryptionSeed == null) return 'UNWRAP_FAILED';

      // 3. eAuth 유도 + 서버 인증
      final eAuthHash = hashEncryptionKeyForAuth(encryptionSeed);
      final meta = await _api.getBoardMeta(boardId, eAuthHash);

      if (meta['error'] != null) return meta['error'] as String;
      if (meta['status'] == 'destroyed') {
        state = state.copyWith(status: BoardStatus.destroyed);
        return 'BOARD_DESTROYED';
      }

      // 4. 키 저장
      _encryptionKey = encryptionSeed;
      _authKeyHash = eAuthHash;

      await _secureStorage.write(
        key: '$_encryptionKeyPrefix$boardId',
        value: base64Encode(encryptionSeed),
      );
      await _secureStorage.write(
        key: '$_eauthPrefix$boardId',
        value: eAuthHash,
      );

      _applyMeta(meta);
      await _loadPosts();
      return null;
    } catch (_) {
      return 'INVITE_CODE_FAILED';
    }
  }

  /// 초대 코드 갱신 (관리자)
  Future<({String? inviteCode, String? error})> rotateInviteCode() async {
    if (state.adminToken == null || _encryptionKey == null) {
      return (inviteCode: null, error: 'NOT_ADMIN');
    }

    try {
      final newCode = generateInviteCode();
      final newCodeHash = hashInviteCode(newCode);
      final newWrappingKey = deriveWrappingKey(newCode, boardId);
      final wrapped = wrapEncryptionKey(_encryptionKey!, newWrappingKey);

      final result = await _api.rotateInviteCode(
        boardId: boardId,
        adminToken: state.adminToken!,
        newInviteCodeHash: newCodeHash,
        newWrappedKey: wrapped.ciphertext,
        newWrappedNonce: wrapped.nonce,
      );

      if (result['error'] != null) {
        return (inviteCode: null, error: result['error'] as String);
      }

      return (inviteCode: newCode, error: null);
    } catch (_) {
      return (inviteCode: null, error: 'ROTATE_FAILED');
    }
  }

  /// 메타데이터 적용 (이름/부제목 복호화 + 상태 + 로컬 캐시)
  void _applyMeta(Map<String, dynamic> meta) {
    final name = decryptSymmetric(
      EncryptedPayload(
        ciphertext: meta['encryptedName'] as String,
        nonce: meta['encryptedNameNonce'] as String,
      ),
      _encryptionKey!,
    );

    String? subtitle;
    final encSubtitle = meta['encryptedSubtitle'] as String?;
    final encSubtitleNonce = meta['encryptedSubtitleNonce'] as String?;
    if (encSubtitle != null && encSubtitleNonce != null) {
      subtitle = decryptSymmetric(
        EncryptedPayload(ciphertext: encSubtitle, nonce: encSubtitleNonce),
        _encryptionKey!,
      );
    }

    state = state.copyWith(
      status: BoardStatus.browsing,
      boardName: name,
      boardSubtitle: subtitle,
      clearSubtitle: subtitle == null,
    );

    // 커뮤니티 리스트에 저장
    final now = DateTime.now().millisecondsSinceEpoch;
    LocalStorageService().saveBoard(SavedBoard(
      boardId: boardId,
      boardName: name ?? '',
      boardSubtitle: subtitle ?? '',
      joinedAt: now,
      lastAccessedAt: now,
    ));
  }

  /// 게시글 로드
  Future<void> _loadPosts({bool refresh = false}) async {
    if (_loading || _authKeyHash == null || _encryptionKey == null) return;
    _loading = true;

    try {
      final result = await _api.getPosts(
        boardId: boardId,
        authKeyHash: _authKeyHash!,
        cursor: refresh ? null : _cursor,
      );

      if (result['error'] != null) return;

      final rawPosts = (result['posts'] as List?) ?? [];
      final decryptedPosts = rawPosts.map((raw) {
        final post = raw as Map<String, dynamic>;
        return _decryptPost(post);
      }).toList();

      // 서버는 hasMore(boolean) 반환, 커서는 마지막 게시글 ID 사용 (web과 동일)
      final hasMore = result['hasMore'] as bool? ?? false;
      if (rawPosts.isNotEmpty) {
        final lastPost = rawPosts.last as Map<String, dynamic>;
        _cursor = lastPost['id'] as String?;
      }

      if (refresh) {
        // 이미 복호화된 이미지 바이트 보존 (refresh 시 유실 방지)
        final oldImageMap = <String, List<DecryptedPostImage>>{};
        for (final old in state.posts) {
          if (old.images.isNotEmpty) {
            oldImageMap[old.id] = old.images;
          }
        }
        final mergedPosts = decryptedPosts.map((post) {
          final cached = oldImageMap[post.id];
          if (cached != null && post.images.isEmpty) {
            return post.copyWith(images: cached);
          }
          return post;
        }).toList();

        state = state.copyWith(
          posts: mergedPosts,
          hasMore: hasMore,
        );
      } else {
        state = state.copyWith(
          posts: [...state.posts, ...decryptedPosts],
          hasMore: hasMore,
        );
      }
    } finally {
      _loading = false;
    }
  }

  /// 서버 응답 → 복호화된 게시글
  /// 서버(actions.ts)는 camelCase로 반환: authorNameEncrypted, contentEncrypted 등
  DecryptedPost _decryptPost(Map<String, dynamic> post) {
    String? authorName;
    final authorCipher = post['authorNameEncrypted'] as String?;
    final authorNonce = post['authorNameNonce'] as String?;
    if (authorCipher != null && authorNonce != null) {
      authorName = decryptSymmetric(
        EncryptedPayload(ciphertext: authorCipher, nonce: authorNonce),
        _encryptionKey!,
      );
    }

    String? content;
    final contentCipher = post['contentEncrypted'] as String?;
    final contentNonce = post['contentNonce'] as String?;
    if (contentCipher != null && contentNonce != null) {
      content = decryptSymmetric(
        EncryptedPayload(ciphertext: contentCipher, nonce: contentNonce),
        _encryptionKey!,
      );
    }

    String title = '';
    final titleCipher = post['titleEncrypted'] as String?;
    final titleNonce = post['titleNonce'] as String?;
    if (titleCipher != null && titleNonce != null) {
      title = decryptSymmetric(
            EncryptedPayload(ciphertext: titleCipher, nonce: titleNonce),
            _encryptionKey!,
          ) ??
          '';
    }

    // 이미지 메타데이터 파싱 (lazy decryption)
    final images = ((post['images'] as List?) ?? [])
        .map((img) => EncryptedPostImageMeta.fromJson(
            img as Map<String, dynamic>))
        .toList();

    return DecryptedPost(
      id: post['id'] as String,
      authorName: authorName ?? 'Unknown',
      title: title,
      content: content ?? '',
      createdAt: post['createdAt'] as String? ?? '',
      isBlinded: post['isBlinded'] as bool? ?? false,
      isMine: authorName == state.myUsername,
      encryptedImages: images,
      commentCount: post['commentCount'] as int? ?? 0,
    );
  }

  /// 게시글 새로고침
  Future<void> refreshPosts() async {
    _cursor = null;
    await _loadPosts(refresh: true);
  }

  /// 추가 로드
  Future<void> loadMore() async {
    if (!state.hasMore) return;
    await _loadPosts();
  }

  /// 게시글 작성 (미디어 첨부 지원)
  Future<String?> submitPost(
    String title,
    String content, {
    List<MediaAttachment>? media,
  }) async {
    if (_encryptionKey == null || _authKeyHash == null) return 'NOT_AUTHENTICATED';

    final authorEncrypted =
        encryptSymmetric(state.myUsername, _encryptionKey!);
    final contentEncrypted = encryptSymmetric(content, _encryptionKey!);
    final titleEncrypted =
        title.isNotEmpty ? encryptSymmetric(title, _encryptionKey!) : null;

    final result = await _api.createPost(
      boardId: boardId,
      authKeyHash: _authKeyHash!,
      authorNameEncrypted: authorEncrypted.ciphertext,
      authorNameNonce: authorEncrypted.nonce,
      contentEncrypted: contentEncrypted.ciphertext,
      contentNonce: contentEncrypted.nonce,
      titleEncrypted: titleEncrypted?.ciphertext,
      titleNonce: titleEncrypted?.nonce,
    );

    if (result['error'] != null) return result['error'] as String;

    // 미디어 업로드 (게시글 생성 후 postId로)
    final postId = result['postId'] as String?;
    if (postId != null && media != null && media.isNotEmpty) {
      final uploadError = await _uploadMediaFiles(postId, media);
      if (uploadError != null) return uploadError;
    }

    await refreshPosts();
    return null;
  }

  /// 미디어 파일 순차 암호화 + 업로드 (웹 패턴 동일)
  Future<String?> _uploadMediaFiles(
    String postId,
    List<MediaAttachment> media,
  ) async {
    for (var i = 0; i < media.length; i++) {
      final attachment = media[i];
      final encrypted = encryptBinary(attachment.compressedBytes, _encryptionKey!);
      final encryptedBytes = base64Decode(encrypted.ciphertext);

      final result = await _api.uploadBoardMedia(
        encryptedFile: Uint8List.fromList(encryptedBytes),
        boardId: boardId,
        postId: postId,
        authKeyHash: _authKeyHash!,
        nonce: encrypted.nonce,
        mimeType: attachment.mimeType,
        width: attachment.width,
        height: attachment.height,
        displayOrder: i,
      );

      if (result['error'] != null) return result['error'] as String;
    }
    return null;
  }

  /// 게시글 수정
  Future<String?> editPost(String postId, String title, String content) async {
    if (_encryptionKey == null || _authKeyHash == null) return 'NOT_AUTHENTICATED';

    final authorEncrypted =
        encryptSymmetric(state.myUsername, _encryptionKey!);
    final contentEncrypted = encryptSymmetric(content, _encryptionKey!);
    final titleEncrypted =
        title.isNotEmpty ? encryptSymmetric(title, _encryptionKey!) : null;

    final result = await _api.updatePost(
      boardId: boardId,
      postId: postId,
      authKeyHash: _authKeyHash!,
      authorNameEncrypted: authorEncrypted.ciphertext,
      authorNameNonce: authorEncrypted.nonce,
      contentEncrypted: contentEncrypted.ciphertext,
      contentNonce: contentEncrypted.nonce,
      titleEncrypted: titleEncrypted?.ciphertext,
      titleNonce: titleEncrypted?.nonce,
    );

    if (result['error'] != null) return result['error'] as String;

    await refreshPosts();
    return null;
  }

  /// 게시글 삭제
  Future<String?> deletePost(String postId, {String? adminToken}) async {
    if (_authKeyHash == null) return 'NOT_AUTHENTICATED';

    final Map<String, dynamic> result;
    if (adminToken != null) {
      result = await _api.adminDeletePost(
        boardId: boardId,
        postId: postId,
        adminToken: adminToken,
      );
    } else {
      result = await _api.deletePost(
        boardId: boardId,
        postId: postId,
        authKeyHash: _authKeyHash!,
      );
    }

    if (result['error'] != null) return result['error'] as String;

    state = state.copyWith(
      posts: state.posts.where((p) => p.id != postId).toList(),
    );
    return null;
  }

  /// 게시글 신고
  Future<String?> submitReport(String postId, ReportReason reason) async {
    if (_authKeyHash == null) return 'NOT_AUTHENTICATED';

    final result = await _api.reportPost(
      boardId: boardId,
      postId: postId,
      authKeyHash: _authKeyHash!,
      reason: reason.name,
    );

    if (result['error'] != null) return result['error'] as String;
    return null;
  }

  /// 게시글 미디어 복호화 (lazy decryption)
  Future<void> decryptPostImages(String postId) async {
    if (_encryptionKey == null || _authKeyHash == null) return;

    final postIndex = state.posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = state.posts[postIndex];
    // 이미 복호화된 경우 또는 암호화된 이미지가 없으면 스킵
    if (post.images.isNotEmpty || post.encryptedImages.isEmpty) return;

    final decryptedImages = <DecryptedPostImage>[];
    final tempDir = await getTemporaryDirectory();

    for (final meta in post.encryptedImages) {
      final mediaResult = await _api.getBoardMedia(
        imageId: meta.id,
        authKeyHash: _authKeyHash!,
      );
      if (mediaResult == null) continue;

      final decrypted = decryptBinaryRaw(
        mediaResult.encryptedBytes,
        Uint8List.fromList(base64Decode(mediaResult.nonce)),
        _encryptionKey!,
      );
      if (decrypted == null) continue;

      // 동영상이면 0.5초 프레임 썸네일 추출
      Uint8List? thumbnailBytes;
      if (meta.mimeType.startsWith('video/')) {
        final tempFile = File(
          '${tempDir.path}/blip_board_thumb_${meta.id}.mp4',
        );
        try {
          await tempFile.writeAsBytes(decrypted);
          thumbnailBytes = await generateVideoThumbnail(tempFile.path);
        } catch (_) {
          // 썸네일 실패해도 동영상 자체는 표시
        } finally {
          tempFile.delete().ignore();
        }
      }

      decryptedImages.add(DecryptedPostImage(
        id: meta.id,
        bytes: decrypted,
        mimeType: meta.mimeType,
        width: meta.width,
        height: meta.height,
        thumbnailBytes: thumbnailBytes,
      ));
    }

    // 불변 리스트 업데이트
    final updatedPosts = List<DecryptedPost>.from(state.posts);
    updatedPosts[postIndex] = post.copyWith(images: decryptedImages);
    state = state.copyWith(posts: updatedPosts);
  }

  /// 관리자 토큰 저장
  Future<void> saveAdminToken(String token) async {
    await _secureStorage.write(key: '$_adminPrefix$boardId', value: token);
    state = state.copyWith(adminToken: token);
  }

  /// 관리자 토큰 삭제
  Future<void> forgetAdminToken() async {
    await _secureStorage.delete(key: '$_adminPrefix$boardId');
    state = state.copyWith(clearAdminToken: true);
  }

  /// 저장된 비밀번호 삭제
  Future<void> forgetSavedPassword() async {
    await _secureStorage.delete(key: '$_storagePrefix$boardId');
    await _secureStorage.delete(key: '$_encryptionKeyPrefix$boardId');
    await _secureStorage.delete(key: '$_eauthPrefix$boardId');
    state = state.copyWith(isPasswordSaved: false);
  }

  /// 부제목 업데이트 (관리자)
  Future<String?> updateSubtitle(String subtitle) async {
    if (state.adminToken == null || _encryptionKey == null) {
      return 'NOT_ADMIN';
    }

    final trimmed = subtitle.trim();

    if (trimmed.isNotEmpty) {
      final enc = encryptSymmetric(trimmed, _encryptionKey!);
      final result = await _api.updateBoardSubtitle(
        boardId: boardId,
        adminToken: state.adminToken!,
        encryptedSubtitle: enc.ciphertext,
        encryptedSubtitleNonce: enc.nonce,
      );
      if (result['error'] != null) return result['error'] as String;
      state = state.copyWith(boardSubtitle: trimmed);
      // 로컬 캐시 업데이트
      final storage = LocalStorageService();
      final boards = await storage.getSavedBoards();
      final idx = boards.indexWhere((b) => b.boardId == boardId);
      if (idx >= 0) {
        await storage.saveBoard(boards[idx].copyWith(boardSubtitle: trimmed));
      }
    } else {
      // 빈 문자열 → 부제목 삭제
      final result = await _api.updateBoardSubtitle(
        boardId: boardId,
        adminToken: state.adminToken!,
      );
      if (result['error'] != null) return result['error'] as String;
      state = state.copyWith(clearSubtitle: true);
      final storage = LocalStorageService();
      final boards = await storage.getSavedBoards();
      final idx = boards.indexWhere((b) => b.boardId == boardId);
      if (idx >= 0) {
        await storage.saveBoard(boards[idx].copyWith(boardSubtitle: ''));
      }
    }

    return null;
  }

  // ─── 댓글 기능 ───

  /// 댓글 로드
  Future<void> loadComments(String postId) async {
    if (_authKeyHash == null || _encryptionKey == null) return;

    state = state.copyWith(commentsLoading: true);
    _commentCursors[postId] = null;

    try {
      final result = await _api.getComments(
        boardId: boardId,
        postId: postId,
        authKeyHash: _authKeyHash!,
      );

      if (result['error'] != null) return;

      final rawComments = (result['comments'] as List?) ?? [];
      final decoded = rawComments.map((raw) {
        return _decryptComment(raw as Map<String, dynamic>, postId);
      }).toList();

      final hasMore = result['hasMore'] as bool? ?? false;
      if (rawComments.isNotEmpty) {
        final last = rawComments.last as Map<String, dynamic>;
        _commentCursors[postId] = last['id'] as String?;
      }

      state = state.copyWith(
        comments: {...state.comments, postId: decoded},
        commentsHasMore: {...state.commentsHasMore, postId: hasMore},
        commentsLoading: false,
      );
    } catch (_) {
      state = state.copyWith(commentsLoading: false);
    }
  }

  /// 댓글 추가 로드
  Future<void> loadMoreComments(String postId) async {
    if (_authKeyHash == null || _encryptionKey == null) return;
    if (!(state.commentsHasMore[postId] ?? false)) return;

    state = state.copyWith(commentsLoading: true);

    try {
      final result = await _api.getComments(
        boardId: boardId,
        postId: postId,
        authKeyHash: _authKeyHash!,
        cursor: _commentCursors[postId],
      );

      if (result['error'] != null) return;

      final rawComments = (result['comments'] as List?) ?? [];
      final decoded = rawComments.map((raw) {
        return _decryptComment(raw as Map<String, dynamic>, postId);
      }).toList();

      final hasMore = result['hasMore'] as bool? ?? false;
      if (rawComments.isNotEmpty) {
        final last = rawComments.last as Map<String, dynamic>;
        _commentCursors[postId] = last['id'] as String?;
      }

      final existing = state.comments[postId] ?? [];
      state = state.copyWith(
        comments: {...state.comments, postId: [...existing, ...decoded]},
        commentsHasMore: {...state.commentsHasMore, postId: hasMore},
        commentsLoading: false,
      );
    } catch (_) {
      state = state.copyWith(commentsLoading: false);
    }
  }

  /// 댓글 복호화
  DecryptedComment _decryptComment(Map<String, dynamic> raw, String postId) {
    String? authorName;
    final authorCipher = raw['authorNameEncrypted'] as String?;
    final authorNonce = raw['authorNameNonce'] as String?;
    if (authorCipher != null && authorNonce != null) {
      authorName = decryptSymmetric(
        EncryptedPayload(ciphertext: authorCipher, nonce: authorNonce),
        _encryptionKey!,
      );
    }

    String? content;
    final contentCipher = raw['contentEncrypted'] as String?;
    final contentNonce = raw['contentNonce'] as String?;
    if (contentCipher != null && contentNonce != null) {
      content = decryptSymmetric(
        EncryptedPayload(ciphertext: contentCipher, nonce: contentNonce),
        _encryptionKey!,
      );
    }

    final images = ((raw['images'] as List?) ?? [])
        .map((img) =>
            EncryptedPostImageMeta.fromJson(img as Map<String, dynamic>))
        .toList();

    return DecryptedComment(
      id: raw['id'] as String,
      postId: postId,
      authorName: authorName ?? 'Unknown',
      content: content ?? '',
      createdAt: raw['createdAt'] as String? ?? '',
      isBlinded: raw['isBlinded'] as bool? ?? false,
      isMine: authorName == state.myUsername,
      encryptedImages: images,
    );
  }

  /// 댓글 작성
  Future<String?> submitComment(
    String postId,
    String content, {
    List<MediaAttachment>? media,
  }) async {
    if (_encryptionKey == null || _authKeyHash == null) return 'NOT_AUTHENTICATED';

    final authorEncrypted =
        encryptSymmetric(state.myUsername, _encryptionKey!);
    final contentEncrypted = encryptSymmetric(content, _encryptionKey!);

    final result = await _api.createComment(
      boardId: boardId,
      postId: postId,
      authKeyHash: _authKeyHash!,
      authorNameEncrypted: authorEncrypted.ciphertext,
      authorNameNonce: authorEncrypted.nonce,
      contentEncrypted: contentEncrypted.ciphertext,
      contentNonce: contentEncrypted.nonce,
    );

    if (result['error'] != null) return result['error'] as String;

    // 미디어 업로드
    final commentId = result['commentId'] as String?;
    if (commentId != null && media != null && media.isNotEmpty) {
      for (var i = 0; i < media.length; i++) {
        final attachment = media[i];
        final encrypted =
            encryptBinary(attachment.compressedBytes, _encryptionKey!);
        final encryptedBytes = base64Decode(encrypted.ciphertext);

        await _api.uploadBoardMedia(
          encryptedFile: Uint8List.fromList(encryptedBytes),
          boardId: boardId,
          commentId: commentId,
          authKeyHash: _authKeyHash!,
          nonce: encrypted.nonce,
          mimeType: attachment.mimeType,
          width: attachment.width,
          height: attachment.height,
          displayOrder: i,
        );
      }
    }

    // 게시글 댓글 수 증가 반영
    final updatedPosts = state.posts.map((p) {
      if (p.id == postId) return p.copyWith(commentCount: p.commentCount + 1);
      return p;
    }).toList();
    state = state.copyWith(posts: updatedPosts);

    // 댓글 새로고침
    await loadComments(postId);
    return null;
  }

  /// 댓글 삭제
  Future<String?> deleteComment(
    String commentId,
    String postId, {
    String? adminToken,
  }) async {
    if (_authKeyHash == null) return 'NOT_AUTHENTICATED';

    final Map<String, dynamic> result;
    if (adminToken != null) {
      result = await _api.adminDeleteComment(
        boardId: boardId,
        commentId: commentId,
        adminToken: adminToken,
      );
    } else {
      result = await _api.deleteComment(
        boardId: boardId,
        commentId: commentId,
        authKeyHash: _authKeyHash!,
      );
    }

    if (result['error'] != null) return result['error'] as String;

    // 로컬 상태 업데이트
    final existing = state.comments[postId] ?? [];
    state = state.copyWith(
      comments: {
        ...state.comments,
        postId: existing.where((c) => c.id != commentId).toList(),
      },
    );

    // 게시글 댓글 수 감소 반영
    final updatedPosts = state.posts.map((p) {
      if (p.id == postId) {
        return p.copyWith(commentCount: (p.commentCount - 1).clamp(0, 999999));
      }
      return p;
    }).toList();
    state = state.copyWith(posts: updatedPosts);

    return null;
  }

  /// 댓글 신고
  Future<String?> submitCommentReport(
    String commentId,
    ReportReason reason,
  ) async {
    if (_authKeyHash == null) return 'NOT_AUTHENTICATED';

    final result = await _api.reportComment(
      boardId: boardId,
      commentId: commentId,
      authKeyHash: _authKeyHash!,
      reason: reason.name,
    );

    if (result['error'] != null) return result['error'] as String;
    return null;
  }

  /// 댓글 이미지 복호화 (lazy decryption)
  Future<void> decryptCommentImages(String commentId, String postId) async {
    if (_encryptionKey == null || _authKeyHash == null) return;

    final commentList = state.comments[postId] ?? [];
    final idx = commentList.indexWhere((c) => c.id == commentId);
    if (idx == -1) return;

    final comment = commentList[idx];
    if (comment.images.isNotEmpty || comment.encryptedImages.isEmpty) return;

    final decryptedImages = <DecryptedPostImage>[];
    final tempDir = await getTemporaryDirectory();

    for (final meta in comment.encryptedImages) {
      final mediaResult = await _api.getBoardMedia(
        imageId: meta.id,
        authKeyHash: _authKeyHash!,
      );
      if (mediaResult == null) continue;

      final decrypted = decryptBinaryRaw(
        mediaResult.encryptedBytes,
        Uint8List.fromList(base64Decode(mediaResult.nonce)),
        _encryptionKey!,
      );
      if (decrypted == null) continue;

      Uint8List? thumbnailBytes;
      if (meta.mimeType.startsWith('video/')) {
        final tempFile = File(
          '${tempDir.path}/blip_board_thumb_${meta.id}.mp4',
        );
        try {
          await tempFile.writeAsBytes(decrypted);
          thumbnailBytes = await generateVideoThumbnail(tempFile.path);
        } catch (_) {
          // 썸네일 실패해도 동영상 자체는 표시
        } finally {
          tempFile.delete().ignore();
        }
      }

      decryptedImages.add(DecryptedPostImage(
        id: meta.id,
        bytes: decrypted,
        mimeType: meta.mimeType,
        width: meta.width,
        height: meta.height,
        thumbnailBytes: thumbnailBytes,
      ));
    }

    final updatedList = List<DecryptedComment>.from(commentList);
    updatedList[idx] = comment.copyWith(images: decryptedImages);
    state = state.copyWith(
      comments: {...state.comments, postId: updatedList},
    );
  }

  /// 커뮤니티 파쇄 (관리자)
  Future<String?> destroyBoard() async {
    if (state.adminToken == null) return 'NO_ADMIN_TOKEN';

    final result = await _api.destroyBoard(
      boardId: boardId,
      adminToken: state.adminToken!,
    );

    if (result['error'] != null) return result['error'] as String;

    state = state.copyWith(status: BoardStatus.destroyed);
    return null;
  }

  @override
  void dispose() {
    // 암호화 키 메모리 제로화
    if (_encryptionKey != null) {
      _encryptionKey!.fillRange(0, _encryptionKey!.length, 0);
      _encryptionKey = null;
    }
    _authKeyHash = null;
    super.dispose();
  }
}

/// BoardNotifier Provider (boardId 기반)
final boardNotifierProvider = StateNotifierProvider.autoDispose
    .family<BoardNotifier, BoardState, String>(
  (ref, boardId) => BoardNotifier(boardId: boardId),
);
