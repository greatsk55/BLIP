import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/group_chat_provider.dart';
import 'group_message_bubble.dart';
import 'participant_list_sheet.dart';
import 'admin_action_dialog.dart';

/// 그룹 채팅 룸 뷰 (메시지 목록 + 입력)
class GroupChatRoomView extends ConsumerStatefulWidget {
  final String roomId;
  final String password;
  final bool isAdmin;
  final String? adminToken;

  const GroupChatRoomView({
    super.key,
    required this.roomId,
    required this.password,
    required this.isAdmin,
    this.adminToken,
  });

  @override
  ConsumerState<GroupChatRoomView> createState() => _GroupChatRoomViewState();
}

class _GroupChatRoomViewState extends ConsumerState<GroupChatRoomView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  GroupChatParams get _params => GroupChatParams(
        roomId: widget.roomId,
        password: widget.password,
        isAdmin: widget.isAdmin,
        adminToken: widget.adminToken,
      );

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

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    ref.read(groupChatNotifierProvider(_params).notifier).sendMessage(text);
    _inputController.clear();
    _scrollToBottom();
  }

  void _showParticipants() {
    final chatState = ref.read(groupChatNotifierProvider(_params));
    showModalBottomSheet(
      context: context,
      builder: (_) => ParticipantListSheet(
        participants: chatState.participants,
        myId: chatState.myId,
        isAdmin: widget.isAdmin,
        onKick: (userId) {
          ref
              .read(groupChatNotifierProvider(_params).notifier)
              .kickUser(userId);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupLeaveTitle),
        content: Text(l10n.groupLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.groupLeaveButton,
              style: const TextStyle(color: AppColors.glitchRed),
            ),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      ref.read(groupChatNotifierProvider(_params).notifier).disconnect();
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _confirmDestroy() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AdminActionDialog(
        title: l10n.groupDestroyTitle,
        message: l10n.groupDestroyConfirm,
        confirmLabel: l10n.groupDestroyButton,
      ),
    );

    if (result == true && mounted) {
      await ref
          .read(groupChatNotifierProvider(_params).notifier)
          .destroyRoom();
      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    final chatState = ref.watch(groupChatNotifierProvider(_params));

    // 메시지 변경 시 스크롤
    ref.listen(groupChatNotifierProvider(_params), (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        // ── 헤더 ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  onPressed: _confirmLeave,
                  icon: Icon(Icons.arrow_back, color: ghostGrey),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.groupChatHeader,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: signalGreen,
                        ),
                      ),
                      Text(
                        l10n.chatHeaderOnline(chatState.participants.length),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: ghostGrey.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                // 참여자 목록
                IconButton(
                  onPressed: _showParticipants,
                  icon: Icon(Icons.people_outline, color: ghostGrey),
                ),
                // 관리자: 방 폭파
                if (widget.isAdmin)
                  IconButton(
                    onPressed: _confirmDestroy,
                    icon: const Icon(Icons.delete_forever,
                        color: AppColors.glitchRed),
                  ),
              ],
            ),
          ),
        ),

        // ── E2EE badge ──
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 10, color: ghostGrey.withValues(alpha: 0.4)),
              const SizedBox(width: 4),
              Text(
                l10n.chatHeaderE2ee,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: ghostGrey.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),

        // ── 메시지 목록 ──
        Expanded(
          child: chatState.messages.isEmpty
              ? Center(
                  child: Text(
                    l10n.groupEmptyChat,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: ghostGrey.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: chatState.messages.length,
                  itemBuilder: (context, index) {
                    return GroupMessageBubble(
                      message: chatState.messages[index],
                    );
                  },
                ),
        ),

        // ── 입력 ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: l10n.chatInputPlaceholder,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    textInputAction: TextInputAction.send,
                    maxLines: 1,
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: signalGreen),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
