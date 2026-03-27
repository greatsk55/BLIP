import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 정산 결과 오버레이 (승리/패배 애니메이션)
class SettlementOverlay extends StatefulWidget {
  final bool isWin;
  final int payout;
  final VoidCallback onDismiss;

  const SettlementOverlay({
    super.key,
    required this.isWin,
    required this.payout,
    required this.onDismiss,
  });

  /// 오버레이 표시 헬퍼
  static void show(
    BuildContext context, {
    required bool isWin,
    required int payout,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => SettlementOverlay(
        isWin: isWin,
        payout: payout,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<SettlementOverlay> createState() => _SettlementOverlayState();
}

class _SettlementOverlayState extends State<SettlementOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = widget.isWin
        ? (isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight)
        : AppColors.glitchRed;

    return GestureDetector(
      onTap: widget.onDismiss,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 아이콘
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      widget.isWin ? Icons.check_circle : Icons.cancel,
                      color: color,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 메시지
                  Text(
                    widget.isWin
                        ? l10n.predictionWon
                        : l10n.predictionLost,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 정산 금액
                  Text(
                    l10n.predictionPayout(widget.payout),
                    style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 닫기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: widget.onDismiss,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: color),
                        foregroundColor: color,
                      ),
                      child: Text(l10n.commonClose),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
