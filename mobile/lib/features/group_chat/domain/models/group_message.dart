/// 그룹 채팅 메시지 (복호화된 상태)
class GroupMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final int timestamp;
  final bool isMine;

  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMine,
  });
}
