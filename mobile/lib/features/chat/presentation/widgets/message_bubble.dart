import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/message.dart';

/// 메시지 버블 위젯
class MessageBubble extends StatelessWidget {
  final DecryptedMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 시스템 메시지
    if (message.senderId == 'system') {
      return _SystemMessage(message: message, isDark: isDark);
    }

    // 내 메시지 vs 상대방 메시지
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMine
              ? (isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight)
                  .withValues(alpha: 0.15)
              : isDark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isMine ? 16 : 4),
            bottomRight: Radius.circular(message.isMine ? 4 : 16),
          ),
          border: Border.all(
            color: message.isMine
                ? (isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight)
                    .withValues(alpha: 0.3)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Column(
          crossAxisAlignment: message.isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // 발신자 이름 (상대방만)
            if (!message.isMine)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.signalGreenDark
                        : AppColors.signalGreenLight,
                  ),
                ),
              ),

            // 미디어 전송 진행률
            if (message.transferProgress != null &&
                message.transferProgress! < 1.0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(
                  value: message.transferProgress,
                  backgroundColor: (isDark
                          ? AppColors.ghostGreyDark
                          : AppColors.ghostGreyLight)
                      .withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(
                    isDark
                        ? AppColors.signalGreenDark
                        : AppColors.signalGreenLight,
                  ),
                ),
              ),

            // 미디어 이미지 (탭 → 풀스크린 확대)
            if (message.type == MessageType.image &&
                message.mediaBytes != null)
              GestureDetector(
                onTap: () => _openFullScreenImage(context, message.mediaBytes!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    message.mediaBytes!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // 미디어 동영상 (썸네일 + 재생 버튼 → 탭 시 풀스크린 재생)
            if (message.type == MessageType.video &&
                message.mediaBytes != null)
              _VideoThumbnail(message: message),

            // 텍스트 내용 (미디어 메시지일 때는 파일명 숨김)
            if (message.content.isNotEmpty &&
                message.type == MessageType.text)
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),

            // 타임스탬프
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.ghostGreyDark
                      : AppColors.ghostGreyLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => _FullScreenImageViewer(bytes: bytes),
      ),
    );
  }

  String _formatTime(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// 동영상 썸네일 (첫 프레임 + 재생 오버레이 → 탭 시 풀스크린 재생)
class _VideoThumbnail extends StatelessWidget {
  final DecryptedMessage message;

  const _VideoThumbnail({required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(context, message.mediaBytes!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 썸네일이 있으면 표시, 없으면 검정 배경
            if (message.mediaThumbnailBytes != null)
              Image.memory(
                message.mediaThumbnailBytes!,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            else
              Container(
                width: double.infinity,
                height: 160,
                color: Colors.black87,
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white38,
                  size: 40,
                ),
              ),
            // 재생 버튼 오버레이
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openVideoPlayer(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(videoBytes: bytes),
      ),
    );
  }
}

/// 풀스크린 이미지 뷰어 (핀치 줌 + 탭으로 닫기)
class _FullScreenImageViewer extends StatelessWidget {
  final Uint8List bytes;

  const _FullScreenImageViewer({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 풀스크린 동영상 플레이어 (임시 파일 → VideoPlayerController)
class _FullScreenVideoPlayer extends StatefulWidget {
  final Uint8List videoBytes;

  const _FullScreenVideoPlayer({required this.videoBytes});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  VideoPlayerController? _controller;
  File? _tempFile;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/blip_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      );
      await file.writeAsBytes(widget.videoBytes);
      _tempFile = file;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.play();

      if (mounted) {
        setState(() => _controller = controller);
      } else {
        controller.dispose();
        file.delete().ignore();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tempFile?.delete().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 동영상 or 로딩
          Center(
            child: _error
                ? const Icon(Icons.error_outline, color: Colors.white38, size: 48)
                : _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : const CircularProgressIndicator(color: Colors.white38),
          ),

          // 닫기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),

          // 재생/일시정지 컨트롤 (하단)
          if (_controller != null && _controller!.value.isInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: _VideoControls(controller: _controller!),
            ),
        ],
      ),
    );
  }
}

/// 동영상 재생 컨트롤 (재생/일시정지 + 진행바)
class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final position = value.position;
    final duration = value.duration;
    final isPlaying = value.isPlaying;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 재생/일시정지
          GestureDetector(
            onTap: () {
              isPlaying
                  ? widget.controller.pause()
                  : widget.controller.play();
            },
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 8),
          // 경과 시간
          Text(
            _formatDuration(position),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          // 진행바
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: AppColors.signalGreenDark,
                inactiveTrackColor: Colors.white24,
                thumbColor: AppColors.signalGreenDark,
              ),
              child: Slider(
                value: duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0,
                onChanged: (v) {
                  widget.controller.seekTo(
                    Duration(milliseconds: (v * duration.inMilliseconds).toInt()),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 전체 시간
          Text(
            _formatDuration(duration),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SystemMessage extends StatelessWidget {
  final DecryptedMessage message;
  final bool isDark;

  const _SystemMessage({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.signalGreenDark
                : AppColors.signalGreenLight,
          ),
        ),
      ),
    );
  }
}
