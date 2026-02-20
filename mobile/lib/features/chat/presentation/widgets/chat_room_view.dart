import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/media/media_processor.dart'
    show compressImage, compressVideo, generateVideoThumbnail,
         VideoTooLongException, VideoTooLargeException;
import '../../../../core/push/push_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../providers/chat_provider.dart';
import '../../providers/webrtc_provider.dart';
import 'message_bubble.dart';
import 'leave_confirm_dialog.dart';

/// 실제 채팅 화면 (메시지 목록 + 입력)
/// ChatNotifier (Riverpod)와 연동된 E2EE 채팅 UI
class ChatRoomView extends ConsumerStatefulWidget {
  final String roomId;
  final String password;
  final VoidCallback onDestroyed;

  const ChatRoomView({
    super.key,
    required this.roomId,
    required this.password,
    required this.onDestroyed,
  });

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  bool _sendingFile = false;

  ({String roomId, String password}) get _params =>
      (roomId: widget.roomId, password: widget.password);

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    final chatState = ref.watch(chatNotifierProvider(_params));
    final webrtcState = ref.watch(webRtcNotifierProvider(_params));

    // 파쇄 감지
    if (chatState.status == ChatStatus.destroyed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onDestroyed();
      });
    }

    // 메시지 변경 시 스크롤 + 수신 알림
    // length 비교 + 마지막 메시지 ID/mediaBytes 비교 (HEADER→DONE 교체 감지)
    ref.listen(chatNotifierProvider(_params), (prev, next) {
      final lengthChanged = prev?.messages.length != next.messages.length;
      final lastChanged = prev != null &&
          next.messages.isNotEmpty &&
          prev.messages.isNotEmpty &&
          prev.messages.last.id == next.messages.last.id &&
          prev.messages.last.mediaBytes == null &&
          next.messages.last.mediaBytes != null;

      if (lengthChanged || lastChanged) {
        _scrollToBottom();
        // 새 수신 메시지 → 비프음 + 햅틱 (시스템 메시지 제외)
        if (next.messages.isNotEmpty &&
            !next.messages.last.isMine &&
            next.messages.last.senderId != 'system') {
          NotificationService.instance.notifyMessageReceived();
        }
      }
    });

    return Column(
      children: [
        // ─── Header ───
        _ChatHeader(
          isDark: isDark,
          signalGreen: signalGreen,
          peerUsername: chatState.peerUsername,
          peerConnected: chatState.peerConnected,
          l10n: l10n,
          onExit: () => _handleExit(chatState),
          onContact: () => _handleContact(l10n),
        ),

        // ─── Messages ───
        Expanded(
          child: chatState.messages.isEmpty
              ? Center(
                  child: Text(
                    l10n.chatConnected,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    return MessageBubble(message: chatState.messages[index]);
                  },
                ),
        ),

        // ─── Input ───
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 8,
            top: 8,
            bottom: 8 + MediaQuery.of(context).viewPadding.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              // Media attach (WebRTC connected일 때만 활성)
              IconButton(
                onPressed: webrtcState.status == WebRtcStatus.connected &&
                        !_sendingFile
                    ? _pickAndSendMedia
                    : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: webrtcState.status == WebRtcStatus.connected
                      ? signalGreen
                      : (isDark
                          ? AppColors.ghostGreyDark
                          : AppColors.ghostGreyLight),
                ),
              ),
              // Text input
              Expanded(
                child: TextField(
                  controller: _inputController,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: l10n.chatInputPlaceholder,
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              // Send button
              IconButton(
                onPressed: _sendMessage,
                icon: Icon(Icons.send, color: signalGreen),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    ref.read(chatNotifierProvider(_params).notifier).sendMessage(text);
    NotificationService.instance.notifyMessageSent();
  }

  Future<void> _handleContact(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.contactConfirmTitle),
        content: Text(l10n.contactConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final sent = await PushService.instance.sendContactNotification(
      roomId: widget.roomId,
      authKeyHash: '', // authKeyHash는 채팅에서는 미사용 (Room 비밀번호 기반)
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(sent ? l10n.contactSent : l10n.contactNotReady),
      ),
    );
  }

  Future<void> _handleExit(ChatState chatState) async {
    final isLast = !chatState.peerConnected;
    final confirmed = await LeaveConfirmDialog.show(context, isLastPerson: isLast);
    if (confirmed && mounted) {
      ref.read(webRtcNotifierProvider(_params).notifier).cleanup();
      ref.read(chatNotifierProvider(_params).notifier).disconnect();
    }
  }

  Future<void> _pickAndSendMedia() async {
    final l10n = AppLocalizations.of(context)!;

    final file = await _imagePicker.pickMedia();
    if (file == null || !mounted) return;

    final mimeType = file.mimeType ?? _guessMimeType(file.path);
    final isVideo = mimeType.startsWith('video');

    setState(() => _sendingFile = true);

    try {
      Uint8List sendBytes;
      String sendMimeType;
      String sendFileName;
      Uint8List? thumbnailBytes;

      if (isVideo) {
        // 동영상: 압축 (720p, 60초 제한)
        final compressed = await compressVideo(file);
        sendBytes = compressed.bytes;
        sendMimeType = 'video/mp4';
        sendFileName = file.name.replaceAll(RegExp(r'\.\w+$'), '.mp4');
        // 썸네일 생성 (원본 파일에서 추출)
        thumbnailBytes = await generateVideoThumbnail(file.path);
      } else {
        // 이미지: 압축 (2048px, 80% JPEG)
        final compressed = await compressImage(file);
        sendBytes = compressed.bytes;
        sendMimeType = 'image/jpeg';
        sendFileName = file.name;
      }

      final sizeMb = sendBytes.length / (1024 * 1024);
      final maxMb = isVideo
          ? AppConstants.maxVideoCompressedMb
          : AppConstants.maxImageSizeMb;

      if (sizeMb > maxMb) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.chatMediaFileTooLarge('${maxMb}MB'))),
          );
        }
        return;
      }

      await ref
          .read(webRtcNotifierProvider(_params).notifier)
          .sendFile(sendBytes, sendFileName, sendMimeType,
              thumbnailBytes: thumbnailBytes);
      NotificationService.instance.notifyMessageSent();
    } on VideoTooLongException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatMediaFileTooLarge(
            '${AppConstants.maxVideoDurationSec}s',
          ))),
        );
      }
    } on VideoTooLargeException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatMediaFileTooLarge(
            '${AppConstants.maxVideoCompressedMb}MB',
          ))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sendingFile = false);
    }
  }

  String _guessMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      _ => 'application/octet-stream',
    };
  }
}

