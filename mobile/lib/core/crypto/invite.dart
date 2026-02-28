import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as hash;
import 'package:pinenacl/x25519.dart';
import 'package:pointycastle/export.dart' hide PrivateKey, PublicKey;

/// 초대 코드 생성 (web: generateInviteCode)
/// 형식: XXXX-XXXX-XXXX (12자, 영숫자 대문자)
String generateInviteCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 0,1,I,O 제외
  final random = Random.secure();
  final segments = <String>[];

  for (var s = 0; s < 3; s++) {
    final buf = StringBuffer();
    for (var i = 0; i < 4; i++) {
      buf.write(chars[random.nextInt(chars.length)]);
    }
    segments.add(buf.toString());
  }

  return segments.join('-');
}

/// 초대 코드에서 wrapping key 유도 (PBKDF2)
/// web: deriveWrappingKey (salt='blip-invite-{boardId}')
Uint8List deriveWrappingKey(String inviteCode, String boardId) {
  final salt = utf8.encode('blip-invite-$boardId');
  final codeBytes = utf8.encode(inviteCode.toUpperCase());

  final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(
      Uint8List.fromList(salt),
      100000, // iterations (web과 동일)
      32, // 256 bits = nacl.secretbox key size
    ));

  return derivator.process(Uint8List.fromList(codeBytes));
}

/// encryptionSeed를 wrapping key로 감싸기 (nacl.secretbox)
/// web: wrapEncryptionKey
({String ciphertext, String nonce}) wrapEncryptionKey(
  Uint8List encryptionSeed,
  Uint8List wrappingKey,
) {
  final box = SecretBox(wrappingKey);
  final encrypted = box.encrypt(encryptionSeed);

  return (
    ciphertext: base64Encode(Uint8List.fromList(encrypted.cipherText)),
    nonce: base64Encode(Uint8List.fromList(encrypted.nonce)),
  );
}

/// wrapped key 복호화 (nacl.secretbox.open)
/// web: unwrapEncryptionKey
Uint8List? unwrapEncryptionKey(
  String wrappedCiphertext,
  String wrappedNonce,
  Uint8List wrappingKey,
) {
  try {
    final ciphertext = base64Decode(wrappedCiphertext);
    final nonce = base64Decode(wrappedNonce);

    final box = SecretBox(wrappingKey);
    final encrypted = EncryptedMessage(
      nonce: Uint8List.fromList(nonce),
      cipherText: Uint8List.fromList(ciphertext),
    );
    return Uint8List.fromList(box.decrypt(encrypted));
  } catch (_) {
    return null;
  }
}

/// encryptionSeed 인증용 해시 (SHA-256)
/// web: hashEncryptionKeyForAuth
/// 형식: SHA-256('blip-board-eauth:' + base64(seed))
String hashEncryptionKeyForAuth(Uint8List encryptionSeed) {
  final input = 'blip-board-eauth:${base64Encode(encryptionSeed)}';
  final digest = hash.sha256.convert(utf8.encode(input));
  return base64Encode(Uint8List.fromList(digest.bytes));
}

/// 초대 코드 해시 (SHA-256)
/// web: hashInviteCode
String hashInviteCode(String inviteCode) {
  final digest = hash.sha256.convert(utf8.encode(inviteCode.toUpperCase()));
  return base64Encode(Uint8List.fromList(digest.bytes));
}
