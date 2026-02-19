import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 관리자 패널 다이얼로그
/// web: AdminPanel.tsx 동일 UX
class AdminPanelDialog extends StatefulWidget {
  final Future<void> Function() onForgetToken;
  final Future<String?> Function() onDestroyBoard;

  const AdminPanelDialog({
    super.key,
    required this.onForgetToken,
    required this.onDestroyBoard,
  });

  /// 다이얼로그 표시
  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onForgetToken,
    required Future<String?> Function() onDestroyBoard,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdminPanelDialog(
        onForgetToken: onForgetToken,
        onDestroyBoard: onDestroyBoard,
      ),
    );
  }

  @override
  State<AdminPanelDialog> createState() => _AdminPanelDialogState();
}

class _AdminPanelDialogState extends State<AdminPanelDialog> {
  bool _showDestroyConfirm = false;
  bool _destroying = false;

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
