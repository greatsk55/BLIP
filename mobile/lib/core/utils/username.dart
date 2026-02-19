import 'dart:math';

/// 랜덤 익명 닉네임 생성 (web/src/lib/username.ts 와 동일)
String generateUsername() {
  const adjectives = [
    'Swift', 'Silent', 'Bright', 'Dark', 'Wild',
    'Calm', 'Bold', 'Quick', 'Sharp', 'Cool',
    'Brave', 'Clever', 'Fierce', 'Free', 'Keen',
    'Mystic', 'Noble', 'Prime', 'Royal', 'Vivid',
  ];

  const nouns = [
    'Fox', 'Wolf', 'Hawk', 'Bear', 'Lion',
    'Deer', 'Eagle', 'Shark', 'Tiger', 'Lynx',
    'Crane', 'Cobra', 'Raven', 'Viper', 'Whale',
    'Falcon', 'Panther', 'Phoenix', 'Dragon', 'Ghost',
  ];

  final rng = Random.secure();
  final adj = adjectives[rng.nextInt(adjectives.length)];
  final noun = nouns[rng.nextInt(nouns.length)];
  final num = rng.nextInt(100);

  return '$adj$noun$num';
}
