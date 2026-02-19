import 'dart:typed_data';

/// 메시지 유형 (web: MessageType)
enum MessageType { text, image, video }

/// 미디어 메타데이터 (web: MediaMetadata)
class MediaMetadata {
  final String fileName;
  final String mimeType;
  final int size;
  final int? width;
  final int? height;
  final double? duration;

  const MediaMetadata({
    required this.fileName,
    required this.mimeType,
    required this.size,
    this.width,
    this.height,
    this.duration,
  });
}

/// 복호화된 메시지 (web: DecryptedMessage)
class DecryptedMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final int timestamp;
  final bool isMine;
  final MessageType type;
  final Uint8List? mediaBytes;
  final Uint8List? mediaThumbnailBytes;
  final MediaMetadata? mediaMetadata;
  final double? transferProgress;

  const DecryptedMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.isMine,
    this.type = MessageType.text,
    this.mediaBytes,
    this.mediaThumbnailBytes,
    this.mediaMetadata,
    this.transferProgress,
  });

  DecryptedMessage copyWith({
    double? transferProgress,
    Uint8List? mediaBytes,
    Uint8List? mediaThumbnailBytes,
  }) {
    return DecryptedMessage(
      id: id,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: timestamp,
      isMine: isMine,
      type: type,
      mediaBytes: mediaBytes ?? this.mediaBytes,
      mediaThumbnailBytes: mediaThumbnailBytes ?? this.mediaThumbnailBytes,
      mediaMetadata: mediaMetadata,
      transferProgress: transferProgress ?? this.transferProgress,
    );
  }
}

/// 파일 전송 헤더 (web: FileTransferHeader)
class FileTransferHeader {
  final String transferId;
  final String fileName;
  final String mimeType;
  final int totalSize;
  final int totalChunks;
  final String checksum;

  const FileTransferHeader({
    required this.transferId,
    required this.fileName,
    required this.mimeType,
    required this.totalSize,
    required this.totalChunks,
    required this.checksum,
  });

  Map<String, dynamic> toJson() => {
        'transferId': transferId,
        'fileName': fileName,
        'mimeType': mimeType,
        'totalSize': totalSize,
        'totalChunks': totalChunks,
        'checksum': checksum,
      };

  factory FileTransferHeader.fromJson(Map<String, dynamic> json) =>
      FileTransferHeader(
        transferId: json['transferId'] as String,
        fileName: json['fileName'] as String,
        mimeType: json['mimeType'] as String,
        totalSize: json['totalSize'] as int,
        totalChunks: json['totalChunks'] as int,
        checksum: json['checksum'] as String,
      );
}
