import 'dart:convert';

import 'package:pinenacl/x25519.dart';

import 'encrypt.dart';

/// 대칭키 암호화 (web: nacl.secretbox)
/// 게시판 등 N:N 공유 환경용
/// pinenacl SecretBox는 crypto_box_afternm 사용 → nacl.secretbox과 동일 구현
EncryptedPayload encryptSymmetric(String plaintext, Uint8List symmetricKey) {
  final box = SecretBox(symmetricKey);
  final encrypted = box.encrypt(Uint8List.fromList(utf8.encode(plaintext)));

  return EncryptedPayload(
    ciphertext: base64Encode(Uint8List.fromList(encrypted.cipherText)),
    nonce: base64Encode(Uint8List.fromList(encrypted.nonce)),
  );
}

/// 대칭키 복호화 (web: nacl.secretbox.open)
String? decryptSymmetric(EncryptedPayload payload, Uint8List symmetricKey) {
  try {
    final ciphertext = base64Decode(payload.ciphertext);
    final nonce = base64Decode(payload.nonce);

    final box = SecretBox(symmetricKey);
    final encrypted = EncryptedMessage(
      nonce: Uint8List.fromList(nonce),
      cipherText: Uint8List.fromList(ciphertext),
    );
    final plaintext = box.decrypt(encrypted);

    return utf8.decode(plaintext);
  } catch (_) {
    return null;
  }
}

/// 바이너리 대칭키 암호화 (이미지 등)
EncryptedPayload encryptBinary(Uint8List data, Uint8List symmetricKey) {
  final box = SecretBox(symmetricKey);
  final encrypted = box.encrypt(data);

  return EncryptedPayload(
    ciphertext: base64Encode(Uint8List.fromList(encrypted.cipherText)),
    nonce: base64Encode(Uint8List.fromList(encrypted.nonce)),
  );
}

/// 바이너리 대칭키 복호화 (raw Uint8List 반환)
Uint8List? decryptBinaryRaw(
  Uint8List ciphertext,
  Uint8List nonce,
  Uint8List symmetricKey,
) {
  try {
    final box = SecretBox(symmetricKey);
    final encrypted = EncryptedMessage(
      nonce: nonce,
      cipherText: ciphertext,
    );
    return Uint8List.fromList(box.decrypt(encrypted));
  } catch (_) {
    return null;
  }
}
