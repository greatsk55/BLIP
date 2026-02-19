import 'dart:convert';

import 'package:crypto/crypto.dart' as hash;
import 'package:pinenacl/x25519.dart';
import 'package:pointycastle/export.dart' hide PrivateKey, PublicKey;

import '../constants/app_constants.dart';

/// ECDH 키쌍 (Curve25519)
class BlipKeyPair {
  final Uint8List publicKey;
  final Uint8List secretKey;

  const BlipKeyPair({required this.publicKey, required this.secretKey});
}

/// PBKDF2 유도 결과
class DerivedKeys {
  final Uint8List authKey;
  final Uint8List encryptionSeed;

  const DerivedKeys({required this.authKey, required this.encryptionSeed});

  /// authKey/encryptionSeed 메모리 제로화
  void dispose() {
    authKey.fillRange(0, authKey.length, 0);
    encryptionSeed.fillRange(0, encryptionSeed.length, 0);
  }
}

/// ECDH 키쌍 생성 (web: nacl.box.keyPair)
BlipKeyPair generateKeyPair() {
  final pk = PrivateKey.generate();
  return BlipKeyPair(
    publicKey: Uint8List.fromList(pk.publicKey),
    secretKey: Uint8List.fromList(pk),
  );
}

/// ECDH 공유 비밀 계산 (web: nacl.box.before)
/// pinenacl Box 생성 시 내부적으로 crypto_box_beforenm 호출
Uint8List computeSharedSecret(
    Uint8List theirPublicKey, Uint8List mySecretKey) {
  final box = Box(
    myPrivateKey: PrivateKey(mySecretKey),
    theirPublicKey: PublicKey(theirPublicKey),
  );
  return Uint8List.fromList(box.sharedKey);
}

/// 비밀번호에서 이중 키 유도 (PBKDF2)
/// web: crypto.subtle.deriveBits(PBKDF2, SHA-256, 100000, 512)
/// salt: 'blip-room-{roomId}' (UTF-8)
DerivedKeys deriveKeysFromPassword(String password, String roomId) {
  final salt = utf8.encode('${AppConstants.pbkdf2SaltPrefix}$roomId');
  final passwordBytes = utf8.encode(password);

  final derivator = KeyDerivator('SHA-256/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(
      Uint8List.fromList(salt),
      AppConstants.pbkdf2Iterations,
      AppConstants.pbkdf2OutputBytes,
    ));

  final derived = derivator.process(Uint8List.fromList(passwordBytes));

  return DerivedKeys(
    authKey: Uint8List.fromList(derived.sublist(0, 32)),
    encryptionSeed: Uint8List.fromList(derived.sublist(32, 64)),
  );
}

/// authKey → SHA-256 → Base64 (서버 검증용)
/// web: crypto.subtle.digest('SHA-256', authKey) → encodeBase64
String hashAuthKey(Uint8List authKey) {
  final digest = hash.sha256.convert(authKey);
  return base64Encode(Uint8List.fromList(digest.bytes));
}

/// 공개키 → Base64 문자열
String publicKeyToString(Uint8List publicKey) {
  return base64Encode(publicKey);
}

/// Base64 문자열 → 공개키
Uint8List stringToPublicKey(String str) {
  return base64Decode(str);
}
