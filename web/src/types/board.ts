import type { EncryptedPayload } from './chat';

// ─── 게시판 ───

export interface Board {
  id: string;
  encryptedName: EncryptedPayload;
  encryptedSubtitle?: EncryptedPayload;
  status: 'active' | 'archived' | 'destroyed';
  createdAt: string;
  maxParticipants: number;
  reportThreshold: number;
}

// ─── 게시글 (서버 저장 형태: 암호문) ───

export interface BoardPost {
  id: string;
  boardId: string;
  authorNameEncrypted: string;
  authorNameNonce: string;
  titleEncrypted: string | null;
  titleNonce: string | null;
  contentEncrypted: string;
  contentNonce: string;
  createdAt: string;
  isBlinded: boolean;
  reportCount: number;
}

// ─── 게시글 (클라이언트 복호화 형태) ───

export interface DecryptedPost {
  id: string;
  authorName: string;
  title: string;
  content: string;
  createdAt: string;
  isBlinded: boolean;
  isMine: boolean;
  images: DecryptedPostImage[];
  /** 복호화 전 이미지 메타데이터 (lazy decryption용) */
  _encryptedImages?: EncryptedPostImageMeta[];
  /** 댓글 수 (목록 조회 시) */
  commentCount?: number;
}

/** 이미지 복호화에 필요한 최소 메타데이터 */
export interface EncryptedPostImageMeta {
  id: string;
  encryptedNonce: string;
  mimeType: string;
  width: number | null;
  height: number | null;
}

// ─── 이미지 ───

/** 복호화된 이미지 (클라이언트 메모리) */
export interface DecryptedPostImage {
  id: string;
  objectUrl: string;
  mimeType: string;
  width: number | null;
  height: number | null;
}

/** 서버 응답용 이미지 메타데이터 (암호문 상태) */
export interface EncryptedPostImage {
  id: string;
  storagePath: string;
  encryptedNonce: string;
  mimeType: string;
  sizeBytes: number;
  width: number | null;
  height: number | null;
  displayOrder: number;
}

// ─── 댓글 (서버 저장 형태: 암호문) ───

export interface BoardComment {
  id: string;
  postId: string;
  authorNameEncrypted: string;
  authorNameNonce: string;
  contentEncrypted: string;
  contentNonce: string;
  createdAt: string;
  isBlinded: boolean;
  images: EncryptedPostImage[];
}

// ─── 댓글 (클라이언트 복호화 형태) ───

export interface DecryptedComment {
  id: string;
  postId: string;
  authorName: string;
  content: string;
  createdAt: string;
  isBlinded: boolean;
  isMine: boolean;
  images: DecryptedPostImage[];
  _encryptedImages?: EncryptedPostImageMeta[];
}

// ─── 상태 ───

export type BoardStatus =
  | 'loading'
  | 'password_required'
  | 'created'
  | 'browsing'
  | 'destroyed'
  | 'error';

// ─── 신고 ───

export type ReportReason = 'spam' | 'abuse' | 'illegal' | 'other';
