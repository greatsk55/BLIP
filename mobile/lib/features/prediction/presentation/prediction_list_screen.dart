import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../domain/models/device_points.dart';
import 'widgets/category_filter.dart';
import 'widgets/points_chip.dart';
import 'widgets/prediction_card.dart';

/// 활성 질문 목록 화면
class PredictionListScreen extends ConsumerStatefulWidget {
  const PredictionListScreen({super.key});

  @override
  ConsumerState<PredictionListScreen> createState() =>
      _PredictionListScreenState();
}

class _PredictionListScreenState extends ConsumerState<PredictionListScreen> {
  PredictionCategory _selectedCategory = PredictionCategory.all;

  // TODO: Riverpod provider로 교체
  final _mockPoints = DevicePoints(
    deviceFingerprint: 'mock',
    balance: 100,
    totalEarned: 500,
    totalSpent: 400,
    createdAt: DateTime.now(),
  );

  // TODO: API 연동 시 실제 데이터로 교체
  List<_MockPrediction> get _filteredPredictions {
    if (_selectedCategory == PredictionCategory.all) return _mockPredictions;
    return _mockPredictions
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PointsChip(points: _mockPoints),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 카테고리 필터
            CategoryFilter(
              selected: _selectedCategory,
              onSelected: (cat) =>
                  setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 12),

            // 질문 리스트
            Expanded(
              child: _filteredPredictions.isEmpty
                  ? Center(
                      child: Text(
                        l10n.predictionTitle,
                        style: TextStyle(
                          color: ghostGrey,
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filteredPredictions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final p = _filteredPredictions[index];
                        return PredictionCard(
                          id: p.id,
                          question: p.question,
                          category: p.category,
                          yesOdds: p.yesOdds,
                          noOdds: p.noOdds,
                          participants: p.participants,
                          closesAt: p.closesAt,
                          onTap: () => context.push('/prediction/${p.id}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/prediction/create'),
        backgroundColor: signalGreen,
        foregroundColor: isDark ? AppColors.voidBlackDark : AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ── Mock 데이터 (API 연동 전) ──
class _MockPrediction {
  final String id;
  final String question;
  final PredictionCategory category;
  final double yesOdds;
  final double noOdds;
  final int participants;
  final DateTime closesAt;

  const _MockPrediction({
    required this.id,
    required this.question,
    required this.category,
    required this.yesOdds,
    required this.noOdds,
    required this.participants,
    required this.closesAt,
  });
}

final _mockPredictions = [
  _MockPrediction(
    id: 'pred001',
    question: 'Will Bitcoin break \$100k by end of 2026?',
    category: PredictionCategory.economy,
    yesOdds: 1.85,
    noOdds: 2.10,
    participants: 42,
    closesAt: DateTime.now().add(const Duration(hours: 6)),
  ),
  _MockPrediction(
    id: 'pred002',
    question: 'Will the next iPhone have a foldable screen?',
    category: PredictionCategory.tech,
    yesOdds: 3.50,
    noOdds: 1.25,
    participants: 128,
    closesAt: DateTime.now().add(const Duration(hours: 24)),
  ),
  _MockPrediction(
    id: 'pred003',
    question: 'Will Team Liquid win Worlds 2026?',
    category: PredictionCategory.gaming,
    yesOdds: 4.20,
    noOdds: 1.15,
    participants: 87,
    closesAt: DateTime.now().add(const Duration(hours: 1)),
  ),
];
