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
  static const _blipMeOwnerTokenKey = 'blip-me-owner-token';
  static const _blipMeLinkIdKey = 'blip_me_link_id';

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

  // ═══════════ BLIP me ═══════════

  Future<String?> getBlipMeOwnerToken() async {
    return _secure.read(key: _blipMeOwnerTokenKey);
  }

  Future<void> saveBlipMeOwnerToken(String token) async {
    await _secure.write(key: _blipMeOwnerTokenKey, value: token);
  }

  Future<void> removeBlipMeOwnerToken() async {
    await _secure.delete(key: _blipMeOwnerTokenKey);
  }

  Future<String?> getBlipMeLinkId() async {
    final prefs = await _preferences;
    return prefs.getString(_blipMeLinkIdKey);
  }

  Future<void> saveBlipMeLinkId(String linkId) async {
    final prefs = await _preferences;
    await prefs.setString(_blipMeLinkIdKey, linkId);
  }

  Future<void> removeBlipMeLinkId() async {
    final prefs = await _preferences;
    await prefs.remove(_blipMeLinkIdKey);
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

  // ═══════════ Chat History (그룹채팅 로컬 저장) ═══════════

  static const _chatHistoryPrefix = 'blip-chat-history-';
  static const _maxStoredMessages = 100;

  /// 채팅 메시지 저장 (최대 _maxStoredMessages개)
  Future<void> saveChatMessages(
    String roomId,
    List<Map<String, dynamic>> messages,
  ) async {
    final prefs = await _preferences;
    final trimmed = messages.length > _maxStoredMessages
        ? messages.sublist(messages.length - _maxStoredMessages)
        : messages;
    await prefs.setString(
      '$_chatHistoryPrefix$roomId',
      jsonEncode(trimmed),
    );
  }

  /// 채팅 메시지 추가
  Future<void> appendChatMessage(
    String roomId,
    Map<String, dynamic> message,
  ) async {
    final existing = await getChatMessages(roomId);
    existing.add(message);
    await saveChatMessages(roomId, existing);
  }

  /// 저장된 채팅 메시지 조회
  Future<List<Map<String, dynamic>>> getChatMessages(String roomId) async {
    final prefs = await _preferences;
    final raw = prefs.getString('$_chatHistoryPrefix$roomId');
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(jsonDecode(raw));
    } catch (_) {
      return [];
    }
  }

  /// 채팅 히스토리 삭제
  Future<void> clearChatMessages(String roomId) async {
    final prefs = await _preferences;
    await prefs.remove('$_chatHistoryPrefix$roomId');
  }
}
