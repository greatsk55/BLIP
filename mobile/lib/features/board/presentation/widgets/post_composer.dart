import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/media/media_processor.dart';
import '../../../../core/services/ad_service.dart';
import '../../domain/models/board_post.dart';
import 'markdown_toolbar.dart';

/// 게시글 작성/편집 풀페이지
/// web: PostComposer.tsx 동일 UX
class PostComposer extends StatefulWidget {
  /// 새 글 작성: (title, content, {media}) -> Future (에러코드 또는 null)
  final Future<String?> Function(
    String title,
    String content, {
    List<MediaAttachment>? media,
  }) onSubmitted;

  /// 편집 모드 시 기존 데이터
  final String? editTitle;
  final String? editContent;

  const PostComposer({
    super.key,
    required this.onSubmitted,
    this.editTitle,
    this.editContent,
  });

  bool get isEditMode => editTitle != null || editContent != null;

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;
  bool _compressing = false;
  String? _error;
  final List<MediaAttachment> _media = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.editTitle ?? '');
    _contentController = TextEditingController(text: widget.editContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _contentController.text.trim().isNotEmpty && !_submitting && !_compressing;

  bool get _canAddMedia =>
      !widget.isEditMode && _media.length < AppConstants.maxMediaPerPost;

  Future<void> _pickMedia() async {
    if (!_canAddMedia) return;

    final remaining = AppConstants.maxMediaPerPost - _media.length;
    final files = await _picker.pickMultipleMedia();
    if (files.isEmpty) return;

    final selected = files.take(remaining).toList();

    setState(() {
      _compressing = true;
      _error = null;
    });

    try {
      for (final file in selected) {
        final mimeType = file.mimeType ?? _guessMimeType(file.path);
        final type = getMediaType(mimeType);

        if (type == MediaType.image) {
          final compressed = await compressImage(file);
          _media.add(MediaAttachment(
            compressedBytes: compressed.bytes,
            mimeType: 'image/jpeg',
            width: compressed.width,
            height: compressed.height,
          ));
        } else if (type == MediaType.video) {
          final thumbnail = await generateVideoThumbnail(file.path);
          final compressed = await compressVideo(file);
          _media.add(MediaAttachment(
            compressedBytes: compressed.bytes,
            mimeType: 'video/mp4',
            width: compressed.width,
            height: compressed.height,
            thumbnailBytes: thumbnail,
          ));
        }
      }
    } on VideoTooLongException {
      if (mounted) setState(() => _error = 'VIDEO_TOO_LONG');
    } on VideoTooLargeException {
      if (mounted) setState(() => _error = 'VIDEO_TOO_LARGE');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _compressing = false);
    }
  }

  String _guessMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      _ => 'application/octet-stream',
    };
  }

  void _removeMedia(int index) {
    setState(() => _media.removeAt(index));
  }

  /// 커서 위치에 인라인 이미지 마크다운 삽입 (web: insertImageInline 패턴)
  void _insertMediaInline(int index) {
    final tag = '![image](img:$index)';
    final text = _contentController.text;
    final selection = _contentController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final before = text.substring(0, start);
    final after = text.substring(end);
    final prefix = before.isNotEmpty && !before.endsWith('\n') ? '\n' : '';
    final suffix = after.isNotEmpty && !after.startsWith('\n') ? '\n' : '';

    final newText = before + prefix + tag + suffix + after;
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + prefix.length + tag.length + suffix.length,
      ),
    );
    setState(() {});
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await widget.onSubmitted(
      _titleController.text.trim(),
      content,
      media: _media.isNotEmpty ? _media : null,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
    } else {
      // 전면광고 (N번에 1번)
      await AdService.instance.maybeShowInterstitial();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    }
  }

  String _getLocalizedError(AppLocalizations l10n, String error) {
    return switch (error) {
      'VIDEO_TOO_LONG' => l10n.boardPostVideoTooLong(AppConstants.maxVideoDurationSec),
      'VIDEO_TOO_LARGE' => l10n.boardPostVideoTooLarge,
      _ => error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: Text(
          widget.isEditMode ? l10n.boardPostEditTitle : l10n.boardPostCompose,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // 제출 버튼
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _canSubmit ? _submit : null,
              child: _submitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: signalGreen,
                      ),
                    )
                  : Text(
                      widget.isEditMode
                          ? l10n.boardPostSave
                          : l10n.boardPostSubmit,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: _canSubmit
                            ? signalGreen
                            : (isDark
                                ? AppColors.ghostGreyDark
                                : AppColors.ghostGreyLight),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 에러 메시지
            if (_error != null)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.glitchRed.withValues(alpha: 0.1),
                child: Text(
                  _getLocalizedError(l10n, _error!),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.glitchRed,
                  ),
                ),
              ),

            // 제목 입력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _titleController,
                maxLength: 200,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: l10n.boardPostTitlePlaceholder,
                  hintStyle: TextStyle(
                    fontFamily: 'monospace',
                    color: (isDark
                            ? AppColors.ghostGreyDark
                            : AppColors.ghostGreyLight)
                        .withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),

            // 마크다운 편집 툴바
            MarkdownToolbar(
              controller: _contentController,
              isDark: isDark,
            ),

            // 본문 입력
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    height: 1.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.boardPostPlaceholder,
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: (isDark
                              ? AppColors.ghostGreyDark
                              : AppColors.ghostGreyLight)
                          .withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ),

            // 미디어 프리뷰 + 피커 (편집 모드에서는 숨김)
            if (!widget.isEditMode) ...[
              Divider(
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              _MediaBar(
                media: _media,
                canAdd: _canAddMedia,
                compressing: _compressing,
                isDark: isDark,
                signalGreen: signalGreen,
                onPick: _pickMedia,
                onRemove: _removeMedia,
                onInsertInline: _insertMediaInline,
                l10n: l10n,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 하단 미디어 바 (프리뷰 + 첨부 버튼)
class _MediaBar extends StatelessWidget {
  final List<MediaAttachment> media;
  final bool canAdd;
  final bool compressing;
  final bool isDark;
  final Color signalGreen;
  final VoidCallback onPick;
  final void Function(int) onRemove;
  final void Function(int) onInsertInline;
  final AppLocalizations l10n;

  const _MediaBar({
    required this.media,
    required this.canAdd,
    required this.compressing,
    required this.isDark,
    required this.signalGreen,
    required this.onPick,
    required this.onRemove,
    required this.onInsertInline,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 미디어 프리뷰 가로 스크롤
          if (media.isNotEmpty)
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: media.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = media[index];
                  return _MediaPreview(
                    attachment: item,
                    isDark: isDark,
                    signalGreen: signalGreen,
                    onRemove: () => onRemove(index),
                    onInsert: () => onInsertInline(index),
                  );
                },
              ),
            ),

          if (media.isNotEmpty) const SizedBox(height: 8),

          // 첨부 버튼 행
          Row(
            children: [
              InkWell(
                onTap: canAdd && !compressing ? onPick : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_file,
                        size: 20,
                        color: canAdd && !compressing
                            ? signalGreen
                            : (isDark
                                ? AppColors.ghostGreyDark
                                : AppColors.ghostGreyLight),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.boardPostAttachMedia,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: canAdd && !compressing
                              ? signalGreen
                              : (isDark
                                  ? AppColors.ghostGreyDark
                                  : AppColors.ghostGreyLight),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              if (compressing)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: signalGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.boardPostCompressing,
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

              if (!compressing)
                Text(
                  '${media.length}/${AppConstants.maxMediaPerPost}',
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
        ],
      ),
    );
  }
}

/// 개별 미디어 프리뷰 (72x72 썸네일 + 삽입 버튼)
class _MediaPreview extends StatelessWidget {
  final MediaAttachment attachment;
  final bool isDark;
  final Color signalGreen;
  final VoidCallback onRemove;
  final VoidCallback onInsert;

  const _MediaPreview({
    required this.attachment,
    required this.isDark,
    required this.signalGreen,
    required this.onRemove,
    required this.onInsert,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          // 썸네일 + 삭제/재생 오버레이
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: attachment.isVideo
                      ? _videoThumbnail()
                      : Image.memory(
                          attachment.compressedBytes,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              // 삭제 버튼
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
              // 동영상 오버레이
              if (attachment.isVideo)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          // 인라인 삽입 버튼
          GestureDetector(
            onTap: onInsert,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 10, color: signalGreen),
                const SizedBox(width: 2),
                Text(
                  'Insert',
                  style: TextStyle(
                    fontSize: 8,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: signalGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _videoThumbnail() {
    if (attachment.thumbnailBytes != null) {
      return Image.memory(attachment.thumbnailBytes!, fit: BoxFit.cover);
    }
    return Container(
      color: isDark ? Colors.grey[800] : Colors.grey[300],
      child: const Center(
        child: Icon(Icons.videocam, color: Colors.white54),
      ),
    );
  }
}
