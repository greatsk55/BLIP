/// 로컬 저장된 커뮤니티 보드 정보
class SavedBoard {
  final String boardId;
  final String boardName; // 복호화된 이름 (로컬 캐시)
  final int joinedAt;
  final int lastAccessedAt;
  final String status; // 'active' | 'destroyed'

  const SavedBoard({
    required this.boardId,
    required this.boardName,
    required this.joinedAt,
    required this.lastAccessedAt,
    this.status = 'active',
  });

  SavedBoard copyWith({
    String? boardName,
    int? lastAccessedAt,
    String? status,
  }) {
    return SavedBoard(
      boardId: boardId,
      boardName: boardName ?? this.boardName,
      joinedAt: joinedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'boardId': boardId,
        'boardName': boardName,
        'joinedAt': joinedAt,
        'lastAccessedAt': lastAccessedAt,
        'status': status,
      };

  factory SavedBoard.fromJson(Map<String, dynamic> json) => SavedBoard(
        boardId: json['boardId'] as String,
        boardName: json['boardName'] as String? ?? '',
        joinedAt: json['joinedAt'] as int,
        lastAccessedAt: json['lastAccessedAt'] as int,
        status: json['status'] as String? ?? 'active',
      );
}
