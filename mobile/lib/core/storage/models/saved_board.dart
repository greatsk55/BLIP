/// 로컬 저장된 커뮤니티 보드 정보
class SavedBoard {
  final String boardId;
  final String boardName; // 복호화된 이름 (로컬 캐시)
  final String boardSubtitle; // 복호화된 부제목 (로컬 캐시, 옵셔널)
  final int joinedAt;
  final int lastAccessedAt;
  final String status; // 'active' | 'destroyed'

  const SavedBoard({
    required this.boardId,
    required this.boardName,
    this.boardSubtitle = '',
    required this.joinedAt,
    required this.lastAccessedAt,
    this.status = 'active',
  });

  SavedBoard copyWith({
    String? boardName,
    String? boardSubtitle,
    int? lastAccessedAt,
    String? status,
  }) {
    return SavedBoard(
      boardId: boardId,
      boardName: boardName ?? this.boardName,
      boardSubtitle: boardSubtitle ?? this.boardSubtitle,
      joinedAt: joinedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'boardId': boardId,
        'boardName': boardName,
        'boardSubtitle': boardSubtitle,
        'joinedAt': joinedAt,
        'lastAccessedAt': lastAccessedAt,
        'status': status,
      };

  factory SavedBoard.fromJson(Map<String, dynamic> json) => SavedBoard(
        boardId: json['boardId'] as String,
        boardName: json['boardName'] as String? ?? '',
        boardSubtitle: json['boardSubtitle'] as String? ?? '',
        joinedAt: json['joinedAt'] as int,
        lastAccessedAt: json['lastAccessedAt'] as int,
        status: json['status'] as String? ?? 'active',
      );
}
