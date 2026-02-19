/// 로컬 저장된 채팅방 정보
class SavedRoom {
  final String roomId;
  final bool isCreator;
  final String? peerUsername;
  final int createdAt;
  final int lastAccessedAt;
  final String status; // 'active' | 'destroyed' | 'expired'

  const SavedRoom({
    required this.roomId,
    required this.isCreator,
    this.peerUsername,
    required this.createdAt,
    required this.lastAccessedAt,
    this.status = 'active',
  });

  SavedRoom copyWith({
    String? peerUsername,
    int? lastAccessedAt,
    String? status,
  }) {
    return SavedRoom(
      roomId: roomId,
      isCreator: isCreator,
      peerUsername: peerUsername ?? this.peerUsername,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'isCreator': isCreator,
        'peerUsername': peerUsername,
        'createdAt': createdAt,
        'lastAccessedAt': lastAccessedAt,
        'status': status,
      };

  factory SavedRoom.fromJson(Map<String, dynamic> json) => SavedRoom(
        roomId: json['roomId'] as String,
        isCreator: json['isCreator'] as bool? ?? false,
        peerUsername: json['peerUsername'] as String?,
        createdAt: json['createdAt'] as int,
        lastAccessedAt: json['lastAccessedAt'] as int,
        status: json['status'] as String? ?? 'active',
      );
}
