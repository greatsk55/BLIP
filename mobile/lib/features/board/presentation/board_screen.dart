import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/ad_service.dart';
import '../domain/models/board_post.dart';
import '../providers/board_provider.dart';
import 'widgets/post_list.dart';
import 'widgets/post_composer.dart';
import 'widgets/post_detail.dart';
import 'widgets/report_dialog.dart';
import 'widgets/board_header.dart';
import 'widgets/admin_panel_dialog.dart';

class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  final _passwordController = TextEditingController();
  bool _verifying = false;
  String? _error;
  DecryptedPost? _selectedPost; // 상세보기 중인 게시글

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final boardState = ref.watch(boardNotifierProvider(widget.boardId));

    return PopScope(
      canPop: _selectedPost == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _selectedPost != null) {
          setState(() => _selectedPost = null);
        }
      },
      child: Scaffold(
        appBar: boardState.status == BoardStatus.browsing || _selectedPost != null
            ? null // browsing은 BoardHeader 사용, 상세보기는 자체 헤더
            : AppBar(
                title: Text(boardState.boardName ?? l10n.boardTitle),
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
        body: SafeArea(
          // appBar가 있는 상태(password 등)에서만 SafeArea.top 불필요
          // browsing → BoardHeader가 자체 SafeArea 처리
          // 상세보기 → PostDetail 내부에서 SafeArea 필요
          top: boardState.status != BoardStatus.browsing || _selectedPost != null,
          child: _buildContent(l10n, boardState),
        ),
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n, BoardState boardState) {
    switch (boardState.status) {
      case BoardStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case BoardStatus.passwordRequired:
        return _buildPasswordEntry(l10n);

      case BoardStatus.created:
        return Center(child: Text(l10n.boardCreated));

      case BoardStatus.browsing:
        return _buildBrowsingView(l10n, boardState);

      case BoardStatus.destroyed:
        return _buildDestroyedView(l10n);

      case BoardStatus.error:
        return Center(child: Text(l10n.errorGeneric));
    }
  }

  Widget _buildPasswordEntry(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum_outlined, size: 48, color: signalGreen),
            const SizedBox(height: 24),
            Text(l10n.chatPasswordTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              textAlign: TextAlign.center,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 4,
                fontFamily: 'monospace',
              ),
              decoration: InputDecoration(
                hintText: 'XXXX-XXXX',
                errorText: _error != null ? _getErrorText(l10n, _error!) : null,
              ),
              onSubmitted: (_) => _verify(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _verifying ? null : _verify,
                child: _verifying
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.chatPasswordJoin),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _verifying = true;
      _error = null;
    });

    final error = await ref
        .read(boardNotifierProvider(widget.boardId).notifier)
        .authenticate(password);

    if (mounted) {
      setState(() {
        _verifying = false;
        _error = error;
      });
    }
  }

  String _getErrorText(AppLocalizations l10n, String code) {
    return switch (code) {
      'INVALID_PASSWORD' => l10n.chatPasswordInvalid,
      'BOARD_NOT_FOUND' => l10n.chatRoomNotFound,
      'BOARD_DESTROYED' => l10n.chatRoomDestroyed,
      _ => l10n.errorGeneric,
    };
  }

  Widget _buildBrowsingView(AppLocalizations l10n, BoardState boardState) {
    // 상세보기 모드
    if (_selectedPost != null) {
      final freshPost = boardState.posts
          .where((p) => p.id == _selectedPost!.id)
          .firstOrNull;

      if (freshPost == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedPost = null);
        });
        return const Center(child: CircularProgressIndicator());
      }

      final notifier =
          ref.read(boardNotifierProvider(widget.boardId).notifier);

      return PostDetail(
        post: freshPost,
        onBack: () => setState(() => _selectedPost = null),
        onShare: () => _sharePost(freshPost.id),
        onDecryptImages: (postId) => notifier.decryptPostImages(postId),
        onEdit: freshPost.isMine
            ? () => _showComposer(
                  editPostId: freshPost.id,
                  editTitle: freshPost.title,
                  editContent: freshPost.content,
                )
            : null,
        onDelete: freshPost.isMine
            ? (postId) async {
                final err = await notifier.deletePost(postId);
                if (err == null && mounted) {
                  setState(() => _selectedPost = null);
                }
                return err;
              }
            : null,
        onAdminDelete: boardState.adminToken != null && !freshPost.isMine
            ? (postId) async {
                final err = await notifier.deletePost(postId,
                    adminToken: boardState.adminToken);
                if (err == null && mounted) {
                  setState(() => _selectedPost = null);
                }
                return err;
              }
            : null,
        onReport: !freshPost.isMine
            ? () => ReportDialog.show(
                  context,
                  onSubmit: (reason) =>
                      notifier.submitReport(freshPost.id, reason),
                )
            : null,
        // 댓글 props
        comments: boardState.comments[freshPost.id] ?? const [],
        commentsHasMore: boardState.commentsHasMore[freshPost.id] ?? false,
        commentsLoading: boardState.commentsLoading,
        onLoadComments: () => notifier.loadComments(freshPost.id),
        onLoadMoreComments: () => notifier.loadMoreComments(freshPost.id),
        onSubmitComment: (content, {media}) =>
            notifier.submitComment(freshPost.id, content, media: media),
        onDeleteComment: (commentId) =>
            notifier.deleteComment(commentId, freshPost.id),
        onAdminDeleteComment:
            boardState.adminToken != null
                ? (commentId) => notifier.deleteComment(
                    commentId, freshPost.id,
                    adminToken: boardState.adminToken)
                : null,
        onReportComment: (commentId) => ReportDialog.show(
              context,
              onSubmit: (reason) =>
                  notifier.submitCommentReport(commentId, reason),
            ),
        onDecryptCommentImages: (commentId) =>
            notifier.decryptCommentImages(commentId, freshPost.id),
      );
    }

    // 목록 모드
    return Column(
      children: [
        // BoardHeader (AppBar 대체)
        BoardHeader(
          boardName: boardState.boardName ?? l10n.boardTitle,
          boardSubtitle: boardState.boardSubtitle,
          hasAdminToken: boardState.adminToken != null,
          isPasswordSaved: boardState.isPasswordSaved,
          onBack: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/');
            }
          },
          onRefresh: () => ref
              .read(boardNotifierProvider(widget.boardId).notifier)
              .refreshPosts(),
          onAdminPanel: () => _showAdminPanel(),
          onRegisterAdmin: () => _showAdminTokenInput(),
        ),

        Expanded(
          child: PostList(
            posts: boardState.posts,
            hasMore: boardState.hasMore,
            onLoadMore: () => ref
                .read(boardNotifierProvider(widget.boardId).notifier)
                .loadMore(),
            onRefresh: () => ref
                .read(boardNotifierProvider(widget.boardId).notifier)
                .refreshPosts(),
            onPostClick: (post) async {
              // 글 조회 5번에 1번 전면광고
              await AdService.instance.maybeShowInterstitial(
                key: 'post_view',
                frequency: 5,
              );
              if (!mounted) return;
              setState(() => _selectedPost = post);
            },
            onSharePost: (postId) => _sharePost(postId),
          ),
        ),

        Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _showComposer(),
              icon: const Icon(Icons.edit),
              label: Text(l10n.boardWritePost),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sharePost(String postId) async {
    final notifier =
        ref.read(boardNotifierProvider(widget.boardId).notifier);
    final url = await notifier.getShareUrl(postId);
    await Share.share(url);
  }

  void _showComposer({
    String? editPostId,
    String? editTitle,
    String? editContent,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostComposer(
          editTitle: editTitle,
          editContent: editContent,
          onSubmitted: (title, content, {media}) async {
            if (editPostId != null) {
              return ref
                  .read(boardNotifierProvider(widget.boardId).notifier)
                  .editPost(editPostId, title, content);
            }
            return ref
                .read(boardNotifierProvider(widget.boardId).notifier)
                .submitPost(title, content, media: media);
          },
        ),
      ),
    );
  }

  Future<void> _showAdminTokenInput() async {
    final token = await BoardHeader.showTokenInputDialog(context);
    if (token != null && mounted) {
      await ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .saveAdminToken(token);
    }
  }

  void _showAdminPanel() {
    final boardState = ref.read(boardNotifierProvider(widget.boardId));
    AdminPanelDialog.show(
      context,
      boardId: widget.boardId,
      onForgetToken: () => ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .forgetAdminToken(),
      onDestroyBoard: () => ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .destroyBoard(),
      currentSubtitle: boardState.boardSubtitle,
      onUpdateSubtitle: (subtitle) => ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .updateSubtitle(subtitle),
      onRotateInviteCode: () => ref
          .read(boardNotifierProvider(widget.boardId).notifier)
          .rotateInviteCode(),
    );
  }

  Widget _buildDestroyedView(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.delete_forever, size: 64, color: AppColors.glitchRed),
          const SizedBox(height: 16),
          Text(l10n.boardDestroyedTitle,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(l10n.boardDestroyedMessage),
        ],
      ),
    );
  }
}
