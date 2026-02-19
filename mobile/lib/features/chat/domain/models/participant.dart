/// 채팅 참여자 (web: Participant)
class Participant {
  final String id;
  final String username;
  final String publicKey;
  final int joinedAt;

  const Participant({
    required this.id,
    required this.username,
    required this.publicKey,
    required this.joinedAt,
  });

  factory Participant.fromPresence(Map<String, dynamic> data) => Participant(
        id: data['userId'] as String,
        username: data['username'] as String,
        publicKey: data['publicKey'] as String? ?? '',
        joinedAt: data['joinedAt'] as int? ?? 0,
      );
}
