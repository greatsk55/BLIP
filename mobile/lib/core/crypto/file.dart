import 'package:pinenacl/x25519.dart';

/// 암호화된 파일 청크
class EncryptedFileChunk {
  final Uint8List ciphertext;
  final Uint8List nonce;

  const EncryptedFileChunk({required this.ciphertext, required this.nonce});
}

/// 파일 청크 암호화 (web: nacl.box.after — 바이너리 직접 처리)
/// SecretBox는 내부적으로 crypto_box_afternm 사용 → 웹 호환
EncryptedFileChunk encryptFileChunk(Uint8List chunk, Uint8List sharedSecret) {
  final box = SecretBox(sharedSecret);
  final encrypted = box.encrypt(chunk);

  return EncryptedFileChunk(
    ciphertext: Uint8List.fromList(encrypted.cipherText),
    nonce: Uint8List.fromList(encrypted.nonce),
  );
}

/// 파일 청크 복호화
Uint8List? decryptFileChunk(
  Uint8List ciphertext,
  Uint8List nonce,
  Uint8List sharedSecret,
) {
  try {
    final box = SecretBox(sharedSecret);
    final encrypted = EncryptedMessage(
      nonce: nonce,
      cipherText: ciphertext,
    );
    return Uint8List.fromList(box.decrypt(encrypted));
  } catch (_) {
    return null;
  }
}
