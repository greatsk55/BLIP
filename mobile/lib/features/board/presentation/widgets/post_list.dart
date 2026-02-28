import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/board_post.dart';
import 'post_card.dart';

/// 게시글 목록 (Pull-to-refresh + 무한 스크롤)
/// web: PostList.tsx 동일 UX
class PostList extends StatefulWidget {
  final List<DecryptedPost> posts;
  final bool hasMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  final void Function(DecryptedPost post)? onPostClick;
  final void Function(String postId)? onSharePost;

  const PostList({
    super.key,
    required this.posts,
    required this.hasMore,
    required this.onLoadMore,
    required this.onRefresh,
    this.onPostClick,
    this.onSharePost,
  });

  @override
  State<PostList> createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  final _scrollController = ScrollController();
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || !widget.hasMore) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // 하단 200px 이내에서 추가 로드
    if (currentScroll >= maxScroll - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    await widget.onLoadMore();
    if (mounted) setState(() => _loadingMore = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (widget.posts.isEmpty) {
      return _EmptyState(l10n: l10n);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.signalGreenDark
          : AppColors.signalGreenLight,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: widget.posts.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          // 로딩 인디케이터
          if (index == widget.posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final post = widget.posts[index];
          return PostCard(
            post: post,
            onTap: () => widget.onPostClick?.call(post),
            onShare: widget.onSharePost != null
                ? () => widget.onSharePost!(post.id)
                : null,
          );
        },
      ),
    );
  }
}

/// 빈 상태 뷰
class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 48,
            color: isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.boardPostEmpty,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color:
                  isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.boardPostWriteFirst,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: (isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight)
                  .withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
