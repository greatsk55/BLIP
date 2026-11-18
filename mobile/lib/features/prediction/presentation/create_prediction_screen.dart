import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/device_identity_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/network/api_client.dart';
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

  DevicePoints? _points;
  bool _busy = false;
  bool _loadFailed = false;

  int get _cost => _points?.creationCost ?? 150;
  bool get _canCreate => !_busy && _points != null &&
      _questionController.text.trim().isNotEmpty && _points!.canAfford(_cost);

  @override
  void initState() {
    super.initState();
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    setState(() => _loadFailed = false);
    try {
      final fingerprint = await DeviceIdentityService.instance.getFingerprint();
      await supabase.rpc('register_device', params: {
        'p_device_fingerprint': fingerprint, 'p_hardware_hash': null,
      });
      final data = await supabase.from('device_points').select()
          .eq('device_fingerprint', fingerprint).single();
      if (mounted) setState(() => _points = DevicePoints.fromJson(data));
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (!_canCreate) return;
    final locale = Localizations.localeOf(context);
    final localeCode = locale.countryCode == 'TW' ? 'zh-TW' : locale.languageCode;
    setState(() => _busy = true);
    try {
      final closes = DateTime.now().toUtc().add(Duration(hours: _durationHours));
      final response = await ApiClient().dio.post('/api/prediction', data: {
        'deviceFingerprint': _points!.deviceFingerprint,
        'question': _questionController.text.trim(),
        'category': _selectedCategory.name,
        'closesAt': closes.toIso8601String(),
        'revealsAt': closes.add(const Duration(hours: 1)).toIso8601String(),
        'locale': localeCode,
      });
      if (response.data['success'] != true) throw StateError('Creation rejected');
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.commonError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen = isDark
        ? AppColors.signalGreenDark
        : AppColors.signalGreenLight;
    final ghostGrey = isDark
        ? AppColors.ghostGreyDark
        : AppColors.ghostGreyLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

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
              if (_points == null && !_loadFailed) const LinearProgressIndicator(),
              if (_loadFailed) TextButton(onPressed: _loadPoints, child: Text(l10n.commonRetry)),
              // 질문 입력
              Text(
                l10n.predictionQuestion,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? (isDark ? AppColors.voidBlackDark : AppColors.white)
                          : ghostGrey,
                    ),
                    side: BorderSide.none,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // 마감 시간
              Text(
                l10n.predictionDuration,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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

                      ],
                    ),
                    Text(
                      '${l10n.predictionBalance}: ${_points?.balance ?? '…'} BP',
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
                  child: Text(l10n.predictionSubmit(_cost)),
                ),
              ),

              // BP 부족 경고
              if (_points != null && !_points!.canAfford(_cost))
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
