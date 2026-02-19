import 'dart:convert';

import 'package:pinenacl/x25519.dart';

/// 암호화된 메시지 페이로드
class EncryptedPayload {
  final String ciphertext; // Base64
  final String nonce; // Base64

  const EncryptedPayload({required this.ciphertext, required this.nonce});

  Map<String, String> toJson() => {
        'ciphertext': ciphertext,
        'nonce': nonce,
      };

  factory EncryptedPayload.fromJson(Map<String, dynamic> json) =>
      EncryptedPayload(
        ciphertext: (json['ciphertext'] as String?) ?? '',
        nonce: (json['nonce'] as String?) ?? '',
      );
}

/// 메시지 암호화 (web: nacl.box.after)
/// pinenacl SecretBox는 내부적으로 crypto_box_afternm 사용 → 웹 호환
EncryptedPayload encryptMessage(String plaintext, Uint8List sharedSecret) {
  final box = SecretBox(sharedSecret);
  final encrypted = box.encrypt(Uint8List.fromList(utf8.encode(plaintext)));

  return EncryptedPayload(
    ciphertext: base64Encode(Uint8List.fromList(encrypted.cipherText)),
    nonce: base64Encode(Uint8List.fromList(encrypted.nonce)),
  );
}
