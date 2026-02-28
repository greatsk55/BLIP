import 'board_post.dart';

/// 복호화된 댓글 (web: DecryptedComment)
class DecryptedComment {
  final String id;
  final String postId;
  final String authorName;
  final String content;
  final String createdAt;
  final bool isBlinded;
  final bool isMine;
  final List<DecryptedPostImage> images;
  final List<EncryptedPostImageMeta> encryptedImages;

  const DecryptedComment({
    required this.id,
    required this.postId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.isBlinded = false,
    this.isMine = false,
    this.images = const [],
    this.encryptedImages = const [],
  });

  DecryptedComment copyWith({
    List<DecryptedPostImage>? images,
  }) {
    return DecryptedComment(
      id: id,
      postId: postId,
      authorName: authorName,
      content: content,
      createdAt: createdAt,
      isBlinded: isBlinded,
      isMine: isMine,
      images: images ?? this.images,
      encryptedImages: encryptedImages,
    );
  }
}
