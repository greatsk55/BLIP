import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/models/saved_board.dart';
import '../providers/community_list_provider.dart';

/// 내 커뮤니티 리스트 화면
class MyCommunityListScreen extends ConsumerWidget {
  const MyCommunityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    final listState = ref.watch(communityListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.communityListTitle,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          // 리스트가 있을 때만 + 버튼 표시
          if (!listState.loading && listState.boards.isNotEmpty)
            IconButton(
              onPressed: () => _showAddOptions(context, l10n, signalGreen),
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: listState.loading
          ? const Center(child: CircularProgressIndicator())
          : listState.boards.isEmpty
              ? _EmptyState(
                  l10n: l10n,
                  signalGreen: signalGreen,
                  ghostGrey: ghostGrey,
                )
              : RefreshIndicator(
                  color: signalGreen,
                  onRefresh: () =>
                      ref.read(communityListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: listState.boards.length,
                    itemBuilder: (context, index) {
                      final board = listState.boards[index];
                      return _BoardCard(
                        board: board,
                        isDark: isDark,
                        signalGreen: signalGreen,
                        ghostGrey: ghostGrey,
                        l10n: l10n,
                        onTap: () => context.push('/board/${board.boardId}'),
                        onDismissed: () => ref
                            .read(communityListProvider.notifier)
                            .removeBoard(board.boardId),
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
              title: Text(l10n.communityListCreate),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/board/create');
              },
            ),
            ListTile(
              leading: Icon(Icons.login, color: signalGreen),
              title: Text(l10n.communityListJoinById),
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

  /// 보드 ID 입력 다이얼로그
  static void _showJoinByIdDialog(
      BuildContext context, AppLocalizations l10n, Color signalGreen) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.communityListJoinDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.communityListJoinDialogHint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final id = value.trim();
            if (id.isNotEmpty) {
              Navigator.pop(ctx);
              context.push('/board/$id');
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final id = controller.text.trim();
              if (id.isNotEmpty) {
                Navigator.pop(ctx);
                context.push('/board/$id');
              }
            },
            child: Text(
              l10n.communityListJoinDialogJoin,
              style: TextStyle(color: signalGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final Color signalGreen;
  final Color ghostGrey;

  const _EmptyState({
    required this.l10n,
    required this.signalGreen,
    required this.ghostGrey,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined,
                size: 64, color: ghostGrey.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              l10n.communityListEmpty,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: ghostGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // 만들기
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/board/create'),
                icon: Icon(Icons.add, color: signalGreen),
                label: Text(l10n.communityListCreate),
              ),
            ),
            const SizedBox(height: 12),
            // ID로 참여
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => MyCommunityListScreen._showJoinByIdDialog(
                    context, l10n, signalGreen),
                icon: Icon(Icons.login, color: signalGreen),
                label: Text(l10n.communityListJoinById),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  final SavedBoard board;
  final bool isDark;
  final Color signalGreen;
  final Color ghostGrey;
  final AppLocalizations l10n;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _BoardCard({
    required this.board,
    required this.isDark,
    required this.signalGreen,
    required this.ghostGrey,
    required this.l10n,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = board.status == 'active';
    final statusColor = isActive ? signalGreen : AppColors.glitchRed;

    final joinDate = DateTime.fromMillisecondsSinceEpoch(board.joinedAt);
    final dateStr =
        '${joinDate.year}-${joinDate.month.toString().padLeft(2, '0')}-${joinDate.day.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(board.boardId),
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
                  // 아이콘
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50,
                    ),
                    child: Icon(Icons.lock, color: statusColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  // 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          board.boardName.isNotEmpty
                              ? board.boardName
                              : 'Board ${board.boardId.substring(0, 8)}',
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
                          '${l10n.communityListJoinedAt} $dateStr',
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
}
