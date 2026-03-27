import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/device_points.dart';

/// 베팅 바텀시트 (슬라이더 + 옵션 선택 + 예상 수익)
class BettingBottomSheet extends StatefulWidget {
  final String question;
  final double yesOdds;
  final double noOdds;
  final DevicePoints points;
  final void Function(String option, int amount) onBet;

  const BettingBottomSheet({
    super.key,
    required this.question,
    required this.yesOdds,
    required this.noOdds,
    required this.points,
    required this.onBet,
  });

  /// 바텀시트 표시 헬퍼
  static Future<void> show(
    BuildContext context, {
    required String question,
    required double yesOdds,
    required double noOdds,
    required DevicePoints points,
    required void Function(String option, int amount) onBet,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BettingBottomSheet(
        question: question,
        yesOdds: yesOdds,
        noOdds: noOdds,
        points: points,
        onBet: onBet,
      ),
    );
  }

  @override
  State<BettingBottomSheet> createState() => _BettingBottomSheetState();
}

class _BettingBottomSheetState extends State<BettingBottomSheet> {
  String _selectedOption = 'yes';
  double _betAmount = 1;

  double get _currentOdds =>
      _selectedOption == 'yes' ? widget.yesOdds : widget.noOdds;

  int get _expectedPayout => (_betAmount * _currentOdds).floor();

  int get _maxBet => widget.points.balance.clamp(1, 1000);

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
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final canBet = widget.points.balance >= _betAmount.round();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ghostGrey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // 질문
            Text(
              widget.question,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Yes / No 선택
            Row(
              children: [
                Expanded(
                  child: _OptionButton(
                    label: l10n.predictionYes,
                    odds: widget.yesOdds,
                    isSelected: _selectedOption == 'yes',
                    color: signalGreen,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedOption = 'yes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OptionButton(
                    label: l10n.predictionNo,
                    odds: widget.noOdds,
                    isSelected: _selectedOption == 'no',
                    color: AppColors.glitchRed,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedOption = 'no'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 베팅 금액 슬라이더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.predictionBet,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: ghostGrey,
                  ),
                ),
                Text(
                  '${_betAmount.round()} BP',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: signalGreen,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: signalGreen,
                inactiveTrackColor: borderColor,
                thumbColor: signalGreen,
                overlayColor: signalGreen.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: _betAmount,
                min: 1,
                max: _maxBet.toDouble(),
                divisions: _maxBet > 1 ? _maxBet - 1 : 1,
                onChanged: (v) => setState(() => _betAmount = v),
              ),
            ),
            const SizedBox(height: 8),

            // 배당률 + 예상 수익
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.predictionOdds,
                        style: TextStyle(fontSize: 11, color: ghostGrey),
                      ),
                      Text(
                        '${_currentOdds.toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: signalGreen,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.predictionExpectedPayout,
                        style: TextStyle(fontSize: 11, color: ghostGrey),
                      ),
                      Text(
                        '$_expectedPayout BP',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          color: signalGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Rake 고지
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '10% fee applies. ${_betAmount.round()} BP bet → ${(_betAmount * 0.9).floor()} BP in pool. Bets are non-refundable.',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 베팅 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: canBet
                    ? () {
                        widget.onBet(_selectedOption, _betAmount.round());
                        Navigator.of(context).pop();
                      }
                    : null,
                child: Text(
                  canBet
                      ? '${l10n.predictionBet} (${_betAmount.round()} BP)'
                      : l10n.predictionInsufficientBP,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String label;
  final double odds;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionButton({
    required this.label,
    required this.odds,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? color : (isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${odds.toStringAsFixed(2)}x',
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: isSelected ? color : (isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
