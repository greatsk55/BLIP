import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 관리자 액션 확인 다이얼로그 (방 폭파, 강퇴 등)
class AdminActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;

  const AdminActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: AppColors.glitchRed),
          ),
        ),
      ],
    );
  }
}
