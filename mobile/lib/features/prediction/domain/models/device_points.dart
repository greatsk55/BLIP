/// 디바이스 기반 포인트 모델
/// 계정 없이 deviceFingerprint로 포인트를 관리
class DevicePoints {
  final String deviceFingerprint;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final int totalWon;
  final int totalLost;
  final DateTime? lastDailyRewardAt;
  final DateTime createdAt;

  const DevicePoints({
    required this.deviceFingerprint,
    required this.balance,
    this.totalEarned = 0,
    this.totalSpent = 0,
    this.totalWon = 0,
    this.totalLost = 0,
    this.lastDailyRewardAt,
    required this.createdAt,
  });

  /// 랭크 계산 (balance 기준)
  String get rank {
    if (balance >= 5000) return 'Oracle';
    if (balance >= 1000) return 'Control';
    if (balance >= 200) return 'Decoder';
    if (balance >= 50) return 'Signal';
    if (balance >= 5) return 'Receiver';
    return 'Static';
  }

  /// 랭크별 이모지
  String get rankEmoji {
    switch (rank) {
      case 'Oracle':
        return '\u{1F451}'; // crown
      case 'Control':
        return '\u{1F48E}'; // gem
      case 'Decoder':
        return '\u{1F525}'; // fire
      case 'Signal':
        return '\u{26A1}'; // lightning
      case 'Receiver':
        return '\u{1F331}'; // seedling
      default:
        return '\u{1F480}'; // skull
    }
  }

  /// 비용 지불 가능 여부
  bool canAfford(int cost) => balance >= cost;

  /// 방 생성 비용 (랭크별 할인)
  int get creationCost {
    switch (rank) {
      case 'Oracle':
        return 75; // 50% 할인
      case 'Control':
        return 120; // 20% 할인
      default:
        return 150; // 기본
    }
  }

  DevicePoints copyWith({
    String? deviceFingerprint,
    int? balance,
    int? totalEarned,
    int? totalSpent,
    int? totalWon,
    int? totalLost,
    DateTime? lastDailyRewardAt,
    DateTime? createdAt,
  }) {
    return DevicePoints(
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      balance: balance ?? this.balance,
      totalEarned: totalEarned ?? this.totalEarned,
      totalSpent: totalSpent ?? this.totalSpent,
      totalWon: totalWon ?? this.totalWon,
      totalLost: totalLost ?? this.totalLost,
      lastDailyRewardAt: lastDailyRewardAt ?? this.lastDailyRewardAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DevicePoints.fromJson(Map<String, dynamic> json) {
    return DevicePoints(
      deviceFingerprint: json['device_fingerprint'] as String,
      balance: json['balance'] as int,
      totalEarned: (json['total_earned'] as int?) ?? 0,
      totalSpent: (json['total_spent'] as int?) ?? 0,
      totalWon: (json['total_won'] as int?) ?? 0,
      totalLost: (json['total_lost'] as int?) ?? 0,
      lastDailyRewardAt: json['last_daily_reward_at'] != null
          ? DateTime.parse(json['last_daily_reward_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_fingerprint': deviceFingerprint,
      'balance': balance,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'total_won': totalWon,
      'total_lost': totalLost,
      'last_daily_reward_at': lastDailyRewardAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
