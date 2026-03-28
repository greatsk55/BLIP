import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_room.dart';
import '../../../core/utils/room_creator.dart';
import '../../blipme/providers/blipme_provider.dart';
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
    final blipMe = ref.watch(blipMeProvider);

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
              ? Column(
                  children: [
                    _BlipMeWidget(
                      state: blipMe,
                      l10n: l10n,
                      isDark: isDark,
                      signalGreen: signalGreen,
                      ghostGrey: ghostGrey,
                      onCreateLink: () =>
                          ref.read(blipMeProvider.notifier).createLink(),
                      onRegenerate: () =>
                          ref.read(blipMeProvider.notifier).regenerateLink(),
                    ),
                    Expanded(
                      child: _EmptyState(
                        l10n: l10n,
                        signalGreen: signalGreen,
                        ghostGrey: ghostGrey,
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  color: signalGreen,
                  onRefresh: () async {
                    ref.invalidate(blipMeProvider);
                    await ref.read(chatListProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    // +1 for BLIP me widget at index 0
                    itemCount: listState.rooms.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _BlipMeWidget(
                          state: blipMe,
                          l10n: l10n,
                          isDark: isDark,
                          signalGreen: signalGreen,
                          ghostGrey: ghostGrey,
                          onCreateLink: () =>
                              ref.read(blipMeProvider.notifier).createLink(),
                          onRegenerate: () =>
                              ref.read(blipMeProvider.notifier).regenerateLink(),
                        );
                      }
                      final room = listState.rooms[index - 1];
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

  /// + 버튼 → 만들기 / 그룹 만들기 / ID로 참여 선택
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
              leading: Icon(Icons.group_add, color: signalGreen),
              title: Text(l10n.groupCreateButton),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/group/create');
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
    final storage = LocalStorageService();
    final password = await storage.getRoomPassword(room.roomId);
    if (!context.mounted) return;

    if (room.roomType == RoomType.group) {
      // 그룹 채팅: extra로 비밀번호 + 관리자 정보 + 관리자 토큰 전달
      final adminToken = room.isAdmin
          ? await storage.getAdminToken(room.roomId)
          : null;
      if (!context.mounted) return;
      context.push('/group/${room.roomId}', extra: {
        'password': password,
        'adminToken': adminToken,
        'isAdmin': room.isAdmin,
      });
    } else {
      // 1:1 채팅: 저장된 비밀번호로 자동 입장
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
                  // 타입 아이콘 + 상태 표시등
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Icon(
                        room.roomType == RoomType.group
                            ? Icons.group
                            : Icons.chat_bubble_outline,
                        size: 28,
                        color: isActive ? signalGreen : ghostGrey,
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.black : Colors.white,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.roomType == RoomType.group
                              ? (room.title ?? 'Group ${room.roomId.substring(0, 8)}')
                              : (room.peerUsername ?? 'Room ${room.roomId.substring(0, 8)}'),
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
                          '${room.roomType == RoomType.group ? "Group" : "1:1"} · $statusText · $timeAgo',
                          style: TextStyle(
                            fontSize: 12,
                            color: ghostGrey,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (room.isAdmin)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.shield, size: 16, color: signalGreen.withValues(alpha: 0.6)),
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

/// 채팅탭 상단 BLIP me 컴팩트 위젯
class _BlipMeWidget extends StatelessWidget {
  final BlipMeState state;
  final AppLocalizations l10n;
  final bool isDark;
  final Color signalGreen;
  final Color ghostGrey;
  final VoidCallback onCreateLink;
  final VoidCallback onRegenerate;

  const _BlipMeWidget({
    required this.state,
    required this.l10n,
    required this.isDark,
    required this.signalGreen,
    required this.ghostGrey,
    required this.onCreateLink,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    // 로딩 중
    if (state.loading) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ghostGrey,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'BLIP me',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: ghostGrey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 링크 미생성 — CTA
    if (state.linkId == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Material(
          color: signalGreen.withValues(alpha: isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onCreateLink,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: signalGreen.withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, size: 20, color: signalGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.blipMeWidgetPrompt,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: ghostGrey,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: signalGreen),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      l10n.blipMeCreateButton,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: signalGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 링크 활성 — 상태 표시 + URL + 복사 + 새로고침
    final blipMeUrl = 'https://blip-blip.vercel.app/m/${state.linkId}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => context.push('/blipme'),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 라벨 + 상태 + 새로고침
                Row(
                  children: [
                    Icon(Icons.bolt, size: 16, color: signalGreen),
                    const SizedBox(width: 6),
                    Text(
                      'BLIP me',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: signalGreen,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (state.listening)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.radio_button_on,
                              size: 10, color: signalGreen),
                          const SizedBox(width: 4),
                          Text(
                            l10n.blipMeListening,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              color: signalGreen,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        l10n.blipMeOffline,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: ghostGrey.withValues(alpha: 0.5),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      '${state.useCount} ${l10n.blipMeWidgetConnections}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: ghostGrey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showRegenerateDialog(context),
                      child: Icon(Icons.refresh, size: 16, color: ghostGrey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 하단: URL + 복사
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        blipMeUrl,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: signalGreen.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: blipMeUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Copied!'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: signalGreen,
                          ),
                        );
                      },
                      child: Icon(Icons.copy, size: 16, color: ghostGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRegenerateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.blipMeRegenerate),
        content: Text(
          l10n.blipMeConfirmDelete,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: ghostGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRegenerate();
            },
            child: Text(
              l10n.blipMeRegenerate,
              style: TextStyle(
                color: signalGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
