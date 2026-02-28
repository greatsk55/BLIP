import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/board_comment.dart';
import 'comment_card.dart';

/// 댓글 목록 위젯
/// web: CommentList.tsx 동일 UX
class CommentList extends StatelessWidget {
  final List<DecryptedComment> comments;
  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;
  final Future<String?> Function(String commentId) onDelete;
  final Future<String?> Function(String commentId)? onAdminDelete;
  final void Function(String commentId) onReport;
  final void Function(String commentId) onDecryptImages;

  const CommentList({
    super.key,
    required this.comments,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
    required this.onDelete,
    this.onAdminDelete,
    required this.onReport,
    required this.onDecryptImages,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 댓글 헤더
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              bottom: BorderSide(
                color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
          child: Text(
            '${l10n.boardCommentTitle} (${comments.length}${hasMore ? '+' : ''})',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark
                  ? AppColors.ghostGreyDark
                  : AppColors.ghostGreyLight,
            ),
          ),
        ),

        // 빈 상태
        if (comments.isEmpty && !loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Text(
                    l10n.boardCommentEmpty,
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: isDark
                          ? AppColors.ghostGreyDark
                          : AppColors.ghostGreyLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.boardCommentWriteFirst,
                    style: TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: (isDark
                              ? AppColors.ghostGreyDark
                              : AppColors.ghostGreyLight)
                          .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 댓글 목록
        ...comments.map((comment) => CommentCard(
              comment: comment,
              onReport: () => onReport(comment.id),
              onDelete: () => onDelete(comment.id),
              onAdminDelete: onAdminDelete != null
                  ? () => onAdminDelete!(comment.id)
                  : null,
              onDecryptImages: () => onDecryptImages(comment.id),
            )),

        // 로딩
        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),

        // 더 보기
        if (hasMore && !loading)
          GestureDetector(
            onTap: onLoadMore,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight)
                        .withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  l10n.boardCommentLoadMore,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.ghostGreyDark
                        : AppColors.ghostGreyLight,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