/// 채팅 헤더 (E2E 뱃지 + 상대방 정보 + 연락하기 + EXIT 버튼)
class _ChatHeader extends StatelessWidget {
  final bool isDark;
  final Color signalGreen;
  final String? peerUsername;
  final bool peerConnected;
  final AppLocalizations l10n;
  final VoidCallback onExit;
  final VoidCallback? onContact;

  const _ChatHeader({
    required this.isDark,
    required this.signalGreen,
    required this.peerUsername,
    required this.peerConnected,
    required this.l10n,
    required this.onExit,
    this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // 뒤로가기 (딥링크로 진입 시 홈으로)
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_back, size: 20,
                color: isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight),
            ),
          ),
          Icon(Icons.lock, size: 16, color: signalGreen),
          const SizedBox(width: 6),
          Text(
            l10n.chatHeaderE2ee,
            style: TextStyle(color: signalGreen, fontSize: 12),
          ),
          if (peerConnected && peerUsername != null) ...[
            const SizedBox(width: 12),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: signalGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              peerUsername!,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight,
              ),
            ),
          ],
          const Spacer(),
          // 연락하기 (상대방 오프라인일 때만)
          if (!peerConnected && peerUsername != null)
            TextButton.icon(
              onPressed: onContact,
              icon: Icon(Icons.notifications_active, size: 14, color: signalGreen),
              label: Text(
                l10n.contactButton,
                style: TextStyle(color: signalGreen, fontSize: 12),
              ),
            ),
          TextButton(
            onPressed: onExit,
            child: Text(
              l10n.chatHeaderExit,
              style: const TextStyle(color: AppColors.glitchRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
