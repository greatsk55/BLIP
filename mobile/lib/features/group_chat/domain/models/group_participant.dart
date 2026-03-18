/// 그룹 채팅 참여자 (Presence 기반)
class GroupParticipant {
  final String userId;
  final String username;
  final int? joinedAt;
  final bool isAdmin;

  const GroupParticipant({
    required this.userId,
    required this.username,
    this.joinedAt,
    this.isAdmin = false,
  });
}
