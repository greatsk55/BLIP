import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/board_post.dart';

/// 게시글 카드 (목록 아이템)
/// web: PostCard.tsx 동일 UX
class PostCard extends StatelessWidget {
  final DecryptedPost post;
  final VoidCallback onTap;
  final VoidCallback? onShare;

  const PostCard({super.key, required this.post, required this.onTap, this.onShare});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return GestureDetector(
      onTap: post.isBlinded ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: post.isBlinded
              ? AppColors.glitchRed.withValues(alpha: 0.02)
              : post.isMine
                  ? signalGreen.withValues(alpha: 0.02)
                  : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: post.isBlinded
                ? AppColors.glitchRed.withValues(alpha: 0.1)
                : post.isMine
                    ? signalGreen.withValues(alpha: 0.1)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Opacity(
          opacity: post.isBlinded ? 0.5 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 작성자 + 시간
              Row(
                children: [
                  Expanded(
                    child: Text(
                      post.authorName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: post.isMine
                            ? signalGreen
                            : (isDark
                                ? AppColors.ghostGreyDark
                                : AppColors.ghostGreyLight),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _formatRelativeTime(post.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppColors.ghostGreyDark
                          : AppColors.ghostGreyLight,
                    ),
                  ),
                  if (onShare != null && !post.isBlinded) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onShare,
                      child: Icon(
                        Icons.share_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.ghostGreyDark
                            : AppColors.ghostGreyLight,
                      ),
                    ),
                  ],
                ],
              ),

              // 제목
              if (post.title.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  post.isBlinded ? '■■■■' : post.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // 본문 미리보기
              const SizedBox(height: 4),
              Text(
                post.isBlinded ? '■■■■■■■■' : _stripMarkdown(post.content),
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  height: 1.4,
                  color: (isDark ? Colors.white : Colors.black87)
                      .withValues(alpha: 0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // 미디어 + 댓글 수 인디케이터
              if ((!post.isBlinded &&
                      post.encryptedImages.isNotEmpty) ||
                  post.commentCount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    // 이미지 인디케이터
                    if (post.encryptedImages.isNotEmpty &&
                        !post.isBlinded) ...[
                      Icon(
                        Icons.image_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.ghostGreyDark
                            : AppColors.ghostGreyLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.encryptedImages.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppColors.ghostGreyDark
                              : AppColors.ghostGreyLight,
                        ),
                      ),
                    ],
                    // 댓글 수 인디케이터
                    if (post.commentCount > 0) ...[
                      if (post.encryptedImages.isNotEmpty &&
                          !post.isBlinded)
                        const SizedBox(width: 10),
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 14,
                        color: isDark
                            ? AppColors.ghostGreyDark
                            : AppColors.ghostGreyLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.commentCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isDark
                              ? AppColors.ghostGreyDark
                              : AppColors.ghostGreyLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 마크다운 제거 (플레인 텍스트로 미리보기)
  String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'#{1,6}\s'), '') // 헤더
        .replaceAll(RegExp(r'\*{1,2}(.*?)\*{1,2}'), r'$1') // 볼드/이탤릭
        .replaceAll(RegExp(r'`{1,3}[^`]*`{1,3}'), '') // 코드
        .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1') // 링크
        .replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), '') // 이미지
        .replaceAll(RegExp(r'^[-*+]\s', multiLine: true), '') // 리스트
        .replaceAll(RegExp(r'^\d+\.\s', multiLine: true), '') // 숫자 리스트
        .replaceAll(RegExp(r'^>\s', multiLine: true), '') // 인용
        .trim();
  }

  /// 상대 시간 표시
  String _formatRelativeTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return '${diff.inSeconds}s';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 30) return '${diff.inDays}d';
      return '${(diff.inDays / 30).floor()}mo';
    } catch (_) {
      return '';
    }
  }
}
