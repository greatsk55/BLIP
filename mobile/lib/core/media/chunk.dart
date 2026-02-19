import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../constants/app_constants.dart';

/// 데이터를 64KB 청크로 분할
List<Uint8List> splitIntoChunks(Uint8List data) {
  final chunks = <Uint8List>[];
  for (var offset = 0; offset < data.length; offset += AppConstants.chunkSize) {
    final end = (offset + AppConstants.chunkSize).clamp(0, data.length);
    chunks.add(Uint8List.fromList(data.sublist(offset, end)));
  }
  return chunks;
}

/// 청크 재조립
Uint8List reassembleChunks(Map<int, Uint8List> chunks, int totalChunks) {
  var totalLength = 0;
  for (var i = 0; i < totalChunks; i++) {
    final chunk = chunks[i];
    if (chunk == null) throw StateError('Missing chunk $i');
    totalLength += chunk.length;
  }

  final result = Uint8List(totalLength);
  var offset = 0;
  for (var i = 0; i < totalChunks; i++) {
    final chunk = chunks[i]!;
    result.setRange(offset, offset + chunk.length, chunk);
    offset += chunk.length;
  }

  return result;
}

/// SHA-256 체크섬 (hex string)
String computeChecksum(Uint8List data) {
  return sha256.convert(data).toString();
}

/// 체크섬 검증
bool verifyChecksum(Uint8List data, String expectedChecksum) {
  return computeChecksum(data) == expectedChecksum;
}
