import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/board_post.dart';
import 'video_player_screen.dart';

/// img:N 스킴 매칭 (web: MarkdownContent.tsx 동일)
final _imgSchemeRe = RegExp(r'^img:(\d+)$');

/// 게시글 상세보기
/// web: PostDetail.tsx 동일 UX
class PostDetail extends StatefulWidget {
  final DecryptedPost post;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final Future<String?> Function(String postId)? onDelete;
  final Future<String?> Function(String postId)? onAdminDelete;
  final VoidCallback? onReport;

  /// 미디어 복호화 트리거 (lazy decryption)
  final Future<void> Function(String postId)? onDecryptImages;

  const PostDetail({
    super.key,
    required this.post,
    required this.onBack,
    this.onEdit,
    this.onDelete,
    this.onAdminDelete,
    this.onReport,
    this.onDecryptImages,
  });

  @override
  State<PostDetail> createState() => _PostDetailState();
}

class _PostDetailState extends State<PostDetail> {
  bool _decrypting = false;

  @override
  void initState() {
    super.initState();
    _triggerDecryptIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PostDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // post가 교체되었고 이미지가 비어있으면 재복호화 트리거
    if (oldWidget.post.id != widget.post.id ||
        (oldWidget.post.images.isNotEmpty && widget.post.images.isEmpty)) {
      _triggerDecryptIfNeeded();
    }
  }

  void _triggerDecryptIfNeeded() {
    // 암호화된 이미지가 있고 복호화된 게 없으면 자동 복호화
    if (widget.post.encryptedImages.isNotEmpty &&
        widget.post.images.isEmpty &&
        widget.onDecryptImages != null) {
      _decryptImages();
    }
  }

