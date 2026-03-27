import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 예측 카테고리 enum (SSOT)
enum PredictionCategory {
  all,
  politics,
  sports,
  tech,
  economy,
  entertainment,
  society,
  gaming,
  other,
}

/// 카테고리 -> 다국어 라벨
String categoryLabel(PredictionCategory cat, AppLocalizations l10n) {
  switch (cat) {
    case PredictionCategory.all:
      return l10n.predictionAll;
    case PredictionCategory.politics:
      return l10n.predictionPolitics;
    case PredictionCategory.sports:
      return l10n.predictionSports;
    case PredictionCategory.tech:
      return l10n.predictionTech;
    case PredictionCategory.economy:
      return l10n.predictionEconomy;
    case PredictionCategory.entertainment:
      return l10n.predictionEntertainment;
    case PredictionCategory.society:
      return l10n.predictionSociety;
    case PredictionCategory.gaming:
      return l10n.predictionGaming;
    case PredictionCategory.other:
      return l10n.predictionOther;
  }
}

/// 카테고리 -> 아이콘
IconData categoryIcon(PredictionCategory cat) {
  switch (cat) {
    case PredictionCategory.all:
      return Icons.apps;
    case PredictionCategory.politics:
      return Icons.gavel;
    case PredictionCategory.sports:
      return Icons.sports_soccer;
    case PredictionCategory.tech:
      return Icons.computer;
    case PredictionCategory.economy:
      return Icons.trending_up;
    case PredictionCategory.entertainment:
      return Icons.movie;
    case PredictionCategory.society:
      return Icons.people;
    case PredictionCategory.gaming:
      return Icons.sports_esports;
    case PredictionCategory.other:
      return Icons.more_horiz;
  }
}

/// 카테고리 필터 칩 (수평 스크롤)
class CategoryFilter extends StatelessWidget {
  final PredictionCategory selected;
  final ValueChanged<PredictionCategory> onSelected;

  const CategoryFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: PredictionCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = PredictionCategory.values[index];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(
              categoryLabel(cat, l10n),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppColors.voidBlackDark : AppColors.white)
                    : ghostGrey,
              ),
            ),
            avatar: isSelected
                ? null
                : Icon(categoryIcon(cat), size: 14, color: ghostGrey),
            selected: isSelected,
            selectedColor: signalGreen,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            side: BorderSide.none,
            onSelected: (_) => onSelected(cat),
          );
        },
      ),
    );
  }
}
