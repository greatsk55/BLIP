import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/saved_board.dart';
import 'models/saved_room.dart';

/// 로컬 저장소 서비스 (SSOT)
/// - SharedPreferences: 메타데이터 리스트 (JSON)
/// - FlutterSecureStorage: 비밀번호 (iOS Keychain / Android KeyStore)
class LocalStorageService {
  static const _roomsKey = 'blip_saved_rooms';
  static const _boardsKey = 'blip_saved_boards';
  static const _roomPasswordPrefix = 'blip-room-pwd-';
  static const _adminTokenPrefix = 'blip-room-admin-';

  final FlutterSecureStorage _secure;
  SharedPreferences? _prefs;

  LocalStorageService({FlutterSecureStorage? secure})
      : _secure = secure ?? const FlutterSecureStorage();

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ═══════════ Rooms ═══════════

  Future<List<SavedRoom>> getSavedRooms() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_roomsKey);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => SavedRoom.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  Future<void> saveRoom(SavedRoom room, String password) async {
    final rooms = await getSavedRooms();
    // 중복 방지: 이미 있으면 업데이트
    final index = rooms.indexWhere((r) => r.roomId == room.roomId);
    if (index >= 0) {
      rooms[index] = room;
    } else {
      rooms.insert(0, room);
    }
    // SharedPreferences 쓰기와 SecureStorage 쓰기는 독립적이므로 병렬 실행
    await Future.wait([
      _writeRooms(rooms),
      _secure.write(
        key: '$_roomPasswordPrefix${room.roomId}',
        value: password,
      ),
    ]);
  }

  Future<void> removeRoom(String roomId) async {
    final rooms = await getSavedRooms();
    rooms.removeWhere((r) => r.roomId == roomId);
    await Future.wait([
      _writeRooms(rooms),
      _secure.delete(key: '$_roomPasswordPrefix$roomId'),
      _secure.delete(key: '$_adminTokenPrefix$roomId'),
    ]);
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    final rooms = await getSavedRooms();
    final index = rooms.indexWhere((r) => r.roomId == roomId);
    if (index >= 0) {
      rooms[index] = rooms[index].copyWith(status: status);
      await _writeRooms(rooms);
    }
  }

  /// 여러 방의 상태를 한 번에 업데이트 (N번 I/O → 1번)
  Future<void> updateRoomStatuses(Map<String, String> statusMap) async {
    if (statusMap.isEmpty) return;
    final rooms = await getSavedRooms();
    bool changed = false;
    for (int i = 0; i < rooms.length; i++) {
      final newStatus = statusMap[rooms[i].roomId];
      if (newStatus != null && rooms[i].status != newStatus) {
        rooms[i] = rooms[i].copyWith(status: newStatus);
        changed = true;
      }
    }
    if (changed) await _writeRooms(rooms);
  }

  Future<void> updateRoomPeer(String roomId, String peerUsername) async {
    final rooms = await getSavedRooms();
    final index = rooms.indexWhere((r) => r.roomId == roomId);
    if (index >= 0) {
      rooms[index] = rooms[index].copyWith(peerUsername: peerUsername);
      await _writeRooms(rooms);
    }
  }

  Future<String?> getRoomPassword(String roomId) async {
    return _secure.read(key: '$_roomPasswordPrefix$roomId');
  }

  // ═══════════ Admin Tokens ═══════════

  Future<void> saveAdminToken(String roomId, String adminToken) async {
    await _secure.write(
      key: '$_adminTokenPrefix$roomId',
      value: adminToken,
    );
  }

  Future<String?> getAdminToken(String roomId) async {
    return _secure.read(key: '$_adminTokenPrefix$roomId');
  }

  Future<void> removeAdminToken(String roomId) async {
    await _secure.delete(key: '$_adminTokenPrefix$roomId');
  }

  Future<void> _writeRooms(List<SavedRoom> rooms) async {
    final prefs = await _preferences;
    await prefs.setString(
      _roomsKey,
      jsonEncode(rooms.map((r) => r.toJson()).toList()),
    );
  }

  // ═══════════ Boards ═══════════

  Future<List<SavedBoard>> getSavedBoards() async {
    final prefs = await _preferences;
    final jsonStr = prefs.getString(_boardsKey);
    if (jsonStr == null) return [];

    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => SavedBoard.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));
  }

  Future<void> saveBoard(SavedBoard board) async {
    final boards = await getSavedBoards();
    final index = boards.indexWhere((b) => b.boardId == board.boardId);
    if (index >= 0) {
      boards[index] = board;
    } else {
      boards.insert(0, board);
    }
    await _writeBoards(boards);
  }

  Future<void> removeBoard(String boardId) async {
    final boards = await getSavedBoards();
    boards.removeWhere((b) => b.boardId == boardId);
    await _writeBoards(boards);
  }

  Future<void> updateBoardStatus(String boardId, String status) async {
    final boards = await getSavedBoards();
    final index = boards.indexWhere((b) => b.boardId == boardId);
    if (index >= 0) {
      boards[index] = boards[index].copyWith(status: status);
      await _writeBoards(boards);
    }
  }

  Future<void> _writeBoards(List<SavedBoard> boards) async {
    final prefs = await _preferences;
    await prefs.setString(
      _boardsKey,
      jsonEncode(boards.map((b) => b.toJson()).toList()),
    );
  }
}
