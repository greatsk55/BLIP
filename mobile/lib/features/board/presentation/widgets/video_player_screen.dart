import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';

/// 동영상 풀스크린 플레이어
/// 복호화된 bytes → 임시파일 → VideoPlayerController.file
class VideoPlayerScreen extends StatefulWidget {
  final Uint8List videoBytes;
  final String? title;

  const VideoPlayerScreen({
    super.key,
    required this.videoBytes,
    this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  File? _tempFile;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // 복호화된 바이트 → 임시파일
      final tempDir = await getTemporaryDirectory();
      final fileName = 'blip_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      _tempFile = File('${tempDir.path}/$fileName');
      await _tempFile!.writeAsBytes(widget.videoBytes);

      _controller = VideoPlayerController.file(_tempFile!);
      await _controller!.initialize();
      await _controller!.play();

      if (mounted) {
        setState(() => _initialized = true);
      }

      _controller!.addListener(_onPlayerUpdate);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    // 임시파일 정리
    _tempFile?.delete().catchError((_) => _tempFile!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: widget.title != null
            ? Text(
                widget.title!,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              )
            : null,
      ),
      body: _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.glitchRed),
              ),
            )
          : !_initialized
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _buildPlayer(isDark),
    );
  }

  Widget _buildPlayer(bool isDark) {
    final controller = _controller!;
    final position = controller.value.position;
    final duration = controller.value.duration;

    return Column(
      children: [
        // 동영상
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
        ),

        // 컨트롤
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewPadding.bottom + 16,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 시크바
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  activeTrackColor: AppColors.signalGreenDark,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.signalGreenDark,
                  overlayColor: AppColors.signalGreenDark.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0,
                  onChanged: (value) {
                    controller.seekTo(Duration(
                      milliseconds: (value * duration.inMilliseconds).toInt(),
                    ));
                  },
                ),
              ),

              // 시간 + 재생/일시정지
              Row(
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),

                  // 재생/일시정지
                  IconButton(
                    onPressed: () {
                      controller.value.isPlaying
                          ? controller.pause()
                          : controller.play();
                    },
                    icon: Icon(
                      controller.value.isPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const Spacer(),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
