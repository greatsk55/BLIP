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

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'timestamp': timestamp,
  };

  factory GroupMessage.fromJson(Map<String, dynamic> json, {String? myId}) {
    return GroupMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: json['timestamp'] as int? ?? 0,
      isMine: json['senderId'] == myId,
    );
  }
}
