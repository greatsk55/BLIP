import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_room.dart';
import '../../../core/utils/room_creator.dart';
import '../../chat/presentation/widgets/terms_confirm_dialog.dart';
import '../providers/chat_list_provider.dart';

/// 내 채팅방 리스트 화면
class MyChatListScreen extends ConsumerWidget {
  const MyChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    final listState = ref.watch(chatListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chatListTitle,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!listState.loading && listState.rooms.isNotEmpty)
            IconButton(
              onPressed: () => _showAddOptions(context, l10n, signalGreen),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: listState.loading
          ? const Center(child: CircularProgressIndicator())
          : listState.rooms.isEmpty
              ? _EmptyState(
                  l10n: l10n,
                  signalGreen: signalGreen,
                  ghostGrey: ghostGrey,
                )
              : RefreshIndicator(
                  color: signalGreen,
                  onRefresh: () =>
                      ref.read(chatListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: listState.rooms.length,
                    itemBuilder: (context, index) {
                      final room = listState.rooms[index];
                      return _RoomCard(
                        room: room,
                        isDark: isDark,
                        signalGreen: signalGreen,
                        ghostGrey: ghostGrey,
                        l10n: l10n,
                        onTap: () => _openRoom(context, room),
                        onDismissed: () => ref
                            .read(chatListProvider.notifier)
                            .removeRoom(room.roomId),
                      );
                    },
                  ),
                ),
    );
  }

  /// + 버튼 → 만들기 / ID로 참여 선택
  void _showAddOptions(
      BuildContext context, AppLocalizations l10n, Color signalGreen) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.add_circle_outline, color: signalGreen),
              title: Text(l10n.chatListCreateNew),
              onTap: () async {
                Navigator.pop(ctx);
                final agreed = await TermsConfirmDialog.show(context);
                if (agreed && context.mounted) {
                  RoomCreator.createAndNavigate(context);
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.login, color: signalGreen),
              title: Text(l10n.chatListJoinById),
              onTap: () {
                Navigator.pop(ctx);
                _showJoinByIdDialog(context, l10n, signalGreen);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 룸 ID/링크 입력 다이얼로그
  static void _showJoinByIdDialog(
      BuildContext context, AppLocalizations l10n, Color signalGreen) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        void submit(String value) {
          final id = _extractRoomId(value.trim());
          if (id.isNotEmpty) {
            Navigator.pop(ctx); // 다이얼로그 context로 pop (root Navigator)
            context.push('/room/$id');
          }
        }

        return AlertDialog(
          title: Text(l10n.chatListJoinDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.chatListJoinDialogHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: submit,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => submit(controller.text),
              child: Text(
                l10n.chatListJoinDialogJoin,
                style:
                    TextStyle(color: signalGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 링크 또는 ID에서 roomId 추출
  /// "https://blip-blip.vercel.app/room/ABC123" → "ABC123"
  /// "ABC123" → "ABC123"
  static String _extractRoomId(String input) {
    final uri = Uri.tryParse(input);
    if (uri != null && uri.hasScheme && uri.pathSegments.length >= 2) {
      final idx = uri.pathSegments.indexOf('room');
      if (idx >= 0 && idx + 1 < uri.pathSegments.length) {
        return uri.pathSegments[idx + 1];
      }
    }
    return input;
  }

  Future<void> _openRoom(BuildContext context, SavedRoom room) async {
    if (room.status != 'active') return;
    // 저장된 비밀번호로 자동 입장
    final password = await LocalStorageService().getRoomPassword(room.roomId);
    if (context.mounted) {
      context.push('/room/${room.roomId}', extra: password);
    }
  }
}

/// 빈 상태
class _EmptyState extends StatefulWidget {
  final AppLocalizations l10n;
  final Color signalGreen;
  final Color ghostGrey;

  const _EmptyState({
    required this.l10n,
    required this.signalGreen,
    required this.ghostGrey,
  });

  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState> {
  bool _creating = false;

  Future<void> _createRoom() async {
    if (_creating) return;
    final agreed = await TermsConfirmDialog.show(context);
    if (!agreed || !mounted) return;
    setState(() => _creating = true);
    try {
      await RoomCreator.createAndNavigate(context);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: widget.ghostGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              widget.l10n.chatListEmpty,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: widget.ghostGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _creating ? null : _createRoom,
                icon: _creating
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.signalGreen,
                        ),
                      )
                    : Icon(Icons.add, color: widget.signalGreen),
                label: Text(widget.l10n.chatListCreateNew),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => MyChatListScreen._showJoinByIdDialog(
                    context, widget.l10n, widget.signalGreen),
                icon: Icon(Icons.login, color: widget.signalGreen),
                label: Text(widget.l10n.chatListJoinById),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 방 카드
class _RoomCard extends StatelessWidget {
  final SavedRoom room;
  final bool isDark;
  final Color signalGreen;
  final Color ghostGrey;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _RoomCard({
    required this.room,
    required this.isDark,
    required this.signalGreen,
    required this.ghostGrey,
    required this.l10n,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = room.status == 'active';
    final isDestroyed = room.status == 'destroyed';

    final statusColor = isActive
        ? signalGreen
        : isDestroyed
            ? AppColors.glitchRed
            : ghostGrey;

    final statusText = isActive
        ? l10n.chatListStatusActive
        : isDestroyed
            ? l10n.chatListStatusDestroyed
            : l10n.chatListStatusExpired;

    final timeAgo = _formatTimeAgo(room.lastAccessedAt, l10n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(room.roomId),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.glitchRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outline, color: AppColors.glitchRed),
        ),
        child: Material(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: isActive ? onTap : null,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 상태 표시등
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.peerUsername ?? 'Room ${room.roomId.substring(0, 8)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isActive ? null : ghostGrey,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$statusText · $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: ghostGrey,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: ghostGrey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(int timestampMs, AppLocalizations l10n) {
    final diff = DateTime.now().millisecondsSinceEpoch - timestampMs;
    final minutes = diff ~/ 60000;
    if (minutes < 1) return 'now';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    return '${days}d';
  }
}
