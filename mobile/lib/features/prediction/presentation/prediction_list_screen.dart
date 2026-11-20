import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/device_identity_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/models/device_points.dart';
import 'widgets/category_filter.dart';
import 'widgets/points_chip.dart';
import 'widgets/prediction_card.dart';

/// 예측 메인 화면 (3탭: All / My Bets / Created)
class PredictionListScreen extends ConsumerStatefulWidget {
  const PredictionListScreen({super.key});

  @override
  ConsumerState<PredictionListScreen> createState() =>
      _PredictionListScreenState();
}

class _PredictionListScreenState extends ConsumerState<PredictionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PredictionCategory _selectedCategory = PredictionCategory.all;

  // 공통 상태
  String? _fingerprint;
  DevicePoints? _points;

  // Tab 0: All
  List<Map<String, dynamic>> _predictions = [];
  bool _loadingAll = true;

  // Tab 1: My Bets
  List<Map<String, dynamic>> _myBets = [];
  bool _loadingBets = true;

  // Tab 2: Created
  List<Map<String, dynamic>> _myPredictions = [];
  bool _loadingCreated = true;

  // 배당 정보 캐시: predictionId -> {yes: odds, no: odds}
  final Map<String, Map<String, double>> _oddsMap = {};

  bool _initialized = false;
  bool _identityFailed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _init();
    }
  }

  @override
  void activate() {
    super.activate();
    _loadPoints();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _loadPredictions();
        break;
      case 1:
        _loadMyBets();
        break;
      case 2:
        _loadMyPredictions();
        break;
    }
    _loadPoints();
  }

  Future<void> _init() async {
    if (mounted) setState(() => _identityFailed = false);
    try {
      _fingerprint = await DeviceIdentityService.instance.getFingerprint();
      await Future.wait([
        _loadPoints(), _loadPredictions(),
        if (_tabController.index == 1) _loadMyBets(),
        if (_tabController.index == 2) _loadMyPredictions(),
      ]);
    } catch (_) {
      if (mounted) setState(() => _identityFailed = true);
    }
  }

  // ─── Fingerprint & Points ───

  Future<void> _loadPoints() async {
    if (_fingerprint == null) return;
    try {
      var data = await supabase
          .from('device_points')
          .select()
          .eq('device_fingerprint', _fingerprint!)
          .maybeSingle();

      if (data == null) {
        await supabase.rpc(
          'register_device',
          params: {
            'p_device_fingerprint': _fingerprint,
            'p_hardware_hash': null,
          },
        );
        data = await supabase
            .from('device_points')
            .select()
            .eq('device_fingerprint', _fingerprint!)
            .single();
      }

      if (mounted) {
        setState(() {
          _points = DevicePoints(
            deviceFingerprint: data!['device_fingerprint'],
            balance: data['balance'],
            totalEarned: data['total_earned'],
            totalSpent: data['total_spent'],
            totalWon: data['total_won'] ?? 0,
            totalLost: data['total_lost'] ?? 0,
            createdAt: DateTime.parse(data['created_at']),
          );
        });
      }
    } catch (e) {
      debugPrint('[Prediction] Load points error: $e');
    }
  }

  // ─── 마감 안 된 투표 우선 정렬 ───

  void _sortActiveFirst(List<Map<String, dynamic>> list) {
    final now = DateTime.now();
    list.sort((a, b) {
      final aClosesAt = DateTime.tryParse(a['closes_at'] ?? '') ?? now;
      final bClosesAt = DateTime.tryParse(b['closes_at'] ?? '') ?? now;
      final aActive =
          (a['status'] ?? 'active') == 'active' && aClosesAt.isAfter(now);
      final bActive =
          (b['status'] ?? 'active') == 'active' && bClosesAt.isAfter(now);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      final aCreated = DateTime.tryParse(a['created_at'] ?? '') ?? now;
      final bCreated = DateTime.tryParse(b['created_at'] ?? '') ?? now;
      return bCreated.compareTo(aCreated);
    });
  }

  // ─── 배당 정보 일괄 로드 ───

  Future<void> _loadOddsForPredictions(
    List<Map<String, dynamic>> predictions,
  ) async {
    if (predictions.isEmpty) return;
    final ids = predictions.map((p) => p['id'] as String).toList();
    try {
      final bets = await supabase
          .from('prediction_bets')
          .select('prediction_id, option_id, bet_amount')
          .inFilter('prediction_id', ids)
          .eq('status', 'pending');

      final betsByPrediction = <String, List<Map<String, dynamic>>>{};
      for (final bet in List<Map<String, dynamic>>.from(bets)) {
        final pid = bet['prediction_id'] as String;
        betsByPrediction.putIfAbsent(pid, () => []).add(bet);
      }

      final newOdds = <String, Map<String, double>>{};
      for (final p in predictions) {
        final pid = p['id'] as String;
        final totalPool = (p['total_pool'] as int?) ?? 0;
        final effectivePool = totalPool * 0.9;
        final pBets = betsByPrediction[pid] ?? [];
        int yesTotal = 0, noTotal = 0;
        for (final b in pBets) {
          if (b['option_id'] == 'yes') {
            yesTotal += (b['bet_amount'] as int);
          } else {
            noTotal += (b['bet_amount'] as int);
          }
        }
        newOdds[pid] = {
          'yes': yesTotal > 0
              ? (effectivePool / yesTotal).clamp(1.05, 20.0)
              : (totalPool > 0 ? 20.0 : 0.0),
          'no': noTotal > 0
              ? (effectivePool / noTotal).clamp(1.05, 20.0)
              : (totalPool > 0 ? 20.0 : 0.0),
        };
      }

      if (mounted) setState(() => _oddsMap.addAll(newOdds));
    } catch (e) {
      debugPrint('[Prediction] Load odds error: $e');
    }
  }

  // ─── Tab 0: All Predictions ───

  String get _currentLocale {
    final locale = Localizations.localeOf(context);
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}-${locale.countryCode}';
    }
    return locale.languageCode;
  }

  Future<List<Map<String, dynamic>>> _queryPredictions(
    String locale,
    String? category,
  ) async {
    var query = supabase.from('predictions').select().eq('locale', locale);
    if (category != null) {
      query = query.eq('category', category);
    }
    final data = await query
        .order('status', ascending: true)
        .order('created_at', ascending: false)
        .limit(30);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _loadPredictions() async {
    if (mounted) setState(() => _loadingAll = true);
    try {
      final locale = _currentLocale;
      final category = _selectedCategory == PredictionCategory.all
          ? null
          : _selectedCategory.name;

      var data = await _queryPredictions(locale, category);
      if (data.isEmpty && locale != 'en') {
        data = await _queryPredictions('en', category);
      }

      _sortActiveFirst(data);
      if (mounted) {
        setState(() {
          _predictions = data;
          _loadingAll = false;
        });
      }
      await _loadOddsForPredictions(data);
    } catch (e) {
      debugPrint('[Prediction] Load error: $e');
      if (mounted) setState(() => _loadingAll = false);
    }
  }

  // ─── Tab 1: My Bets ───

  Future<void> _loadMyBets() async {
    if (_fingerprint == null) return;
    if (mounted) setState(() => _loadingBets = true);
    try {
      final data = await supabase
          .from('prediction_bets')
          .select('*, predictions(question, category, status, correct_answer)')
          .eq('device_fingerprint', _fingerprint!)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myBets = List<Map<String, dynamic>>.from(data);
          _loadingBets = false;
        });
      }
    } catch (e) {
      debugPrint('[Prediction] Load bets error: $e');
      if (mounted) setState(() => _loadingBets = false);
    }
  }

  // ─── Tab 2: My Predictions ───

  Future<void> _loadMyPredictions() async {
    if (_fingerprint == null) return;
    if (mounted) setState(() => _loadingCreated = true);
    try {
      final data = await supabase
          .from('predictions')
          .select()
          .eq('creator_fingerprint', _fingerprint!)
          .order('status', ascending: true)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);
      _sortActiveFirst(list);
      if (mounted) {
        setState(() {
          _myPredictions = list;
          _loadingCreated = false;
        });
      }
      await _loadOddsForPredictions(list);
    } catch (e) {
      debugPrint('[Prediction] Load created error: $e');
      if (mounted) setState(() => _loadingCreated = false);
    }
  }

  PredictionCategory _parseCategory(String? cat) {
    if (cat == null) return PredictionCategory.other;
    return PredictionCategory.values.firstWhere(
      (e) => e.name == cat,
      orElse: () => PredictionCategory.other,
    );
  }

  // ─── Build ───

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
          if (_points != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PointsChip(points: _points!),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: signalGreen,
          labelColor: signalGreen,
          unselectedLabelColor: ghostGrey,
          labelStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.public, size: 18),
              text: l10n.predictionTabAll,
            ),
            Tab(
              icon: const Icon(Icons.history, size: 18),
              text: l10n.predictionTabMyBets,
            ),
            Tab(
              icon: const Icon(Icons.person_outline, size: 18),
              text: l10n.predictionTabCreated,
            ),
          ],
        ),
      ),
      body: _identityFailed ? Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(l10n.commonError), TextButton(onPressed: _init, child: Text(l10n.commonRetry))],
      )) : TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(ghostGrey),
          _buildMyBetsTab(ghostGrey, signalGreen),
          _buildMyPredictionsTab(ghostGrey, signalGreen),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/prediction/create');
          if (mounted) await Future.wait([_loadPoints(), _loadPredictions()]);
        },
        backgroundColor: signalGreen,
        foregroundColor: isDark ? AppColors.voidBlackDark : AppColors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ─── Tab 0 ───

  Widget _buildAllTab(Color ghostGrey) {
    return Column(
      children: [
        const SizedBox(height: 8),
        CategoryFilter(
          selected: _selectedCategory,
          onSelected: (cat) {
            setState(() => _selectedCategory = cat);
            _loadPredictions();
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingAll
              ? const Center(child: CircularProgressIndicator())
              : _predictions.isEmpty
              ? Center(
                  child: Text(
                    'No predictions yet.',
                    style: TextStyle(
                      color: ghostGrey,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await _loadPredictions();
                    await _loadPoints();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _predictions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = _predictions[index];
                      final pid = p['id'] ?? '';
                      final createdAt =
                          DateTime.tryParse(p['created_at'] ?? '') ??
                          DateTime.now();
                      final closesAt =
                          DateTime.tryParse(p['closes_at'] ?? '') ??
                          DateTime.now();
                      return PredictionCard(
                        id: pid,
                        question: p['question'] ?? '',
                        category: _parseCategory(p['category']),
                        yesOdds: _oddsMap[pid]?['yes'] ?? 0,
                        noOdds: _oddsMap[pid]?['no'] ?? 0,
                        participants: ((p['total_pool'] as int?) ?? 0) ~/ 50,
                        createdAt: createdAt,
                        closesAt: closesAt,
                        status: p['status'] ?? 'active',
                        correctAnswer: p['correct_answer'],
                        onTap: () => context.push('/prediction/${p['id']}'),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Tab 1 ───

  Widget _buildMyBetsTab(Color ghostGrey, Color signalGreen) {
    if (_loadingBets && _myBets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myBets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: ghostGrey),
            const SizedBox(height: 12),
            Text(
              'No bets yet.\nStart betting on predictions!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ghostGrey,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMyBets();
        await _loadPoints();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _myBets.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final bet = _myBets[index];
          final pred = bet['predictions'] as Map<String, dynamic>?;
          final optionId = bet['option_id'] as String? ?? '';
          final amount = bet['bet_amount'] as int? ?? 0;
          final odds = double.tryParse('${bet['odds_at_bet']}') ?? 0;
          final status = bet['status'] as String? ?? 'pending';
          final payout = bet['payout'] as int?;
          final isWon = status == 'won';
          final isLost = status == 'lost';
          final isYes = optionId == 'yes';

          return GestureDetector(
            onTap: () => context.push('/prediction/${bet['prediction_id']}'),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pred?['question'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isWon
                                ? signalGreen.withValues(alpha: 0.15)
                                : isLost
                                ? AppColors.glitchRed.withValues(alpha: 0.15)
                                : ghostGrey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isWon
                                  ? signalGreen
                                  : isLost
                                  ? AppColors.glitchRed
                                  : ghostGrey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${odds.toStringAsFixed(2)}x',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: ghostGrey,
                          ),
                        ),
                        if (payout != null) ...[
                          const Spacer(),
                          Text(
                            '${isWon ? "+" : ""}${payout - amount} BP',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isWon ? signalGreen : AppColors.glitchRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Tab 2 ───

  Widget _buildMyPredictionsTab(Color ghostGrey, Color signalGreen) {
    if (_loadingCreated && _myPredictions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPredictions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 48, color: ghostGrey),
            const SizedBox(height: 12),
            Text(
              'No predictions created yet.',
              style: TextStyle(
                color: ghostGrey,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadMyPredictions();
        await _loadPoints();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _myPredictions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final p = _myPredictions[index];
          final pid = p['id'] ?? '';
          final createdAt =
              DateTime.tryParse(p['created_at'] ?? '') ?? DateTime.now();
          final closesAt =
              DateTime.tryParse(p['closes_at'] ?? '') ?? DateTime.now();
          return PredictionCard(
            id: pid,
            question: p['question'] ?? '',
            category: _parseCategory(p['category']),
            yesOdds: _oddsMap[pid]?['yes'] ?? 0,
            noOdds: _oddsMap[pid]?['no'] ?? 0,
            participants: ((p['total_pool'] as int?) ?? 0) ~/ 50,
            createdAt: createdAt,
            closesAt: closesAt,
            status: p['status'] ?? 'active',
            correctAnswer: p['correct_answer'],
            onTap: () => context.push('/prediction/${p['id']}'),
          );
        },
      ),
    );
  }
}
