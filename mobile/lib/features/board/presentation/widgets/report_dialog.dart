import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/board_post.dart';

/// 게시글 신고 다이얼로그
/// web: BoardRoom.tsx 내 ReportDialog 동일 UX
class ReportDialog extends StatefulWidget {
  final Future<String?> Function(ReportReason reason) onSubmit;

  const ReportDialog({super.key, required this.onSubmit});

  /// 다이얼로그 표시 헬퍼
  static Future<void> show(
    BuildContext context, {
    required Future<String?> Function(ReportReason reason) onSubmit,
  }) {
    return showDialog(
      context: context,
      builder: (_) => ReportDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  ReportReason? _selected;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_selected == null || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await widget.onSubmit(_selected!);

    if (!mounted) return;

    if (error != null) {
      setState(() {
        _submitting = false;
        _error = error;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reasons = {
      ReportReason.spam: l10n.boardReportSpam,
      ReportReason.abuse: l10n.boardReportAbuse,
      ReportReason.illegal: l10n.boardReportIllegal,
      ReportReason.other: l10n.boardReportOther,
    };

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        l10n.boardReportTitle,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error == 'ALREADY_REPORTED'
                    ? l10n.boardReportAlreadyReported
                    : _error!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.glitchRed,
                ),
              ),
            ),
          RadioGroup<ReportReason>(
            groupValue: _selected,
            onChanged: (v) => setState(() => _selected = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: reasons.entries.map((entry) {
                return RadioListTile<ReportReason>(
                  value: entry.key,
                  title: Text(
                    entry.value,
                    style:
                        const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                  ),
                  dense: true,
                  activeColor: isDark
                      ? AppColors.signalGreenDark
                      : AppColors.signalGreenLight,
                );
              }).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.boardReportCancel),
        ),
        ElevatedButton(
          onPressed: _selected != null && !_submitting ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.glitchRed,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.boardReportSubmit),
        ),
      ],
    );
  }
}
