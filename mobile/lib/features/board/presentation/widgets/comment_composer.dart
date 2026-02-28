import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/media/media_processor.dart';
import '../../domain/models/board_post.dart';

const _maxCommentMedia = 2;

/// 댓글 입력 위젯
/// web: CommentComposer.tsx 동일 UX
class CommentComposer extends StatefulWidget {
  final Future<String?> Function(String content, {List<MediaAttachment>? media})
      onSubmit;

  const CommentComposer({super.key, required this.onSubmit});

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  final List<MediaAttachment> _media = [];
  final List<String> _previewPaths = []; // XFile.path for preview
  bool _sending = false;

  bool get _canSubmit =>
      (_controller.text.trim().isNotEmpty || _media.isNotEmpty) && !_sending;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _sending = true);

    final error = await widget.onSubmit(
      _controller.text.trim(),
      media: _media.isNotEmpty ? _media : null,
    );

    if (mounted) {
      setState(() => _sending = false);
      if (error == null) {
        _controller.clear();
        _media.clear();
        _previewPaths.clear();
      }
    }
  }

  Future<void> _pickImage() async {
    if (_media.length >= _maxCommentMedia) return;

    final remaining = _maxCommentMedia - _media.length;
    final files = await _picker.pickMultiImage(limit: remaining);
    if (files.isEmpty || !mounted) return;

    for (final file in files.take(remaining)) {
      try {
        final compressed = await compressImage(file);
        _media.add(MediaAttachment(
          compressedBytes: compressed.bytes,
          mimeType: 'image/jpeg',
          width: compressed.width,
          height: compressed.height,
        ));
        _previewPaths.add(file.path);
      } catch (_) {
        // 압축 실패 시 스킵
      }
    }
    if (mounted) setState(() {});
  }

  void _removeFile(int index) {
    setState(() {
      _media.removeAt(index);
      _previewPaths.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 첨부 이미지 미리보기
            if (_previewPaths.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: _previewPaths.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.memory(
                          _media[i].compressedBytes,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: () => _removeFile(i),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 입력 영역
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 이미지 첨부
                IconButton(
                  onPressed:
                      _media.length >= _maxCommentMedia || _sending
                          ? null
                          : _pickImage,
                  icon: Icon(
                    Icons.image_outlined,
                    size: 20,
                    color: (isDark
                            ? AppColors.ghostGreyDark
                            : AppColors.ghostGreyLight)
                        .withValues(alpha: 0.6),
                  ),
                  tooltip: l10n.boardCommentAttachImage,
                ),

                // 텍스트 입력
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 3,
                    minLines: 1,
                    enabled: !_sending,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.boardCommentPlaceholder,
                      hintStyle: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: (isDark
                                ? AppColors.ghostGreyDark
                                : AppColors.ghostGreyLight)
                            .withValues(alpha: 0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                    ),
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                  ),
                ),

                // 전송
                IconButton(
                  onPressed: _canSubmit ? _submit : null,
                  icon: Icon(
                    Icons.send,
                    size: 20,
                    color: _canSubmit
                        ? signalGreen
                        : (isDark
                                ? AppColors.ghostGreyDark
                                : AppColors.ghostGreyLight)
                            .withValues(alpha: 0.3),
                  ),
                  tooltip: l10n.boardCommentSubmit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
