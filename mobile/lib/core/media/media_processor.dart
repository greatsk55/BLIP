import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

import '../constants/app_constants.dart';

/// 미디어 타입 구분 (web: getMediaType 동일)
enum MediaType { image, video }

/// MIME 타입으로 미디어 타입 판별
MediaType? getMediaType(String mimeType) {
  if (mimeType.startsWith('image/')) return MediaType.image;
  if (mimeType.startsWith('video/')) return MediaType.video;
  return null;
}

/// 파일 크기 검증 (원본 선택 시)
bool validateFileSize(int bytes, MediaType type) {
  final maxMb = type == MediaType.image
      ? AppConstants.maxImageSizeMb
      : AppConstants.maxVideoSizeMb;
  return bytes <= maxMb * 1024 * 1024;
}

/// 이미지 압축 결과
typedef CompressedImage = ({Uint8List bytes, int width, int height});

/// 이미지 압축 (web: compressImage 동일 로직)
/// flutter_image_compress: 2048px, 80% JPEG
Future<CompressedImage> compressImage(XFile file) async {
  final bytes = await file.readAsBytes();

  final compressed = await FlutterImageCompress.compressWithList(
    Uint8List.fromList(bytes),
    minWidth: AppConstants.imageMaxDimension,
    minHeight: AppConstants.imageMaxDimension,
    quality: (AppConstants.imageQuality * 100).toInt(),
    format: CompressFormat.jpeg,
  );

  // 압축된 이미지의 실제 크기 추출
  final codec = await ui.instantiateImageCodec(compressed);
  final frame = await codec.getNextFrame();
  final width = frame.image.width;
  final height = frame.image.height;
  frame.image.dispose();

  return (bytes: compressed, width: width, height: height);
}

/// 동영상 압축 결과
typedef CompressedVideo = ({
  Uint8List bytes,
  int width,
  int height,
  double duration,
});

/// 동영상 압축 (720p MediumQuality)
/// 60초 초과 시 예외 발생
Future<CompressedVideo> compressVideo(XFile file) async {
  // 길이 검증
  final info = await VideoCompress.getMediaInfo(file.path);
  final durationSec = (info.duration ?? 0) / 1000;
  if (durationSec > AppConstants.maxVideoDurationSec) {
    throw VideoTooLongException(durationSec);
  }

  final result = await VideoCompress.compressVideo(
    file.path,
    quality: VideoQuality.MediumQuality,
    includeAudio: true,
  );

  if (result == null || result.file == null) {
    throw Exception('Video compression failed');
  }

  final compressed = await result.file!.readAsBytes();

  // 압축 후 크기 검증
  if (compressed.length > AppConstants.maxVideoCompressedMb * 1024 * 1024) {
    throw VideoTooLargeException(compressed.length);
  }

  return (
    bytes: Uint8List.fromList(compressed),
    width: result.width?.toInt() ?? 0,
    height: result.height?.toInt() ?? 0,
    duration: durationSec,
  );
}

/// 동영상 썸네일 생성 (로컬 미리보기용, 서버 업로드 안 함)
Future<Uint8List?> generateVideoThumbnail(String filePath) async {
  try {
    final thumb = await VideoCompress.getByteThumbnail(
      filePath,
      quality: (AppConstants.thumbnailQuality * 100).toInt(),
      position: 500, // 0.5초 지점 (web과 동일)
    );
    return thumb;
  } catch (_) {
    return null;
  }
}

/// 동영상 압축 캐시 정리
Future<void> clearVideoCompressCache() async {
  await VideoCompress.deleteAllCache();
}

/// 동영상 길이 초과 예외
class VideoTooLongException implements Exception {
  final double durationSec;
  VideoTooLongException(this.durationSec);

  @override
  String toString() =>
      'Video too long: ${durationSec.toStringAsFixed(0)}s (max ${AppConstants.maxVideoDurationSec}s)';
}

/// 동영상 크기 초과 예외
class VideoTooLargeException implements Exception {
  final int sizeBytes;
  VideoTooLargeException(this.sizeBytes);

  @override
  String toString() =>
      'Video too large: ${(sizeBytes / 1024 / 1024).toStringAsFixed(1)}MB (max ${AppConstants.maxVideoCompressedMb}MB)';
}
