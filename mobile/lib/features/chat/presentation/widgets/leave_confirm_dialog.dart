import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 퇴장 확인 다이얼로그
/// web: LeaveConfirmDialog 컴포넌트와 동일 UX
class LeaveConfirmDialog extends StatelessWidget {
  final bool isLastPerson;

  const LeaveConfirmDialog({super.key, this.isLastPerson = false});

  /// 다이얼로그 표시 헬퍼 (반환: true = 퇴장 확인)
  static Future<bool> show(BuildContext context, {bool isLastPerson = false}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => LeaveConfirmDialog(isLastPerson: isLastPerson),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.chatLeaveTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.chatLeaveDescription),
          if (isLastPerson) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glitchRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.glitchRed.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.glitchRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.chatLeaveLastPersonWarning,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.glitchRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.chatLeaveCancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.glitchRed,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.chatLeaveConfirm),
        ),
      ],
    );
  }
}
