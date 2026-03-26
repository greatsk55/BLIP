import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/models/device_points.dart';
import 'widgets/betting_bottom_sheet.dart';
import 'widgets/category_filter.dart';

/// 예측 질문 상세 화면
class PredictionDetailScreen extends ConsumerStatefulWidget {
  final String predictionId;

  const PredictionDetailScreen({
    super.key,
    required this.predictionId,
  });

  @override
  ConsumerState<PredictionDetailScreen> createState() =>
      _PredictionDetailScreenState();
}

class _PredictionDetailScreenState
    extends ConsumerState<PredictionDetailScreen> {
  // TODO: Riverpod provider로 교체
  final _mockPoints = DevicePoints(
    deviceFingerprint: 'mock',
    balance: 100,
    totalEarned: 500,
    totalSpent: 400,
    createdAt: DateTime.now(),
  );

  // Mock 데이터
  late final String _question = 'Will Bitcoin break \$100k by end of 2026?';
  late final PredictionCategory _category = PredictionCategory.economy;
  late final double _yesOdds = 1.85;
  late final double _noOdds = 2.10;
  late final int _participants = 42;
  late final int _yesBets = 25;
  late final int _noBets = 17;
  late final DateTime _closesAt =
      DateTime.now().add(const Duration(hours: 6));
  late final bool _isClosed = false;
  late final bool _isSettled = false;

  String _formatTimeRemaining(AppLocalizations l10n) {
    if (_isClosed) return l10n.predictionClosed;
    final diff = _closesAt.difference(DateTime.now());
    if (diff.isNegative) return l10n.predictionClosed;
    if (diff.inHours >= 1) {
      return l10n.predictionClosesIn('${diff.inHours}h ${diff.inMinutes % 60}m');
    }
    return l10n.predictionClosesIn('${diff.inMinutes}m');
  }

  void _onBet(String option, int amount) {
    // TODO: API 연동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Bet $amount BP on $option'),
        behavior: SnackBarBehavior.floating,
      ),
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
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final isExpired = _isClosed || _closesAt.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.predictionTitle,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 + 시간
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: signalGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      categoryLabel(_category, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: signalGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isExpired ? Icons.lock : Icons.access_time,
                    size: 14,
                    color: isExpired ? AppColors.glitchRed : ghostGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeRemaining(l10n),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isExpired ? AppColors.glitchRed : ghostGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 질문
              Text(
                _question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.predictionParticipants(_participants),
                style: TextStyle(
                  fontSize: 13,
                  color: ghostGrey,
                ),
              ),
              const SizedBox(height: 28),

              // 배당률 카드
              _buildOddsSection(l10n, signalGreen, ghostGrey, borderColor, isDark),
              const SizedBox(height: 20),

              // 배팅 분포 바
              _buildDistributionBar(signalGreen, ghostGrey, isDark),
              const SizedBox(height: 28),

              // 정산 결과 (정산 완료 시)
              if (_isSettled) ...[
                _buildSettlementResult(l10n, signalGreen, borderColor, isDark),
                const SizedBox(height: 28),
              ],

              // 잔액 정보
              _buildBalanceInfo(l10n, signalGreen, ghostGrey, borderColor, isDark),
            ],
          ),
        ),
      ),
      // 베팅 버튼 (마감 전만)
      bottomNavigationBar: isExpired
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => BettingBottomSheet.show(
                      context,
                      question: _question,
                      yesOdds: _yesOdds,
                      noOdds: _noOdds,
                      points: _mockPoints,
                      onBet: _onBet,
                    ),
                    child: Text(l10n.predictionBet),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOddsSection(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    Color borderColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Expanded(
          child: _OddsCard(
            label: l10n.predictionYes,
            odds: _yesOdds,
            color: signalGreen,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _OddsCard(
            label: l10n.predictionNo,
            odds: _noOdds,
            color: AppColors.glitchRed,
            borderColor: borderColor,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildDistributionBar(
    Color signalGreen,
    Color ghostGrey,
    bool isDark,
  ) {
    final total = _yesBets + _noBets;
    final yesFraction = total > 0 ? _yesBets / total : 0.5;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (yesFraction * 100).round(),
                  child: Container(color: signalGreen),
                ),
                Expanded(
                  flex: ((1 - yesFraction) * 100).round(),
                  child: Container(color: AppColors.glitchRed),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_yesBets bets',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: signalGreen,
              ),
            ),
            Text(
              '$_noBets bets',
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.glitchRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettlementResult(
    AppLocalizations l10n,
    Color signalGreen,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: signalGreen.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: signalGreen.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle, color: signalGreen, size: 36),
          const SizedBox(height: 8),
          Text(
            l10n.predictionWon,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: signalGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.predictionPayout(250),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: signalGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    Color borderColor,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.white,
      ),
      child: Row(
        children: [
          Text(
            _mockPoints.rankEmoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.predictionRank}: ${_mockPoints.rank}',
                style: TextStyle(
                  fontSize: 12,
                  color: ghostGrey,
                ),
              ),
              Text(
                '${_mockPoints.balance} BP',
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: signalGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OddsCard extends StatelessWidget {
  final String label;
  final double odds;
  final Color color;
  final Color borderColor;
  final bool isDark;

  const _OddsCard({
    required this.label,
    required this.odds,
    required this.color,
    required this.borderColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: color.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${odds.toStringAsFixed(2)}x',
            style: TextStyle(
              fontSize: 28,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
