import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_room.dart';

/// 채팅 리스트 상태
class ChatListState {
  final List<SavedRoom> rooms;
  final bool loading;
  final bool refreshing;

  const ChatListState({
    this.rooms = const [],
    this.loading = true,
    this.refreshing = false,
  });

  ChatListState copyWith({
    List<SavedRoom>? rooms,
    bool? loading,
    bool? refreshing,
  }) {
    return ChatListState(
      rooms: rooms ?? this.rooms,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
    );
  }
}

/// 채팅 리스트 Provider
class ChatListNotifier extends StateNotifier<ChatListState> {
  final LocalStorageService _storage;
  final ApiClient _api;

  ChatListNotifier({
    LocalStorageService? storage,
    ApiClient? api,
  })  : _storage = storage ?? LocalStorageService(),
        _api = api ?? ApiClient(),
        super(const ChatListState()) {
    load();
  }

  /// 초기 로드
  Future<void> load() async {
    final rooms = await _storage.getSavedRooms();
    state = state.copyWith(rooms: rooms, loading: false);
    // 바로 서버 상태 동기화
    await _syncStatuses();
  }

  /// Pull-to-refresh
  Future<void> refresh() async {
    state = state.copyWith(refreshing: true);
    final rooms = await _storage.getSavedRooms();
    state = state.copyWith(rooms: rooms);
    await _syncStatuses();
    state = state.copyWith(refreshing: false);
  }

  /// 서버에서 배치 상태 확인 후 로컬 업데이트
  Future<void> _syncStatuses() async {
    final activeRooms =
        state.rooms.where((r) => r.status == 'active').toList();
    if (activeRooms.isEmpty) return;

    try {
      final statuses = await _api.batchRoomStatus(
        activeRooms.map((r) => r.roomId).toList(),
      );

      for (final entry in statuses.entries) {
        final serverStatus = entry.value;
        // 'not_found'도 destroyed로 처리
        final normalizedStatus =
            serverStatus == 'not_found' ? 'destroyed' : serverStatus;
        if (normalizedStatus != 'active') {
          await _storage.updateRoomStatus(entry.key, normalizedStatus);
        }
      }

      // 업데이트된 목록 다시 로드
      final updated = await _storage.getSavedRooms();
      if (mounted) state = state.copyWith(rooms: updated);
    } catch (_) {
      // 네트워크 에러 시 로컬 상태 유지
    }
  }

  /// 로컬에서 방 삭제
  Future<void> removeRoom(String roomId) async {
    await _storage.removeRoom(roomId);
    state = state.copyWith(
      rooms: state.rooms.where((r) => r.roomId != roomId).toList(),
    );
  }
}

final chatListProvider =
    StateNotifierProvider.autoDispose<ChatListNotifier, ChatListState>(
  (ref) => ChatListNotifier(),
);
