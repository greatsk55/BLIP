import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/models/device_points.dart';
import 'widgets/category_filter.dart';

/// 예측 질문 생성 화면
class CreatePredictionScreen extends ConsumerStatefulWidget {
  const CreatePredictionScreen({super.key});

  @override
  ConsumerState<CreatePredictionScreen> createState() =>
      _CreatePredictionScreenState();
}

class _CreatePredictionScreenState
    extends ConsumerState<CreatePredictionScreen> {
  final _questionController = TextEditingController();
  PredictionCategory _selectedCategory = PredictionCategory.other;
  int _durationHours = 24;

  // TODO: Riverpod provider로 교체
  final _mockPoints = DevicePoints(
    deviceFingerprint: 'mock',
    balance: 100,
    totalEarned: 500,
    totalSpent: 400,
    createdAt: DateTime.now(),
  );

  int get _cost => _mockPoints.creationCost;
  bool get _canCreate =>
      _questionController.text.trim().isNotEmpty &&
      _mockPoints.canAfford(_cost);

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _onCreate() {
    if (!_canCreate) return;
    // TODO: API 연동
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Prediction created!'),
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

    // 카테고리 목록 (all 제외)
    final categories = PredictionCategory.values
        .where((c) => c != PredictionCategory.all)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.predictionCreateTitle,
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
              // 질문 입력
              Text(
                l10n.predictionQuestion,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _questionController,
                maxLength: 200,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.predictionQuestionHint,
                  counterStyle: TextStyle(
                    color: ghostGrey,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 카테고리 선택
              Text(
                l10n.predictionCategory,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = cat == _selectedCategory;
                  return ChoiceChip(
                    label: Text(categoryLabel(cat, l10n)),
                    avatar: isSelected
                        ? null
                        : Icon(categoryIcon(cat), size: 16),
                    selected: isSelected,
                    selectedColor: signalGreen,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isDark
                              ? AppColors.voidBlackDark
                              : AppColors.white)
                          : ghostGrey,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 마감 시간
              Text(
                l10n.predictionDuration,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _DurationChip(
                    label: '1h',
                    isSelected: _durationHours == 1,
                    signalGreen: signalGreen,
                    ghostGrey: ghostGrey,
                    isDark: isDark,
                    onTap: () => setState(() => _durationHours = 1),
                  ),
                  const SizedBox(width: 10),
                  _DurationChip(
                    label: '6h',
                    isSelected: _durationHours == 6,
                    signalGreen: signalGreen,
                    ghostGrey: ghostGrey,
                    isDark: isDark,
                    onTap: () => setState(() => _durationHours = 6),
                  ),
                  const SizedBox(width: 10),
                  _DurationChip(
                    label: '24h',
                    isSelected: _durationHours == 24,
                    signalGreen: signalGreen,
                    ghostGrey: ghostGrey,
                    isDark: isDark,
                    onTap: () => setState(() => _durationHours = 24),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 비용 표시
              Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.predictionCost(_cost),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: signalGreen,
                          ),
                        ),
                        if (_mockPoints.rank == 'Oracle' ||
                            _mockPoints.rank == 'Control')
                          Text(
                            '${l10n.predictionRank}: ${_mockPoints.rank} discount',
                            style: TextStyle(
                              fontSize: 11,
                              color: ghostGrey,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${l10n.predictionBalance}: ${_mockPoints.balance} BP',
                      style: TextStyle(
                        fontSize: 12,
                        color: ghostGrey,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canCreate ? _onCreate : null,
                  child: Text(
                    l10n.predictionSubmit(_cost),
                  ),
                ),
              ),

              // BP 부족 경고
              if (!_mockPoints.canAfford(_cost))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l10n.predictionInsufficientBP,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.glitchRed,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color signalGreen;
  final Color ghostGrey;
  final bool isDark;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.signalGreen,
    required this.ghostGrey,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? signalGreen.withValues(alpha: 0.15)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? signalGreen : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            color: isSelected ? signalGreen : ghostGrey,
          ),
        ),
      ),
    );
  }
}
