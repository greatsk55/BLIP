import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 관리자 패널 다이얼로그
/// web: AdminPanel.tsx 동일 UX
class AdminPanelDialog extends StatefulWidget {
  final Future<void> Function() onForgetToken;
  final Future<String?> Function() onDestroyBoard;
  final String? currentSubtitle;
  final Future<String?> Function(String subtitle)? onUpdateSubtitle;

  const AdminPanelDialog({
    super.key,
    required this.onForgetToken,
    required this.onDestroyBoard,
    this.currentSubtitle,
    this.onUpdateSubtitle,
  });

  /// 다이얼로그 표시
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onForgetToken,
    required Future<String?> Function() onDestroyBoard,
    String? currentSubtitle,
    Future<String?> Function(String subtitle)? onUpdateSubtitle,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdminPanelDialog(
        onForgetToken: onForgetToken,
        onDestroyBoard: onDestroyBoard,
        currentSubtitle: currentSubtitle,
        onUpdateSubtitle: onUpdateSubtitle,
      ),
    );
  }

  @override
  State<AdminPanelDialog> createState() => _AdminPanelDialogState();
}

class _AdminPanelDialogState extends State<AdminPanelDialog> {
  bool _showDestroyConfirm = false;
  bool _destroying = false;
  bool _showSubtitleEdit = false;
  bool _subtitleSaving = false;
  late final TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    _subtitleController = TextEditingController(text: widget.currentSubtitle ?? '');
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _handleDestroy() async {
    setState(() => _destroying = true);
    final error = await widget.onDestroyBoard();
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _destroying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.boardAdminPanel,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: _showDestroyConfirm
          ? _buildDestroyConfirm(l10n, isDark)
          : _buildMenu(l10n, isDark),
    );
  }

  Widget _buildMenu(AppLocalizations l10n, bool isDark) {
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 부제목 편집
        if (widget.onUpdateSubtitle != null && !_showSubtitleEdit)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showSubtitleEdit = true),
              icon: Icon(Icons.subtitles_outlined, size: 18, color: signalGreen),
              label: Text(
                l10n.boardAdminEditSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),

        // 부제목 편집 입력 영역
        if (_showSubtitleEdit) ...[
          TextField(
            controller: _subtitleController,
            autofocus: true,
            maxLength: 100,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: l10n.boardAdminSubtitlePlaceholder,
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: signalGreen),
              ),
            ),
            onSubmitted: (_) => _handleSaveSubtitle(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _subtitleController.text = widget.currentSubtitle ?? '';
                    _showSubtitleEdit = false;
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Text(l10n.commonCancel,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _subtitleSaving ? null : _handleSaveSubtitle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: signalGreen,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: _subtitleSaving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.boardAdminSubtitleSave,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],

        if (_showSubtitleEdit || widget.onUpdateSubtitle != null)
          const SizedBox(height: 12),

        // 관리자 토큰 해제
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              widget.onForgetToken();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.key_off, size: 18),
            label: Text(
              l10n.boardAdminForgetToken,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 커뮤니티 파쇄
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showDestroyConfirm = true),
            icon: const Icon(Icons.delete_forever, size: 18,
                color: AppColors.glitchRed),
            label: Text(
              l10n.boardAdminDestroy,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.glitchRed,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(
                color: AppColors.glitchRed,
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSaveSubtitle() async {
    if (widget.onUpdateSubtitle == null) return;
    setState(() => _subtitleSaving = true);
    final error = await widget.onUpdateSubtitle!(_subtitleController.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _subtitleSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.glitchRed,
        ),
      );
      return;
    }
    setState(() {
      _subtitleSaving = false;
      _showSubtitleEdit = false;
    });
  }

  Widget _buildDestroyConfirm(AppLocalizations l10n, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded,
            size: 40, color: AppColors.glitchRed),
        const SizedBox(height: 12),
        Text(
          l10n.boardAdminDestroyWarning,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.glitchRed,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showDestroyConfirm = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  l10n.commonCancel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _destroying ? null : _handleDestroy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.glitchRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _destroying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.boardAdminConfirmDestroy,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
