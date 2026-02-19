import 'dart:math';

/// 방 ID 생성 (web/src/lib/room/password.ts 와 동일)
/// 8자 소문자 + 숫자
String generateRoomId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rng = Random.secure();
  return List.generate(8, (_) => chars[rng.nextInt(chars.length)]).join();
}

/// 방 비밀번호 생성 (web 동일: "XXXX-XXXX")
/// 대문자 + 숫자 4자리 - 대문자 + 숫자 4자리
String generateRoomPassword() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rng = Random.secure();
  final part1 = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  final part2 = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  return '$part1-$part2';
}
