import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/board_comment.dart';
import '../../domain/models/board_post.dart';

/// 개별 댓글 카드
/// web: CommentCard.tsx 동일 UX
class CommentCard extends StatefulWidget {
  final DecryptedComment comment;
  final VoidCallback onReport;
  final Future<String?> Function() onDelete;
  final Future<String?> Function()? onAdminDelete;
  final VoidCallback? onDecryptImages;

  const CommentCard({
    super.key,
    required this.comment,
    required this.onReport,
    required this.onDelete,
    this.onAdminDelete,
    this.onDecryptImages,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _deleting = false;
  bool _decryptTriggered = false;

  @override
  void initState() {
    super.initState();
    _triggerDecryptIfNeeded();
  }

  void _triggerDecryptIfNeeded() {
    if (_decryptTriggered) return;
    if (widget.comment.isBlinded) return;
    if (widget.comment.images.isNotEmpty) return;
    if (widget.comment.encryptedImages.isEmpty) return;
    if (widget.onDecryptImages == null) return;
    _decryptTriggered = true;
    widget.onDecryptImages!();
  }

  Future<void> _handleDelete({bool admin = false}) async {
    setState(() => _deleting = true);
    if (admin && widget.onAdminDelete != null) {
      await widget.onAdminDelete!();
    } else {
      await widget.onDelete();
    }
    if (mounted) setState(() => _deleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    if (widget.comment.isBlinded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
        child: Opacity(
          opacity: 0.5,
          child: Text(
            'BLINDED',
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.glitchRed,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.comment.isMine
            ? signalGreen.withValues(alpha: 0.02)
            : null,
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 작성자 + 시간 + 액션
          Row(
            children: [
              Text(
                widget.comment.authorName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: widget.comment.isMine
                      ? signalGreen
                      : (isDark
                          ? AppColors.ghostGreyDark
                          : AppColors.ghostGreyLight),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimeAgo(widget.comment.createdAt),
                style: TextStyle(
                  fontSize: 9,
                  fontFamily: 'monospace',
                  color: isDark
                      ? AppColors.ghostGreyDark
                      : AppColors.ghostGreyLight,
                ),
              ),
              const Spacer(),

              // 본인 댓글: 삭제
              if (widget.comment.isMine)
                _ActionButton(
                  icon: Icons.delete_outline,
                  color: AppColors.glitchRed,
                  onTap: _deleting ? null : () => _handleDelete(),
                ),

              // 타인 댓글: 신고 + 관리자삭제
              if (!widget.comment.isMine) ...[
                _ActionButton(
                  icon: Icons.flag_outlined,
                  color: isDark
                      ? AppColors.ghostGreyDark
                      : AppColors.ghostGreyLight,
                  onTap: widget.onReport,
                ),
                if (widget.onAdminDelete != null)
                  _ActionButton(
                    icon: Icons.delete_outline,
                    color: AppColors.glitchRed,
                    onTap: _deleting
                        ? null
                        : () => _handleDelete(admin: true),
                  ),
              ],
            ],
          ),

          const SizedBox(height: 4),

          // 본문
          Text(
            widget.comment.content,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              height: 1.5,
              color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
            ),
          ),

          // 이미지
          if (widget.comment.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.comment.images.map((img) {
                return GestureDetector(
                  onTap: () => _openImageViewer(context, img),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Image.memory(img.bytes, fit: BoxFit.cover),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // 미복호화 인디케이터
          if (widget.comment.images.isEmpty &&
              widget.comment.encryptedImages.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: isDark
                        ? AppColors.ghostGreyDark
                        : AppColors.ghostGreyLight,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Decrypting...',
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: isDark
                        ? AppColors.ghostGreyDark
                        : AppColors.ghostGreyLight,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openImageViewer(BuildContext context, DecryptedPostImage media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.memory(media.bytes),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: color.withValues(alpha: 0.6)),
      ),
    );
  }
}
