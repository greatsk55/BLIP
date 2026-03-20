/// 채팅방 타입
enum RoomType { chat, group }

/// 로컬 저장된 채팅방 정보
class SavedRoom {
  final String roomId;
  final RoomType roomType;
  final bool isCreator;
  final bool isAdmin;
  final String? peerUsername;
  final String? title; // 그룹 채팅 제목
  final int createdAt;
  final int lastAccessedAt;
  final String status; // 'active' | 'destroyed' | 'expired'

  const SavedRoom({
    required this.roomId,
    this.roomType = RoomType.chat,
    required this.isCreator,
    this.isAdmin = false,
    this.peerUsername,
    this.title,
    required this.createdAt,
    required this.lastAccessedAt,
    this.status = 'active',
  });

  SavedRoom copyWith({
    String? peerUsername,
    String? title,
    int? lastAccessedAt,
    String? status,
  }) {
    return SavedRoom(
      roomId: roomId,
      roomType: roomType,
      isCreator: isCreator,
      isAdmin: isAdmin,
      peerUsername: peerUsername ?? this.peerUsername,
      title: title ?? this.title,
      createdAt: createdAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomId': roomId,
        'roomType': roomType.name,
        'isCreator': isCreator,
        'isAdmin': isAdmin,
        'peerUsername': peerUsername,
        'title': title,
        'createdAt': createdAt,
        'lastAccessedAt': lastAccessedAt,
        'status': status,
      };

  factory SavedRoom.fromJson(Map<String, dynamic> json) => SavedRoom(
        roomId: json['roomId'] as String,
        roomType: json['roomType'] == 'group' ? RoomType.group : RoomType.chat,
        isCreator: json['isCreator'] as bool? ?? false,
        isAdmin: json['isAdmin'] as bool? ?? false,
        peerUsername: json['peerUsername'] as String?,
        title: json['title'] as String?,
        createdAt: json['createdAt'] as int,
        lastAccessedAt: json['lastAccessedAt'] as int,
        status: json['status'] as String? ?? 'active',
      );
}
