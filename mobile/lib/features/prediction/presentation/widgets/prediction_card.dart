import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import 'category_filter.dart';

/// 예측 질문 카드
class PredictionCard extends StatelessWidget {
  final String id;
  final String question;
  final PredictionCategory category;
  final double yesOdds;
  final double noOdds;
  final int participants;
  final DateTime createdAt;
  final DateTime closesAt;
  final bool isClosed;
  final String status;
  final String? correctAnswer;
  final VoidCallback? onTap;

  const PredictionCard({
    super.key,
    required this.id,
    required this.question,
    required this.category,
    required this.yesOdds,
    required this.noOdds,
    required this.participants,
    required this.createdAt,
    required this.closesAt,
    this.isClosed = false,
    this.status = 'active',
    this.correctAnswer,
    this.onTap,
  });

  String _formatTimeRemaining(AppLocalizations l10n) {
    if (isClosed) return l10n.predictionClosed;
    final diff = closesAt.difference(DateTime.now());
    if (diff.isNegative) return l10n.predictionClosed;
    if (diff.inHours >= 1) {
      return l10n.predictionClosesIn('${diff.inHours}h');
    }
    return l10n.predictionClosesIn('${diff.inMinutes}m');
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final isExpired =
        isClosed || closesAt.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
          color: isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 + 시간
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: signalGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    categoryLabel(category, l10n),
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: signalGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (status == 'settled') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: signalGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      correctAnswer?.toUpperCase() ?? 'SETTLED',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: signalGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (status == 'closed') ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CLOSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  isExpired ? Icons.lock : Icons.access_time,
                  size: 12,
                  color: isExpired ? AppColors.glitchRed : ghostGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimeRemaining(l10n),
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isExpired ? AppColors.glitchRed : ghostGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 질문
            Text(
              question,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // 배당률 + 참여자
            Row(
              children: [
                // Yes 배당률
                _OddsBadge(
                  label: l10n.predictionYes,
                  odds: yesOdds,
                  color: signalGreen,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                // No 배당률
                _OddsBadge(
                  label: l10n.predictionNo,
                  odds: noOdds,
                  color: AppColors.glitchRed,
                  isDark: isDark,
                ),
                const Spacer(),
                Icon(Icons.people_outline, size: 14, color: ghostGrey),
                const SizedBox(width: 4),
                Text(
                  l10n.predictionParticipants(participants),
                  style: TextStyle(
                    fontSize: 11,
                    color: ghostGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 시작일 / 마감일
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 11, color: ghostGrey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: ghostGrey),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 10, color: ghostGrey),
                const SizedBox(width: 8),
                Icon(
                  Icons.flag_outlined,
                  size: 11,
                  color: isExpired ? AppColors.glitchRed : ghostGrey,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(closesAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isExpired ? AppColors.glitchRed : ghostGrey,
                    fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OddsBadge extends StatelessWidget {
  final String label;
  final double odds;
  final Color color;
  final bool isDark;

  const _OddsBadge({
    required this.label,
    required this.odds,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label ${odds.toStringAsFixed(2)}x',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
