import 'dart:convert';

import 'package:pinenacl/x25519.dart';

import 'encrypt.dart';

/// 메시지 복호화 (web: nacl.box.open.after)
/// 변조 감지 시 null 반환
String? decryptMessage(EncryptedPayload payload, Uint8List sharedSecret) {
  try {
    final ciphertext = base64Decode(payload.ciphertext);
    final nonce = base64Decode(payload.nonce);

    final box = SecretBox(sharedSecret);
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
