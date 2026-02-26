import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/terms_label_builder.dart';

/// 이용약관 동의 확인 다이얼로그
/// 방 생성 전 이용약관 동의를 받는 재사용 가능한 다이얼로그
/// 반환: true = 동의 후 진행, false = 취소
class TermsConfirmDialog extends StatefulWidget {
  const TermsConfirmDialog({super.key});

  /// 다이얼로그 표시 헬퍼
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const TermsConfirmDialog(),
    );
    return result ?? false;
  }

  @override
  State<TermsConfirmDialog> createState() => _TermsConfirmDialogState();
}

class _TermsConfirmDialogState extends State<TermsConfirmDialog> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.termsTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 체크박스 + 이용약관 텍스트
          GestureDetector(
            onTap: () => setState(() => _agreed = !_agreed),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: signalGreen,
                    side: BorderSide(color: ghostGrey),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: buildTermsLabel(
                      context: context,
                      fullText: l10n.termsAgree,
                      linkText: l10n.termsAgreeLink,
                      textColor: ghostGrey,
                      linkColor: signalGreen,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _agreed ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}
