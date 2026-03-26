/// 베팅 상태
enum BetStatus { pending, won, lost, refunded }

/// 예측 베팅 모델
class PredictionBet {
  final String id;
  final String predictionId;
  final String deviceFingerprint;
  final String optionId;
  final int betAmount;
  final double oddsAtBet;
  final BetStatus status;
  final int? payout;
  final DateTime createdAt;
  final DateTime? settledAt;

  const PredictionBet({
    required this.id,
    required this.predictionId,
    required this.deviceFingerprint,
    required this.optionId,
    required this.betAmount,
    required this.oddsAtBet,
    required this.status,
    this.payout,
    required this.createdAt,
    this.settledAt,
  });

  /// 대기 중인 베팅인지
  bool get isPending => status == BetStatus.pending;

  /// 예상 수익 (소수점 버림)
  int get expectedPayout => (betAmount * oddsAtBet).floor();

  PredictionBet copyWith({
    String? id,
    String? predictionId,
    String? deviceFingerprint,
    String? optionId,
    int? betAmount,
    double? oddsAtBet,
    BetStatus? status,
    int? payout,
    DateTime? createdAt,
    DateTime? settledAt,
  }) {
    return PredictionBet(
      id: id ?? this.id,
      predictionId: predictionId ?? this.predictionId,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      optionId: optionId ?? this.optionId,
      betAmount: betAmount ?? this.betAmount,
      oddsAtBet: oddsAtBet ?? this.oddsAtBet,
      status: status ?? this.status,
      payout: payout ?? this.payout,
      createdAt: createdAt ?? this.createdAt,
      settledAt: settledAt ?? this.settledAt,
    );
  }

  factory PredictionBet.fromJson(Map<String, dynamic> json) {
    return PredictionBet(
      id: json['id'] as String,
      predictionId: json['prediction_id'] as String,
      deviceFingerprint: json['device_fingerprint'] as String,
      optionId: json['option_id'] as String,
      betAmount: json['bet_amount'] as int,
      oddsAtBet: (json['odds_at_bet'] as num).toDouble(),
      status: BetStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
      ),
      payout: json['payout'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      settledAt: json['settled_at'] != null
          ? DateTime.parse(json['settled_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prediction_id': predictionId,
      'device_fingerprint': deviceFingerprint,
      'option_id': optionId,
      'bet_amount': betAmount,
      'odds_at_bet': oddsAtBet,
      'status': status.name,
      'payout': payout,
      'created_at': createdAt.toIso8601String(),
      'settled_at': settledAt?.toIso8601String(),
    };
  }
}
