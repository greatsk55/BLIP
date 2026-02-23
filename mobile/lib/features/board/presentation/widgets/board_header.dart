import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 커뮤니티 게시판 헤더 (관리자 토큰 UI 포함)
/// web: BoardHeader.tsx 동일 UX
class BoardHeader extends StatelessWidget {
  final String boardName;
  final String? boardSubtitle;
  final bool hasAdminToken;
  final bool isPasswordSaved;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onAdminPanel;
  final VoidCallback onRegisterAdmin;
  final VoidCallback? onForgetPassword;

  const BoardHeader({
    super.key,
    required this.boardName,
    this.boardSubtitle,
    required this.hasAdminToken,
    required this.isPasswordSaved,
    required this.onBack,
    required this.onRefresh,
    required this.onAdminPanel,
    required this.onRegisterAdmin,
    this.onForgetPassword,
  });

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
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
          children: [
            // 뒤로가기
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
            ),

            // 커뮤니티 이름 + E2E 뱃지
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    boardName,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (boardSubtitle != null && boardSubtitle!.isNotEmpty)
                    Text(
                      boardSubtitle!,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: isDark
                            ? AppColors.ghostGreyDark.withValues(alpha: 0.6)
                            : AppColors.ghostGreyLight.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.lock, size: 10, color: signalGreen),
                        const SizedBox(width: 4),
                        Text(
                          l10n.boardHeaderEncrypted,
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: signalGreen.withValues(alpha: 0.6),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // 리프레시
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: l10n.boardRefresh,
            ),

            // 관리자 Shield 아이콘
            IconButton(
              onPressed: hasAdminToken ? onAdminPanel : onRegisterAdmin,
              icon: Icon(
                Icons.shield_outlined,
                size: 20,
                color: hasAdminToken
                    ? signalGreen
                    : (isDark
                        ? AppColors.ghostGreyDark.withValues(alpha: 0.5)
                        : AppColors.ghostGreyLight.withValues(alpha: 0.5)),
              ),
              tooltip: hasAdminToken
                  ? l10n.boardAdminPanel
                  : l10n.boardAdminRegister,
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// 관리자 토큰 등록 다이얼로그
  static Future<String?> showTokenInputDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.boardAdminRegister,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: TextCapitalization.none,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
          ),
          decoration: InputDecoration(
            hintText: l10n.boardAdminTokenPlaceholder,
            hintStyle: TextStyle(
              fontFamily: 'monospace',
              color: isDark
                  ? AppColors.ghostGreyDark.withValues(alpha: 0.5)
                  : AppColors.ghostGreyLight.withValues(alpha: 0.5),
            ),
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
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(context).pop(value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.commonCancel,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(context).pop(value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: signalGreen,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            child: Text(
              l10n.boardAdminConfirmRegister,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
