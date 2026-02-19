import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_board.dart';

/// 커뮤니티 리스트 상태
class CommunityListState {
  final List<SavedBoard> boards;
  final bool loading;
  final bool refreshing;

  const CommunityListState({
    this.boards = const [],
    this.loading = true,
    this.refreshing = false,
  });

  CommunityListState copyWith({
    List<SavedBoard>? boards,
    bool? loading,
    bool? refreshing,
  }) {
    return CommunityListState(
      boards: boards ?? this.boards,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

/// 커뮤니티 리스트 Provider
class CommunityListNotifier extends StateNotifier<CommunityListState> {
  final LocalStorageService _storage;
  final ApiClient _api;

  CommunityListNotifier({
    LocalStorageService? storage,
    ApiClient? api,
  })  : _storage = storage ?? LocalStorageService(),
        _api = api ?? ApiClient(),
        super(const CommunityListState()) {
    load();
  }

  Future<void> load() async {
    final boards = await _storage.getSavedBoards();
    state = state.copyWith(boards: boards, loading: false);
    await _syncStatuses();
  }

  Future<void> refresh() async {
    state = state.copyWith(refreshing: true);
    final boards = await _storage.getSavedBoards();
    state = state.copyWith(boards: boards);
    await _syncStatuses();
    state = state.copyWith(refreshing: false);
  }

  Future<void> _syncStatuses() async {
    final activeBoards =
        state.boards.where((b) => b.status == 'active').toList();
    if (activeBoards.isEmpty) return;

    try {
      final statuses = await _api.batchBoardStatus(
        activeBoards.map((b) => b.boardId).toList(),
      );

      for (final entry in statuses.entries) {
        final serverStatus = entry.value;
        final normalized =
            serverStatus == 'not_found' ? 'destroyed' : serverStatus;
        if (normalized != 'active') {
          await _storage.updateBoardStatus(entry.key, normalized);
        }
      }

      final updated = await _storage.getSavedBoards();
      if (mounted) state = state.copyWith(boards: updated);
    } catch (_) {
      // 네트워크 에러 시 로컬 상태 유지
    }
  }

  Future<void> removeBoard(String boardId) async {
    await _storage.removeBoard(boardId);
    state = state.copyWith(
      boards: state.boards.where((b) => b.boardId != boardId).toList(),
    );
  }
}

final communityListProvider = StateNotifierProvider
    .autoDispose<CommunityListNotifier, CommunityListState>(
  (ref) => CommunityListNotifier(),
);
