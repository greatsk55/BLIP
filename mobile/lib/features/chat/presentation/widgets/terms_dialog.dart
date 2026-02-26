import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 이용약관 전체 보기 다이얼로그
/// web: TermsModal 컴포넌트와 동일 UX
class TermsDialog extends StatelessWidget {
  const TermsDialog({super.key});

  /// 다이얼로그 표시 헬퍼
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const TermsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    final sections = _getTermsSections(l10n);

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.termsTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.termsLastUpdated,
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: ghostGrey.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.termsIntro,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: ghostGrey,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...sections.map((section) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            section.content,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: ghostGrey,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: signalGreen,
                    side: BorderSide(color: signalGreen.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(l10n.commonClose),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsSection {
  final String title;
  final String content;
  const _TermsSection({required this.title, required this.content});
}

List<_TermsSection> _getTermsSections(AppLocalizations l10n) {
  return [
    _TermsSection(title: l10n.termsSection1Title, content: l10n.termsSection1Content),
    _TermsSection(title: l10n.termsSection2Title, content: l10n.termsSection2Content),
    _TermsSection(title: l10n.termsSection3Title, content: l10n.termsSection3Content),
    _TermsSection(title: l10n.termsSection4Title, content: l10n.termsSection4Content),
    _TermsSection(title: l10n.termsSection5Title, content: l10n.termsSection5Content),
    _TermsSection(title: l10n.termsSection6Title, content: l10n.termsSection6Content),
    _TermsSection(title: l10n.termsSection7Title, content: l10n.termsSection7Content),
    _TermsSection(title: l10n.termsSection8Title, content: l10n.termsSection8Content),
    _TermsSection(title: l10n.termsSection9Title, content: l10n.termsSection9Content),
  ];
}
