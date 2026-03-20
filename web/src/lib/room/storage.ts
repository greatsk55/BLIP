/**
 * 채팅방 로컬 저장소 (SSOT)
 * - 1:1 채팅 + 그룹 채팅 메타데이터를 localStorage에 저장
 * - 비밀번호는 메모리/URL fragment에서만 관리 (localStorage에 저장하지 않음)
 * - 인메모리 캐시로 반복적인 JSON.parse/stringify 방지
 */

// ─── 타입 ───

export type RoomType = 'chat' | 'group';

export interface SavedRoom {
  roomId: string;
  roomType: RoomType;
  isCreator: boolean;
  isAdmin: boolean;
  title?: string;       // 그룹 채팅 제목
  peerUsername?: string; // 1:1 상대방 이름
  createdAt: number;
  lastAccessedAt: number;
  status: 'active' | 'destroyed' | 'expired';
}

// ─── 상수 ───

const STORAGE_KEY = 'blip-saved-rooms';
const PASSWORD_PREFIX = 'blip-room-pwd-';
const ADMIN_TOKEN_PREFIX = 'blip-room-admin-';

// ─── 인메모리 캐시 ───

const isBrowser = typeof window !== 'undefined';
let _cachedRooms: SavedRoom[] | null = null;

// 다른 탭에서 변경 시 캐시 무효화
if (isBrowser) {
  window.addEventListener('storage', (e) => {
    if (e.key === STORAGE_KEY) _cachedRooms = null;
  });
}

// ─── 헬퍼 ───

function readRooms(): SavedRoom[] {
  if (!isBrowser) return [];
  if (_cachedRooms !== null) return _cachedRooms;
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    _cachedRooms = JSON.parse(raw) as SavedRoom[];
    return _cachedRooms;
  } catch {
    return [];
  }
}

function writeRooms(rooms: SavedRoom[]): void {
  if (!isBrowser) return;
  _cachedRooms = rooms;
  localStorage.setItem(STORAGE_KEY, JSON.stringify(rooms));
}

// ─── 공개 API ───

/** 저장된 채팅방 목록 (최근 접속순) */
export function getSavedRooms(): SavedRoom[] {
  return readRooms().sort((a, b) => b.lastAccessedAt - a.lastAccessedAt);
}

/** 채팅방 저장 (중복 시 업데이트) */
export function saveRoom(room: SavedRoom): void {
  const rooms = readRooms();
  const index = rooms.findIndex((r) => r.roomId === room.roomId);
  if (index >= 0) {
    rooms[index] = { ...rooms[index], ...room };
  } else {
    rooms.unshift(room);
  }
  writeRooms(rooms);
}

/** 비밀번호 저장 */
export function saveRoomPassword(roomId: string, password: string): void {
  if (!isBrowser) return;
  localStorage.setItem(`${PASSWORD_PREFIX}${roomId}`, password);
}

/** 비밀번호 조회 */
export function getRoomPassword(roomId: string): string | null {
  if (!isBrowser) return null;
  return localStorage.getItem(`${PASSWORD_PREFIX}${roomId}`);
}

/** 관리자 토큰 저장 (그룹 채팅 관리자용) */
export function saveAdminToken(roomId: string, adminToken: string): void {
  if (!isBrowser) return;
  localStorage.setItem(`${ADMIN_TOKEN_PREFIX}${roomId}`, adminToken);
}

/** 관리자 토큰 조회 */
export function getAdminToken(roomId: string): string | null {
  if (!isBrowser) return null;
  return localStorage.getItem(`${ADMIN_TOKEN_PREFIX}${roomId}`);
}

/** 채팅방 삭제 */
export function removeSavedRoom(roomId: string): void {
  writeRooms(readRooms().filter((r) => r.roomId !== roomId));
  if (isBrowser) {
    localStorage.removeItem(`${PASSWORD_PREFIX}${roomId}`);
    localStorage.removeItem(`${ADMIN_TOKEN_PREFIX}${roomId}`);
  }
}

/** 상태 업데이트 */
export function updateRoomStatus(roomId: string, status: SavedRoom['status']): void {
  const rooms = readRooms();
  const room = rooms.find((r) => r.roomId === roomId);
  if (room) {
    room.status = status;
    writeRooms(rooms);
  }
}

/** 상대방 이름 업데이트 (1:1) */
export function updateRoomPeer(roomId: string, peerUsername: string): void {
  const rooms = readRooms();
  const room = rooms.find((r) => r.roomId === roomId);
  if (room) {
    room.peerUsername = peerUsername;
    writeRooms(rooms);
  }
}

/** 마지막 접속 시간 업데이트 */
export function touchRoom(roomId: string): void {
  const rooms = readRooms();
  const room = rooms.find((r) => r.roomId === roomId);
  if (room) {
    room.lastAccessedAt = Date.now();
    writeRooms(rooms);
  }
}
