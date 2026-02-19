import 'dart:typed_data';

/// 신고 사유 (web: ReportReason)
enum ReportReason { spam, abuse, illegal, other }

/// 복호화된 이미지 (클라이언트 메모리)
class DecryptedPostImage {
  final String id;
  final Uint8List bytes;
  final String mimeType;
  final int? width;
  final int? height;

  const DecryptedPostImage({
    required this.id,
    required this.bytes,
    required this.mimeType,
    this.width,
    this.height,
  });
}

/// 암호화된 이미지 메타데이터 (lazy decryption용)
class EncryptedPostImageMeta {
  final String id;
  final String encryptedNonce;
  final String mimeType;
  final int? width;
  final int? height;

  const EncryptedPostImageMeta({
    required this.id,
    required this.encryptedNonce,
    required this.mimeType,
    this.width,
    this.height,
  });

  /// 서버(actions.ts)는 camelCase 반환: encryptedNonce, mimeType
  factory EncryptedPostImageMeta.fromJson(Map<String, dynamic> json) =>
      EncryptedPostImageMeta(
        id: json['id'] as String,
        encryptedNonce: json['encryptedNonce'] as String,
        mimeType: json['mimeType'] as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
      );
}

/// 미디어 첨부 데이터 (업로드 전 압축된 상태)
class MediaAttachment {
  final Uint8List compressedBytes;
  final String mimeType;
  final int? width;
  final int? height;
  final Uint8List? thumbnailBytes; // 동영상 로컬 프리뷰

  const MediaAttachment({
    required this.compressedBytes,
    required this.mimeType,
    this.width,
    this.height,
    this.thumbnailBytes,
  });

  bool get isVideo => mimeType.startsWith('video/');
}

/// 복호화된 게시글 (web: DecryptedPost)
class DecryptedPost {
  final String id;
  final String authorName;
  final String title;
  final String content;
  final String createdAt;
  final bool isBlinded;
  final bool isMine;
  final List<DecryptedPostImage> images;
  final List<EncryptedPostImageMeta> encryptedImages;

  const DecryptedPost({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    required this.createdAt,
    this.isBlinded = false,
    this.isMine = false,
    this.images = const [],
    this.encryptedImages = const [],
  });

  DecryptedPost copyWith({
    List<DecryptedPostImage>? images,
  }) {
    return DecryptedPost(
      id: id,
      authorName: authorName,
      title: title,
      content: content,
      createdAt: createdAt,
      isBlinded: isBlinded,
      isMine: isMine,
      images: images ?? this.images,
      encryptedImages: encryptedImages,
    );
  }
}
