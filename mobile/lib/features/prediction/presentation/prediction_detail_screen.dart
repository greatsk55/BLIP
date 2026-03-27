import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/supabase/supabase_client.dart';
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
  Map<String, dynamic>? _prediction;
  DevicePoints? _points;
  String? _deviceFingerprint;
  bool _loading = true;
  bool _betting = false;
  List<Map<String, dynamic>> _myBets = [];
  double _yesOdds = 1.85;
  double _noOdds = 2.10;
  int _yesBets = 0;
  int _noBets = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String> _getDeviceFingerprint() async {
    // 간단한 디바이스 fingerprint (웹과 동일 로직 간소화)
    final raw = '${DateTime.now().timeZoneName}|mobile';
    final hash = sha256.convert(utf8.encode(raw)).toString();
    return hash;
  }

  Future<void> _loadData() async {
    try {
      final fp = await _getDeviceFingerprint();
      _deviceFingerprint = fp;

      // 예측 조회
      final pred = await supabase
          .from('predictions')
          .select()
          .eq('id', widget.predictionId)
          .single();

      // 디바이스 포인트 조회 (없으면 등록)
      var pointsData = await supabase
          .from('device_points')
          .select()
          .eq('device_fingerprint', fp)
          .maybeSingle();

      if (pointsData == null) {
        // 신규 디바이스 등록
        await supabase.rpc('register_device', params: {
          'p_device_fingerprint': fp,
          'p_hardware_hash': null,
        });
        pointsData = await supabase
            .from('device_points')
            .select()
            .eq('device_fingerprint', fp)
            .single();
      }

      // 배당률 계산
      final bets = await supabase
          .from('prediction_bets')
          .select('option_id, bet_amount')
          .eq('prediction_id', widget.predictionId)
          .eq('status', 'pending');

      int yesTotal = 0, noTotal = 0;
      for (final bet in bets) {
        if (bet['option_id'] == 'yes') {
          yesTotal += (bet['bet_amount'] as int);
        } else {
          noTotal += (bet['bet_amount'] as int);
        }
      }
      _yesBets = bets.where((b) => b['option_id'] == 'yes').length;
      _noBets = bets.where((b) => b['option_id'] == 'no').length;

      final totalPool = (pred['total_pool'] as int?) ?? 0;
      final effectivePool = totalPool * 0.9;
      _yesOdds = yesTotal > 0
          ? (effectivePool / yesTotal).clamp(1.05, 20.0)
          : 20.0;
      _noOdds = noTotal > 0
          ? (effectivePool / noTotal).clamp(1.05, 20.0)
          : 20.0;

      // 내 베팅 기록 조회
      final myBets = await supabase
          .from('prediction_bets')
          .select()
          .eq('prediction_id', widget.predictionId)
          .eq('device_fingerprint', fp)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _prediction = pred;
          _points = DevicePoints(
            deviceFingerprint: pointsData!['device_fingerprint'],
            balance: pointsData['balance'],
            totalEarned: pointsData['total_earned'],
            totalSpent: pointsData['total_spent'],
            totalWon: pointsData['total_won'] ?? 0,
            totalLost: pointsData['total_lost'] ?? 0,
            createdAt: DateTime.parse(pointsData['created_at']),
          );
          _myBets = List<Map<String, dynamic>>.from(myBets);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[PredictionDetail] Load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onBet(String option, int amount) async {
    if (_betting || _deviceFingerprint == null) return;
    setState(() => _betting = true);

    try {
      // idempotency key 생성
      final random = List.generate(8, (_) => Random().nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      final key = '$_deviceFingerprint-${widget.predictionId}-$option-$random';

      await supabase.rpc('calculate_odds_and_place_bet', params: {
        'p_prediction_id': widget.predictionId,
        'p_device_fingerprint': _deviceFingerprint,
        'p_option_id': option,
        'p_bet_amount': amount,
        'p_idempotency_key': key,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$amount BP on ${option.toUpperCase()} ✓'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.signalGreenDark,
          ),
        );
        // 데이터 새로고침
        await _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bet failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.glitchRed,
          ),
        );
      }
    }

    if (mounted) setState(() => _betting = false);
  }

  String _formatTimeRemaining(AppLocalizations l10n) {
    final closesAt = DateTime.tryParse(_prediction?['closes_at'] ?? '') ??
        DateTime.now();
    if (closesAt.isBefore(DateTime.now())) return l10n.predictionClosed;
    final diff = closesAt.difference(DateTime.now());
    if (diff.inDays >= 1) {
      return l10n.predictionClosesIn('${diff.inDays}d ${diff.inHours % 24}h');
    }
    if (diff.inHours >= 1) {
      return l10n.predictionClosesIn('${diff.inHours}h ${diff.inMinutes % 60}m');
    }
    return l10n.predictionClosesIn('${diff.inMinutes}m');
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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_prediction == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Prediction not found')),
      );
    }

    final question = _prediction!['question'] as String? ?? '';
    final categoryStr = _prediction!['category'] as String? ?? 'other';
    final category = PredictionCategory.values.firstWhere(
      (e) => e.name == categoryStr,
      orElse: () => PredictionCategory.other,
    );
    final totalPool = (_prediction!['total_pool'] as int?) ?? 0;
    final status = _prediction!['status'] as String? ?? 'active';
    final closesAt = DateTime.tryParse(_prediction!['closes_at'] ?? '') ??
        DateTime.now();
    final isExpired = status != 'active' || closesAt.isBefore(DateTime.now());
    final isSettled = status == 'settled';
    final correctAnswer = _prediction!['correct_answer'] as String?;
    final participants = _yesBets + _noBets;

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
                      categoryLabel(category, l10n),
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: signalGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isSettled && correctAnswer != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: signalGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        correctAnswer.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: signalGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
                question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.predictionParticipants(participants),
                style: TextStyle(fontSize: 13, color: ghostGrey),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalPool BP pool',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: signalGreen,
                ),
              ),
              const SizedBox(height: 28),

              // 배당률 카드
              _buildOddsSection(l10n, signalGreen, borderColor, isDark),
              const SizedBox(height: 20),

              // 배팅 분포 바
              _buildDistributionBar(signalGreen, isDark),
              const SizedBox(height: 28),

              // 내 베팅 내역
              if (_myBets.isNotEmpty) ...[
                Text(
                  'MY BETS',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: ghostGrey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                ..._myBets.map((bet) {
                  final optionId = bet['option_id'] as String? ?? '';
                  final amount = bet['bet_amount'] as int? ?? 0;
                  final odds = double.tryParse('${bet['odds_at_bet']}') ?? 0;
                  final isYes = optionId == 'yes';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: (isYes ? signalGreen : AppColors.glitchRed)
                              .withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            optionId.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isYes ? signalGreen : AppColors.glitchRed,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$amount BP',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${odds.toStringAsFixed(2)}x',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: ghostGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 20),

              // 잔액 정보
              if (_points != null)
                _buildBalanceInfo(l10n, signalGreen, ghostGrey, borderColor, isDark),

              const SizedBox(height: 16),

              // 토론방 참여 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 예측 ID 기반 그룹 채팅방 참여
                    // prediction ID를 roomId로 사용 (앞 12자)
                    final roomId = widget.predictionId.replaceAll('-', '').substring(0, 12);
                    context.push('/group/$roomId', extra: {
                      'password': widget.predictionId,
                    });
                  },
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: Text(
                    l10n.predictionDiscuss,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: signalGreen,
                    side: BorderSide(color: signalGreen.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // 베팅 버튼 (마감 전이면 항상 표시 — 추가 베팅 가능)
      bottomNavigationBar: isExpired
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _betting
                        ? null
                        : () => BettingBottomSheet.show(
                              context,
                              question: question,
                              yesOdds: _yesOdds,
                              noOdds: _noOdds,
                              points: _points!,
                              onBet: _onBet,
                            ),
                    child: _betting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.predictionBet),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOddsSection(
    AppLocalizations l10n,
    Color signalGreen,
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

  Widget _buildDistributionBar(Color signalGreen, bool isDark) {
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
                  flex: (yesFraction * 100).round().clamp(1, 99),
                  child: Container(color: signalGreen),
                ),
                Expanded(
                  flex: ((1 - yesFraction) * 100).round().clamp(1, 99),
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
              style: const TextStyle(
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
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
      ),
      child: Row(
        children: [
          Text(_points!.rankEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.predictionRank}: ${_points!.rank}',
                style: TextStyle(fontSize: 12, color: ghostGrey),
              ),
              Text(
                '${_points!.balance} BP',
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