  Future<void> _decryptImages() async {
    setState(() => _decrypting = true);
    await widget.onDecryptImages?.call(widget.post.id);
    if (mounted) {
      setState(() => _decrypting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    if (widget.post.isBlinded) {
      return _BlindedView(l10n: l10n, onBack: widget.onBack);
    }

    return Column(
      children: [
        // 헤더
        _DetailHeader(
          l10n: l10n,
          post: widget.post,
          isDark: isDark,
          signalGreen: signalGreen,
          onBack: widget.onBack,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete != null
              ? () => _confirmDelete(context, l10n, isAdmin: false)
              : null,
          onAdminDelete: widget.onAdminDelete != null
              ? () => _confirmDelete(context, l10n, isAdmin: true)
              : null,
          onReport: widget.onReport,
        ),

        // 본문
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 작성자 + 시간
                Row(
                  children: [
                    Text(
                      widget.post.authorName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: widget.post.isMine
                            ? signalGreen
                            : (isDark
                                ? AppColors.ghostGreyDark
                                : AppColors.ghostGreyLight),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDateTime(widget.post.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.ghostGreyDark
                            : AppColors.ghostGreyLight,
                      ),
                    ),
                  ],
                ),

                // 제목
                if (widget.post.title.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.post.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // 본문 (마크다운 렌더링)
                _MarkdownContent(
                  content: widget.post.content,
                  images: widget.post.images,
                  isDark: isDark,
                  signalGreen: signalGreen,
                ),

                // 미디어 갤러리 (인라인으로 삽입되지 않은 이미지들)
                if (widget.post.encryptedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  if (_decrypting)
                    _DecryptingIndicator(signalGreen: signalGreen)
                  else if (widget.post.images.isNotEmpty)
                    _MediaGallery(images: widget.post.images),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isAdmin,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAdmin ? l10n.boardPostAdminDelete : l10n.boardPostDelete,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(l10n.boardPostDeleteWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final handler = isAdmin ? widget.onAdminDelete : widget.onDelete;
              await handler?.call(widget.post.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.glitchRed,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.boardPostConfirmDelete),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

/// 마크다운 본문 렌더링 (web: MarkdownContent.tsx 동일)
class _MarkdownContent extends StatelessWidget {
  final String content;
  final List<DecryptedPostImage> images;
  final bool isDark;
  final Color signalGreen;

  const _MarkdownContent({
    required this.content,
    required this.images,
    required this.isDark,
    required this.signalGreen,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 14,
          fontFamily: 'monospace',
          height: 1.6,
          color: textColor,
        ),
        h1: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        h3: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        strong: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        em: TextStyle(fontStyle: FontStyle.italic, color: textColor.withValues(alpha: 0.8)),
        code: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          color: signalGreen.withValues(alpha: 0.8),
          backgroundColor: textColor.withValues(alpha: 0.05),
        ),
        codeblockDecoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.05),
          border: Border.all(color: textColor.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(4),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: signalGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
        ),
        blockquotePadding: const EdgeInsets.only(left: 12),
        listBullet: TextStyle(fontSize: 14, color: textColor),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: textColor.withValues(alpha: 0.1)),
          ),
        ),
        a: TextStyle(
          color: signalGreen,
          decoration: TextDecoration.underline,
          decorationColor: signalGreen,
        ),
        tableBorder: TableBorder.all(color: textColor.withValues(alpha: 0.1)),
        tableHead: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        tableBody: TextStyle(color: textColor),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      sizedImageBuilder: (config) {
        // img:N 스킴 → 인라인 이미지 (외부 URL 차단)
        final match = _imgSchemeRe.firstMatch(config.uri.toString());
        if (match == null) return const SizedBox.shrink();

        final index = int.tryParse(match.group(1)!);
        if (index == null || index >= images.length) return const SizedBox.shrink();

        final image = images[index];

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: GestureDetector(
            onTap: image.isVideo
                ? () => _openVideoPlayer(context, image)
                : () => _openImageViewer(context, image),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image.isVideo
                  ? _VideoPreview(
                      thumbnailBytes: image.thumbnailBytes,
                      isDark: isDark,
                    )
                  : Image.memory(
                      image.bytes,
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
            ),
          ),
        );
      },
      onTapLink: (text, href, title) {
        // 링크 탭 처리 (보안: 외부 URL만 허용)
        if (href == null) return;
        // url_launcher 등으로 열 수 있지만 현재는 무시
      },
    );
  }

  void _openVideoPlayer(BuildContext context, DecryptedPostImage media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoBytes: media.bytes),
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
}

/// 동영상 썸네일 프리뷰 (인라인 + 갤러리 공용)
/// thumbnailBytes가 있으면 0.5초 프레임 이미지, 없으면 플레이스홀더
class _VideoPreview extends StatelessWidget {
  final Uint8List? thumbnailBytes;
  final bool isDark;

  const _VideoPreview({
    this.thumbnailBytes,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = isDark || Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 썸네일 또는 플레이스홀더
        if (thumbnailBytes != null)
          Image.memory(
            thumbnailBytes!,
            fit: BoxFit.cover,
          )
        else
          Container(
            color: dark ? Colors.grey[800] : Colors.grey[300],
            child: const Center(
              child: Icon(Icons.videocam, size: 32, color: Colors.white54),
            ),
          ),

        // 재생 버튼 오버레이
        Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

/// 복호화 로딩 인디케이터
class _DecryptingIndicator extends StatelessWidget {
  final Color signalGreen;

  const _DecryptingIndicator({required this.signalGreen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: signalGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Decrypting...',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: signalGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 미디어 갤러리 (이미지 + 동영상 통합)
class _MediaGallery extends StatelessWidget {
  final List<DecryptedPostImage> images;

  const _MediaGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: images.map((media) {
        final isVideo = media.mimeType.startsWith('video/');
        final itemWidth = (MediaQuery.of(context).size.width - 48) / 2;

        return GestureDetector(
          onTap: isVideo
              ? () => _openVideoPlayer(context, media)
              : () => _openImageViewer(context, media),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: itemWidth,
              height: itemWidth,
              child: isVideo
                  ? _VideoPreview(thumbnailBytes: media.thumbnailBytes)
                  : Image.memory(media.bytes, fit: BoxFit.cover),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _openVideoPlayer(BuildContext context, DecryptedPostImage media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(videoBytes: media.bytes),
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
}


/// 상세보기 헤더
class _DetailHeader extends StatelessWidget {
  final AppLocalizations l10n;
  final DecryptedPost post;
  final bool isDark;
  final Color signalGreen;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAdminDelete;
  final VoidCallback? onReport;

  const _DetailHeader({
    required this.l10n,
    required this.post,
    required this.isDark,
    required this.signalGreen,
    required this.onBack,
    this.onEdit,
    this.onDelete,
    this.onAdminDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20),
          ),
          Text(
            l10n.boardPostDetail,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),

          // 본인 게시글: 편집 + 삭제
          if (post.isMine) ...[
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                icon: Icon(Icons.edit_outlined, size: 20, color: signalGreen),
                tooltip: l10n.boardPostEdit,
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.glitchRed),
                tooltip: l10n.boardPostDelete,
              ),
          ],

          // 타인 게시글: 신고
          if (!post.isMine) ...[
            if (onReport != null)
              IconButton(
                onPressed: onReport,
                icon: Icon(Icons.flag_outlined,
                    size: 20,
                    color: isDark
                        ? AppColors.ghostGreyDark
                        : AppColors.ghostGreyLight),
                tooltip: l10n.boardReportTitle,
              ),
            // 관리자 삭제
            if (onAdminDelete != null)
              IconButton(
                onPressed: onAdminDelete,
                icon: const Icon(Icons.delete_sweep,
                    size: 20, color: AppColors.glitchRed),
                tooltip: l10n.boardPostAdminDelete,
              ),
          ],
        ],
      ),
    );
  }
}

/// 블라인드 처리된 게시글
class _BlindedView extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onBack;

  const _BlindedView({required this.l10n, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 20),
              ),
              Text(
                l10n.boardPostDetail,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility_off, size: 48, color: AppColors.glitchRed),
                SizedBox(height: 16),
                Text(
                  'BLINDED',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.glitchRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
