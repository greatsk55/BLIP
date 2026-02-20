/// BLIP 앱 상수 (SSOT)
/// web 프로젝트와 동일한 값 유지
class AppConstants {
  AppConstants._();

  // ─── WebRTC 바이너리 프로토콜 ───
  static const int packetHeader = 0x01;
  static const int packetChunk = 0x02;
  static const int packetDone = 0x03;
  static const int packetCancel = 0x05;
  static const int transferIdSize = 36; // UUID (하이픈 포함)
  static const int chunkSize = 64 * 1024; // 64KB (Safari 안전)
  static const int windowSize = 16; // 흐름 제어 윈도우

  // ─── PBKDF2 ───
  static const int pbkdf2Iterations = 100000;
  static const int pbkdf2OutputBytes = 64; // 512 bits
  static const String pbkdf2SaltPrefix = 'blip-room-';

  // ─── 미디어 ───
  static const int maxImageSizeMb = 50;
  static const int maxVideoSizeMb = 100;
  static const int imageMaxDimension = 2048;
  static const double imageQuality = 0.8;
  static const int thumbnailMaxDimension = 320;
  static const double thumbnailQuality = 0.6;
  static const int maxMediaPerPost = 4;
  static const int maxVideoCompressedMb = 40; // 압축 후 암호화 전
  static const int maxVideoDurationSec = 60;

  // ─── 방 ───
  static const int maxParticipants = 2; // 1:1 채팅

  // ─── Supabase Realtime ───
  static const int eventsPerSecond = 10;

  // ─── AdMob ───
  static const String admobBannerAndroid =
      'ca-app-pub-2005178297837902/5096661695';
  static const String admobBannerIos =
      'ca-app-pub-2005178297837902/3028901557';
  // 전면광고
  static const String admobInterstitialAndroid =
      'ca-app-pub-2005178297837902/4595357994';
  static const String admobInterstitialIos =
      'ca-app-pub-2005178297837902/1704211599';
  // 전면광고 표시 빈도 (N번에 1번)
  static const int interstitialFrequency = 3;
  // 오프닝(앱 오픈) 광고
  static const String admobAppOpenAndroid =
      'ca-app-pub-2005178297837902/1063307095';
  static const String admobAppOpenIos =
      'ca-app-pub-2005178297837902/6350033614';
}
