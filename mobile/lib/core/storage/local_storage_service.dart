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
    await _writeRooms(rooms);
    // 비밀번호는 SecureStorage에 별도 저장
    await _secure.write(
      key: '$_roomPasswordPrefix${room.roomId}',
      value: password,
    );
  }

  Future<void> removeRoom(String roomId) async {
    final rooms = await getSavedRooms();
    rooms.removeWhere((r) => r.roomId == roomId);
    await _writeRooms(rooms);
    await _secure.delete(key: '$_roomPasswordPrefix$roomId');
  }

  Future<void> updateRoomStatus(String roomId, String status) async {
    final rooms = await getSavedRooms();
    final index = rooms.indexWhere((r) => r.roomId == roomId);
    if (index >= 0) {
      rooms[index] = rooms[index].copyWith(status: status);
      await _writeRooms(rooms);
    }
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
