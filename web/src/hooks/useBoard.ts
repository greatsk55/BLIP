'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import {
  deriveKeysFromPassword,
  hashAuthKey,
  encryptSymmetric,
  decryptSymmetric,
  encryptBinary,
  decryptBinaryRaw,
  generateInviteCode,
  deriveWrappingKey,
  wrapEncryptionKey,
  unwrapEncryptionKey,
  hashEncryptionKeyForAuth,
  hashInviteCode,
} from '@/lib/crypto';
import { decodeBase64, encodeBase64 } from 'tweetnacl-util';
import { generateUsername } from '@/lib/username';
import { compressImage } from '@/lib/media/compress';
import { getMediaType, createVideoThumbnail } from '@/lib/media/thumbnail';
import {
  getPosts,
  createPost,
  updatePost,
  reportPost,
  adminDeletePost,
  deleteOwnPost,
  getBoardMeta,
  updateBoardSubtitle,
  getComments,
  createComment,
  deleteOwnComment,
  reportComment,
  adminDeleteComment,
  joinBoardViaInviteCode,
  rotateInviteCode as rotateInviteCodeAction,
  updateEncryptionKeyAuthHash,
} from '@/lib/board/actions';
import type { DecryptedPost, DecryptedPostImage, DecryptedComment, BoardStatus, ReportReason } from '@/types/board';

// ─── localStorage 헬퍼 ───

const STORAGE_PREFIX = 'blip-board-';
const ADMIN_PREFIX = 'blip-board-admin-';
const USERNAME_PREFIX = 'blip-board-user-';
const NAME_PREFIX = 'blip-board-name-';
const SUBTITLE_PREFIX = 'blip-board-subtitle-';
const ENCRYPTION_KEY_PREFIX = 'blip-board-key-';
const EAUTH_PREFIX = 'blip-board-eauth-';

function getSavedPassword(boardId: string): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(`${STORAGE_PREFIX}${boardId}`);
}

export function savePassword(boardId: string, password: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${STORAGE_PREFIX}${boardId}`, password);
}

function forgetPassword(boardId: string): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(`${STORAGE_PREFIX}${boardId}`);
}

function getSavedAdminToken(boardId: string): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(`${ADMIN_PREFIX}${boardId}`);
}

export function saveAdminTokenToStorage(boardId: string, token: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${ADMIN_PREFIX}${boardId}`, token);
}

function forgetAdminToken(boardId: string): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(`${ADMIN_PREFIX}${boardId}`);
}

function getSavedEncryptionKey(boardId: string): Uint8Array | null {
  if (typeof window === 'undefined') return null;
  const saved = localStorage.getItem(`${ENCRYPTION_KEY_PREFIX}${boardId}`);
  if (!saved) return null;
  try { return decodeBase64(saved); } catch { return null; }
}

function saveEncryptionKey(boardId: string, key: Uint8Array): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${ENCRYPTION_KEY_PREFIX}${boardId}`, encodeBase64(key));
}

function getSavedEAuth(boardId: string): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(`${EAUTH_PREFIX}${boardId}`);
}

function saveEAuth(boardId: string, eauth: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${EAUTH_PREFIX}${boardId}`, eauth);
}

function getOrCreateUsername(boardId: string): string {
  if (typeof window === 'undefined') return generateUsername();
  const saved = localStorage.getItem(`${USERNAME_PREFIX}${boardId}`);
  if (saved) return saved;
  const name = generateUsername();
  localStorage.setItem(`${USERNAME_PREFIX}${boardId}`, name);
  return name;
}

// ─── 보드 이름 캐시 ───

export function saveBoardName(boardId: string, name: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${NAME_PREFIX}${boardId}`, name);
}

function getSavedBoardName(boardId: string): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(`${NAME_PREFIX}${boardId}`);
}

// ─── 보드 부제목 캐시 ───

export function saveBoardSubtitle(boardId: string, subtitle: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${SUBTITLE_PREFIX}${boardId}`, subtitle);
}

function getSavedBoardSubtitle(boardId: string): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(`${SUBTITLE_PREFIX}${boardId}`);
}

// ─── 저장된 커뮤니티 목록 (대시보드용) ───

export interface SavedBoard {
  boardId: string;
  name: string | null;
  subtitle: string | null;
  hasAdminToken: boolean;
}

/** localStorage에서 저장된 커뮤니티 목록을 반환 */
export function getSavedBoards(): SavedBoard[] {
  if (typeof window === 'undefined') return [];
  const boardIds = new Set<string>();
  // 보조 prefix 목록 (boardId 추출 대상에서 제외)
  const auxiliaryPrefixes = [ADMIN_PREFIX, USERNAME_PREFIX, NAME_PREFIX, SUBTITLE_PREFIX, EAUTH_PREFIX];

  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (!key?.startsWith(STORAGE_PREFIX)) continue;
    if (auxiliaryPrefixes.some((p) => key.startsWith(p))) continue;

    // password key (blip-board-{id}) 또는 encryption key (blip-board-key-{id})
    if (key.startsWith(ENCRYPTION_KEY_PREFIX)) {
      boardIds.add(key.slice(ENCRYPTION_KEY_PREFIX.length));
    } else {
      boardIds.add(key.slice(STORAGE_PREFIX.length));
    }
  }

  return Array.from(boardIds).map((boardId) => ({
    boardId,
    name: getSavedBoardName(boardId),
    subtitle: getSavedBoardSubtitle(boardId),
    hasAdminToken: !!getSavedAdminToken(boardId),
  }));
}

/** 커뮤니티의 모든 로컬 데이터를 삭제 */
export function removeSavedBoard(boardId: string): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(`${STORAGE_PREFIX}${boardId}`);
  localStorage.removeItem(`${ADMIN_PREFIX}${boardId}`);
  localStorage.removeItem(`${USERNAME_PREFIX}${boardId}`);
  localStorage.removeItem(`${NAME_PREFIX}${boardId}`);
  localStorage.removeItem(`${SUBTITLE_PREFIX}${boardId}`);
  localStorage.removeItem(`${ENCRYPTION_KEY_PREFIX}${boardId}`);
  localStorage.removeItem(`${EAUTH_PREFIX}${boardId}`);
}

// ─── 타입 ───

interface UseBoardOptions {
  boardId: string;
}

interface UseBoardReturn {
  // 상태
  status: BoardStatus;
  boardName: string | null;
  boardSubtitle: string | null;
  posts: DecryptedPost[];
  hasMore: boolean;
  myUsername: string;
  isPasswordSaved: boolean;
  adminToken: string | null;

  // 댓글 상태
  commentsMap: Record<string, DecryptedComment[]>;
  commentsHasMore: Record<string, boolean>;
  commentsLoading: boolean;

  // 액션
  authenticate: (password: string) => Promise<{ error?: string }>;
  loadMore: () => Promise<void>;
  submitPost: (title: string, content: string, images?: File[]) => Promise<{ error?: string }>;
  editPost: (postId: string, title: string, content: string) => Promise<{ error?: string }>;
  deletePost: (postId: string, adminToken?: string) => Promise<{ error?: string }>;
  submitReport: (postId: string, reason: ReportReason) => Promise<{ error?: string }>;
  refreshPosts: () => Promise<void>;
  forgetSavedPassword: () => void;
  saveAdminToken: (token: string) => void;
  forgetSavedAdminToken: () => void;
  decryptPostImages: (postId: string) => Promise<void>;
  updateSubtitle: (subtitle: string) => Promise<{ error?: string }>;

  // 초대 코드
  rotateInviteCode: () => Promise<{ inviteCode?: string; error?: string }>;

  // 공유
  initialPostId: string | null;
  clearInitialPostId: () => void;
  getShareUrl: (postId: string) => string;

  // 댓글 액션
  loadComments: (postId: string) => Promise<void>;
  loadMoreComments: (postId: string) => Promise<void>;
  submitComment: (postId: string, content: string, images?: File[]) => Promise<{ error?: string }>;
  deleteComment: (commentId: string, postId: string, adminToken?: string) => Promise<{ error?: string }>;
  submitCommentReport: (commentId: string, reason: ReportReason) => Promise<{ error?: string }>;
  decryptCommentImages: (commentId: string, postId: string) => Promise<void>;
}

export function useBoard({ boardId }: UseBoardOptions): UseBoardReturn {
  const [status, setStatus] = useState<BoardStatus>('loading');
  const [boardName, setBoardName] = useState<string | null>(null);
  const [boardSubtitle, setBoardSubtitle] = useState<string | null>(null);
  const [posts, setPosts] = useState<DecryptedPost[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [isPasswordSaved, setIsPasswordSaved] = useState(false);
  const [adminToken, setAdminToken] = useState<string | null>(null);

  // ─── 댓글 상태 ───
  const [commentsMap, setCommentsMap] = useState<Record<string, DecryptedComment[]>>({});
  const [commentsHasMore, setCommentsHasMore] = useState<Record<string, boolean>>({});
  const [commentsLoading, setCommentsLoading] = useState(false);
  const commentCursorsRef = useRef<Record<string, string | undefined>>({});
  const [initialPostId, setInitialPostId] = useState<string | null>(null);

  const encryptionKeyRef = useRef<Uint8Array | null>(null);
  const authKeyHashRef = useRef<string | null>(null);
  const usernameRef = useRef(getOrCreateUsername(boardId));
  const cursorRef = useRef<string | undefined>(undefined);
  const loadingRef = useRef(false);
  const isMountedRef = useRef(true);
  // 복호화된 blob URL 추적 (unmount 시 cleanup)
  const blobUrlsRef = useRef<Set<string>>(new Set());

  // blob URL cleanup on unmount
  useEffect(() => {
    isMountedRef.current = true;
    return () => {
      isMountedRef.current = false;
      blobUrlsRef.current.forEach((url) => URL.revokeObjectURL(url));
    };
  }, []);

  // ─── URL fragment 파싱 (#k=초대코드, #pw=비밀번호, #p=게시글ID) ───
  // Room의 RoomPageClient.tsx 패턴 재활용
  function parseUrlFragment(): { inviteCode?: string; password?: string; postId?: string } | null {
    if (typeof window === 'undefined') return null;

    const params = new URLSearchParams(
      window.location.hash.startsWith('#') ? window.location.hash.slice(1) : ''
    );

    // fallback: query parameter
    const searchParams = new URLSearchParams(window.location.search);

    const k = params.get('k') ?? searchParams.get('k');
    const pw = params.get('pw') ?? searchParams.get('pw');
    const p = params.get('p') ?? searchParams.get('p');

    if (!k && !pw && !p) return null;

    // URL에서 즉시 제거 (보안: fragment에 비밀번호 노출 방지)
    window.history.replaceState(null, '', window.location.pathname);

    return {
      inviteCode: k ? decodeURIComponent(k) : undefined,
      password: pw ? decodeURIComponent(pw) : undefined,
      postId: p ? decodeURIComponent(p) : undefined,
    };
  }

  // ─── 초대 코드로 인증 ───
  async function authenticateWithInviteCode(inviteCode: string): Promise<{ error?: string }> {
    try {
      // 1. 초대 코드 해시 → 서버 검증 → wrapped key 반환
      const codeHash = await hashInviteCode(inviteCode);
      const joinResult = await joinBoardViaInviteCode(boardId, codeHash);

      if ('error' in joinResult) {
        return { error: joinResult.error };
      }

      // 2. wrapping key 유도 → encryptionSeed unwrap
      const wrappingKey = await deriveWrappingKey(inviteCode, boardId);
      const encryptionSeed = unwrapEncryptionKey(
        joinResult.wrappedEncryptionKey,
        joinResult.wrappedKeyNonce,
        wrappingKey
      );

      if (!encryptionSeed) {
        return { error: 'UNWRAP_FAILED' };
      }

      // 3. encryptionKey 기반 인증 해시 유도
      const eAuthHash = await hashEncryptionKeyForAuth(encryptionSeed);

      // 4. 서버 인증 (eAuthHash로)
      const meta = await getBoardMeta(boardId, eAuthHash);

      if ('error' in meta) {
        return { error: meta.error };
      }

      if (meta.status === 'destroyed') {
        setStatus('destroyed');
        return { error: 'BOARD_DESTROYED' };
      }

      // 5. 인증 성공 → 키 저장
      encryptionKeyRef.current = encryptionSeed;
      authKeyHashRef.current = eAuthHash;

      saveEncryptionKey(boardId, encryptionSeed);
      saveEAuth(boardId, eAuthHash);

      // 6. 이름 복호화
      const name = decryptSymmetric(
        { ciphertext: meta.encryptedName, nonce: meta.encryptedNameNonce },
        encryptionSeed
      );
      setBoardName(name);
      if (name) saveBoardName(boardId, name);

      if (meta.encryptedSubtitle && meta.encryptedSubtitleNonce) {
        const subtitle = decryptSymmetric(
          { ciphertext: meta.encryptedSubtitle, nonce: meta.encryptedSubtitleNonce },
          encryptionSeed
        );
        setBoardSubtitle(subtitle);
        if (subtitle) saveBoardSubtitle(boardId, subtitle);
      }

      setStatus('browsing');
      await loadPostsInternal(eAuthHash, encryptionSeed);

      return {};
    } catch {
      return { error: 'INVITE_CODE_FAILED' };
    }
  }

  // ─── 저장된 encryptionKey로 인증 ───
  async function authenticateWithKey(
    encryptionSeed: Uint8Array,
    eAuthHash: string
  ): Promise<{ error?: string }> {
    try {
      const meta = await getBoardMeta(boardId, eAuthHash);

      if ('error' in meta) {
        // 저장된 키가 무효 → 삭제
        localStorage.removeItem(`${ENCRYPTION_KEY_PREFIX}${boardId}`);
        localStorage.removeItem(`${EAUTH_PREFIX}${boardId}`);
        return { error: meta.error };
      }

      if (meta.status === 'destroyed') {
        setStatus('destroyed');
        return { error: 'BOARD_DESTROYED' };
      }

      encryptionKeyRef.current = encryptionSeed;
      authKeyHashRef.current = eAuthHash;

      const name = decryptSymmetric(
        { ciphertext: meta.encryptedName, nonce: meta.encryptedNameNonce },
        encryptionSeed
      );
      setBoardName(name);
      if (name) saveBoardName(boardId, name);

      if (meta.encryptedSubtitle && meta.encryptedSubtitleNonce) {
        const subtitle = decryptSymmetric(
          { ciphertext: meta.encryptedSubtitle, nonce: meta.encryptedSubtitleNonce },
          encryptionSeed
        );
        setBoardSubtitle(subtitle);
        if (subtitle) saveBoardSubtitle(boardId, subtitle);
      }

      setStatus('browsing');
      await loadPostsInternal(eAuthHash, encryptionSeed);

      return {};
    } catch {
      return { error: 'KEY_AUTH_FAILED' };
    }
  }

  // 초기화: 4가지 인증 경로 (직접 키 → 비밀번호 → URL 초대코드 → URL 비밀번호)
  useEffect(() => {
    // 관리자 토큰 복원
    const savedToken = getSavedAdminToken(boardId);
    if (savedToken) {
      setAdminToken(savedToken);
    }

    // URL fragment 먼저 파싱 (인증 전에 추출해야 replaceState로 제거 가능)
    const fragment = parseUrlFragment();

    async function initAuth() {
      // 1순위: 저장된 encryptionKey (초대코드로 참여한 멤버)
      const savedKey = getSavedEncryptionKey(boardId);
      const savedEAuth = getSavedEAuth(boardId);
      if (savedKey && savedEAuth) {
        const result = await authenticateWithKey(savedKey, savedEAuth);
        if (!result.error) {
          if (getSavedPassword(boardId)) setIsPasswordSaved(true);
          return;
        }
        // 키 인증 실패 → 다음 경로로
      }

      // 2순위: 저장된 비밀번호 (password로 참여한 멤버)
      const savedPassword = getSavedPassword(boardId);
      if (savedPassword) {
        setIsPasswordSaved(true);
        const result = await authenticateInternal(savedPassword, true);
        if (!result.error) return;
        // 비밀번호 인증 실패 → 다음 경로로
      }

      // 3순위: URL fragment 초대 코드 (#k=...)
      if (fragment?.inviteCode) {
        const result = await authenticateWithInviteCode(fragment.inviteCode);
        if (!result.error) return;
      }

      // 4순위: URL fragment 비밀번호 (#pw=...)
      if (fragment?.password) {
        const result = await authenticateInternal(fragment.password, false);
        if (!result.error) return;
      }

      setStatus('password_required');
    }

    void initAuth().then(() => {
      // 인증 성공 후 URL fragment의 postId가 있으면 자동 네비게이션
      if (fragment?.postId) {
        setInitialPostId(fragment.postId);
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [boardId]);

  // ─── 내부 인증 로직 ───

  async function authenticateInternal(
    password: string,
    isSaved: boolean
  ): Promise<{ error?: string }> {
    try {
      const { authKey, encryptionSeed } = await deriveKeysFromPassword(password, boardId);
      const keyHash = await hashAuthKey(authKey);

      // 서버에서 메타데이터 조회 (인증 검증 포함)
      const meta = await getBoardMeta(boardId, keyHash);

      if ('error' in meta) {
        if (isSaved) {
          // 저장된 비밀번호가 잘못됨 → 삭제
          forgetPassword(boardId);
          setIsPasswordSaved(false);
        }
        setStatus('password_required');
        return { error: meta.error };
      }

      if (meta.status === 'destroyed') {
        setStatus('destroyed');
        return { error: 'BOARD_DESTROYED' };
      }

      // 인증 성공
      encryptionKeyRef.current = encryptionSeed;
      authKeyHashRef.current = keyHash;

      // encryptionKey + eAuth도 저장 (초대 코드 갱신 후에도 접속 유지)
      saveEncryptionKey(boardId, encryptionSeed);
      const eAuthHash = await hashEncryptionKeyForAuth(encryptionSeed);
      saveEAuth(boardId, eAuthHash);

      // 레거시 마이그레이션: 서버에 encryption_key_auth_hash 설정
      void updateEncryptionKeyAuthHash(boardId, keyHash, eAuthHash);

      // 게시판 이름 복호화
      const name = decryptSymmetric(
        { ciphertext: meta.encryptedName, nonce: meta.encryptedNameNonce },
        encryptionSeed
      );
      setBoardName(name);

      // 이름 캐시 (대시보드 목록용)
      if (name) saveBoardName(boardId, name);

      // 부제목 복호화 (옵셔널)
      if (meta.encryptedSubtitle && meta.encryptedSubtitleNonce) {
        const subtitle = decryptSymmetric(
          { ciphertext: meta.encryptedSubtitle, nonce: meta.encryptedSubtitleNonce },
          encryptionSeed
        );
        setBoardSubtitle(subtitle);
        if (subtitle) saveBoardSubtitle(boardId, subtitle);
      } else {
        setBoardSubtitle(null);
      }

      setStatus('browsing');

      // 게시글 로드
      await loadPostsInternal(keyHash, encryptionSeed);

      return {};
    } catch {
      setStatus('error');
      return { error: 'AUTHENTICATION_FAILED' };
    }
  }

  // ─── 게시글 로드 ───

  async function loadPostsInternal(
    keyHash: string,
    key: Uint8Array,
    cursor?: string
  ): Promise<void> {
    if (loadingRef.current) return;
    loadingRef.current = true;

    try {
      const result = await getPosts(boardId, keyHash, cursor);
      if (!isMountedRef.current) return;

      if ('error' in result) return;

      const decrypted: DecryptedPost[] = result.posts.map((p) => {
        if (p.isBlinded) {
          return {
            id: p.id,
            authorName: '',
            title: '',
            content: '',
            createdAt: p.createdAt,
            isBlinded: true,
            isMine: false,
            images: [],
          };
        }

        const authorName = decryptSymmetric(
          { ciphertext: p.authorNameEncrypted, nonce: p.authorNameNonce },
          key
        );
        const title =
          p.titleEncrypted && p.titleNonce
            ? decryptSymmetric({ ciphertext: p.titleEncrypted, nonce: p.titleNonce }, key)
            : '';
        const content = decryptSymmetric(
          { ciphertext: p.contentEncrypted, nonce: p.contentNonce },
          key
        );

        return {
          id: p.id,
          authorName: authorName ?? '[DECRYPTION FAILED]',
          title: title ?? '',
          content: content ?? '[DECRYPTION FAILED]',
          createdAt: p.createdAt,
          isBlinded: false,
          isMine: authorName === usernameRef.current,
          commentCount: p.commentCount ?? 0,
          // 이미지 메타데이터만 저장 (복호화는 lazy)
          images: [],
          _encryptedImages: p.images.map((img) => ({
            id: img.id,
            encryptedNonce: img.encryptedNonce,
            mimeType: img.mimeType,
            width: img.width,
            height: img.height,
          })),
        };
      });

      if (cursor) {
        setPosts((prev) => [...prev, ...decrypted]);
      } else {
        // refresh 시 이미 복호화된 이미지 바이트 보존
        setPosts((prev) => {
          if (prev.length === 0) return decrypted;
          const oldImageMap = new Map<string, DecryptedPostImage[]>();
          for (const p of prev) {
            if (p.images.length > 0) {
              oldImageMap.set(p.id, p.images);
            }
          }
          if (oldImageMap.size === 0) return decrypted;
          return decrypted.map((post) => {
            const cached = oldImageMap.get(post.id);
            if (cached && cached.length > 0 && post.images.length === 0) {
              return { ...post, images: cached };
            }
            return post;
          });
        });
      }

      if (!isMountedRef.current) return;
      setHasMore(result.hasMore);
      if (result.posts.length > 0) {
        cursorRef.current = result.posts[result.posts.length - 1].id;
      }
    } finally {
      loadingRef.current = false;
    }
  }

  // ─── 이미지 복호화 (lazy) ───

  async function decryptPostImagesInternal(postId: string): Promise<void> {
    const key = encryptionKeyRef.current;
    const keyHash = authKeyHashRef.current;
    if (!key || !keyHash) return;

    const post = posts.find((p) => p.id === postId);
    if (!post?._encryptedImages || post._encryptedImages.length === 0) return;
    if (post.images.length > 0) return; // 이미 복호화됨

    const decryptedImages: DecryptedPostImage[] = [];

    for (const imgMeta of post._encryptedImages) {
      try {
        const res = await fetch(
          `/api/board/image?imageId=${imgMeta.id}&authKeyHash=${encodeURIComponent(keyHash)}`
        );
        if (!res.ok) continue;

        const encryptedBuffer = await res.arrayBuffer();

        // imgMeta에서 직접 nonce 사용 (X-Encrypted-Nonce 헤더보다 안정적)
        const decrypted = decryptBinaryRaw(
          new Uint8Array(encryptedBuffer),
          decodeBase64(imgMeta.encryptedNonce),
          key
        );
        if (!decrypted) continue;

        const blob = new Blob([new Uint8Array(decrypted)], { type: imgMeta.mimeType });
        const objectUrl = URL.createObjectURL(blob);
        blobUrlsRef.current.add(objectUrl);

        decryptedImages.push({
          id: imgMeta.id,
          objectUrl,
          mimeType: imgMeta.mimeType,
          width: imgMeta.width,
          height: imgMeta.height,
        });
      } catch {
        // 개별 이미지 복호화 실패 무시
      }
    }

    if (!isMountedRef.current) return;
    if (decryptedImages.length > 0) {
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId ? { ...p, images: decryptedImages } : p
        )
      );
    }
  }

  // ─── 미디어 업로드 (이미지 + 동영상) ───

  async function uploadImages(
    postId: string,
    files: File[],
    key: Uint8Array,
    keyHash: string,
    commentId?: string
  ): Promise<void> {
    for (let i = 0; i < files.length; i++) {
      try {
        const mediaType = getMediaType(files[i].type);
        if (!mediaType) continue; // 지원하지 않는 파일 형식 건너뛰기

        let buffer: Uint8Array;
        let width = 0;
        let height = 0;

        if (mediaType === 'video') {
          // 동영상: 압축 없이 raw 바이트 암호화
          buffer = new Uint8Array(await files[i].arrayBuffer());
          try {
            const { metadata } = await createVideoThumbnail(files[i]);
            width = metadata.width;
            height = metadata.height;
          } catch {
            // 메타데이터 추출 실패 시 0으로 유지
          }
        } else {
          // 이미지: 압축 후 암호화
          const compressed = await compressImage(files[i]);
          buffer = new Uint8Array(await compressed.blob.arrayBuffer());
          width = compressed.width;
          height = compressed.height;
        }

        // 암호화
        const encrypted = encryptBinary(buffer, key);
        const ciphertextBytes = decodeBase64(encrypted.ciphertext);

        // FormData
        const formData = new FormData();
        formData.append('file', new Blob([new Uint8Array(ciphertextBytes)]), 'media.enc');
        formData.append('boardId', boardId);
        if (commentId) {
          formData.append('commentId', commentId);
        } else {
          formData.append('postId', postId);
        }
        formData.append('authKeyHash', keyHash);
        formData.append('nonce', encrypted.nonce);
        formData.append('mimeType', files[i].type || 'application/octet-stream');
        formData.append('width', String(width));
        formData.append('height', String(height));
        formData.append('displayOrder', String(i));

        await fetch('/api/board/upload-image', {
          method: 'POST',
          body: formData,
        });
      } catch {
        // 개별 미디어 업로드 실패 무시 (게시글은 이미 생성됨)
      }
    }
  }

  // ─── 공개 API ───

  const authenticate = useCallback(
    async (password: string): Promise<{ error?: string }> => {
      const result = await authenticateInternal(password, false);
      if (!result.error) {
        // 인증 성공 시 항상 비밀번호 자동 저장
        savePassword(boardId, password);
        setIsPasswordSaved(true);
      }
      return result;
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [boardId]
  );

  const loadMore = useCallback(async () => {
    if (!authKeyHashRef.current || !encryptionKeyRef.current) return;
    await loadPostsInternal(
      authKeyHashRef.current,
      encryptionKeyRef.current,
      cursorRef.current
    );
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [boardId]);

  const submitPost = useCallback(
    async (title: string, content: string, images?: File[]): Promise<{ error?: string }> => {
      if (!authKeyHashRef.current || !encryptionKeyRef.current) {
        return { error: 'NOT_AUTHENTICATED' };
      }

      const trimmedTitle = title.trim();
      const trimmedContent = content.trim();
      if (!trimmedTitle && !trimmedContent && (!images || images.length === 0)) {
        return { error: 'EMPTY_CONTENT' };
      }

      const encName = encryptSymmetric(usernameRef.current, encryptionKeyRef.current);
      const encContent = encryptSymmetric(trimmedContent || ' ', encryptionKeyRef.current);

      // title 암호화 (비어있으면 null)
      let titleEncrypted: string | undefined;
      let titleNonce: string | undefined;
      if (trimmedTitle) {
        const encTitle = encryptSymmetric(trimmedTitle, encryptionKeyRef.current);
        titleEncrypted = encTitle.ciphertext;
        titleNonce = encTitle.nonce;
      }

      const result = await createPost(
        boardId,
        authKeyHashRef.current,
        encName.ciphertext,
        encName.nonce,
        encContent.ciphertext,
        encContent.nonce,
        titleEncrypted,
        titleNonce
      );

      if ('error' in result) return { error: result.error };

      // 이미지 업로드 (게시글 생성 후)
      if (images && images.length > 0) {
        await uploadImages(
          result.postId,
          images,
          encryptionKeyRef.current,
          authKeyHashRef.current
        );
      }

      // 새 글을 목록 맨 앞에 추가 (서버 재조회 없이)
      // 이미지가 있으면 로컬 preview blob URL 생성
      const localImages: DecryptedPostImage[] = (images ?? []).map((file, i) => ({
        id: `local-${i}`,
        objectUrl: URL.createObjectURL(file),
        mimeType: file.type,
        width: null,
        height: null,
      }));
      localImages.forEach((img) => blobUrlsRef.current.add(img.objectUrl));

      const newPost: DecryptedPost = {
        id: result.postId,
        authorName: usernameRef.current,
        title: trimmedTitle,
        content: trimmedContent,
        createdAt: new Date().toISOString(),
        isBlinded: false,
        isMine: true,
        images: localImages,
      };
      setPosts((prev) => [newPost, ...prev]);

      return {};
    },
    [boardId]
  );

  const editPost = useCallback(
    async (postId: string, title: string, content: string): Promise<{ error?: string }> => {
      if (!authKeyHashRef.current || !encryptionKeyRef.current) {
        return { error: 'NOT_AUTHENTICATED' };
      }

      const trimmedTitle = title.trim();
      const trimmedContent = content.trim();
      if (!trimmedTitle && !trimmedContent) {
        return { error: 'EMPTY_CONTENT' };
      }

      const encName = encryptSymmetric(usernameRef.current, encryptionKeyRef.current);
      const encContent = encryptSymmetric(trimmedContent || ' ', encryptionKeyRef.current);

      let titleEncrypted: string | undefined;
      let titleNonce: string | undefined;
      if (trimmedTitle) {
        const encTitle = encryptSymmetric(trimmedTitle, encryptionKeyRef.current);
        titleEncrypted = encTitle.ciphertext;
        titleNonce = encTitle.nonce;
      }

      const result = await updatePost(
        boardId,
        postId,
        authKeyHashRef.current,
        encName.ciphertext,
        encName.nonce,
        encContent.ciphertext,
        encContent.nonce,
        titleEncrypted,
        titleNonce
      );

      if ('error' in result) return { error: result.error };

      // 로컬 상태 업데이트
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId
            ? { ...p, title: trimmedTitle, content: trimmedContent }
            : p
        )
      );

      return {};
    },
    [boardId]
  );

  const deletePost = useCallback(
    async (postId: string, adminToken?: string): Promise<{ error?: string }> => {
      let result: { success: boolean; error?: string };

      if (adminToken) {
        // 관리자 삭제
        result = await adminDeletePost(boardId, postId, adminToken);
      } else {
        // 본인 삭제 (authKeyHash로 인증)
        if (!authKeyHashRef.current) return { error: 'NOT_AUTHENTICATED' };
        result = await deleteOwnPost(boardId, postId, authKeyHashRef.current);
      }

      if (!result.success) return { error: result.error };

      // 로컬 상태에서 제거
      setPosts((prev) => prev.filter((p) => p.id !== postId));
      return {};
    },
    [boardId]
  );

  const submitReport = useCallback(
    async (postId: string, reason: ReportReason): Promise<{ error?: string }> => {
      if (!authKeyHashRef.current) return { error: 'NOT_AUTHENTICATED' };

      const result = await reportPost(boardId, postId, authKeyHashRef.current, reason);
      if (!result.success) return { error: result.error };

      return {};
    },
    [boardId]
  );

  const refreshPosts = useCallback(async () => {
    if (!authKeyHashRef.current || !encryptionKeyRef.current) return;
    cursorRef.current = undefined;
    await loadPostsInternal(authKeyHashRef.current, encryptionKeyRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [boardId]);

  const forgetSavedPassword = useCallback(() => {
    forgetPassword(boardId);
    setIsPasswordSaved(false);
  }, [boardId]);

  const saveAdminTokenFn = useCallback(
    (token: string) => {
      saveAdminTokenToStorage(boardId, token);
      setAdminToken(token);
    },
    [boardId]
  );

  const forgetSavedAdminToken = useCallback(() => {
    forgetAdminToken(boardId);
    setAdminToken(null);
  }, [boardId]);

  const updateSubtitleFn = useCallback(
    async (subtitle: string): Promise<{ error?: string }> => {
      if (!adminToken || !encryptionKeyRef.current) {
        return { error: 'NOT_ADMIN' };
      }

      const trimmed = subtitle.trim();

      if (trimmed) {
        const enc = encryptSymmetric(trimmed, encryptionKeyRef.current);
        const result = await updateBoardSubtitle(
          boardId,
          adminToken,
          enc.ciphertext,
          enc.nonce
        );
        if (!result.success) return { error: result.error };
        setBoardSubtitle(trimmed);
        saveBoardSubtitle(boardId, trimmed);
      } else {
        // 빈 문자열 → 부제목 삭제
        const result = await updateBoardSubtitle(boardId, adminToken);
        if (!result.success) return { error: result.error };
        setBoardSubtitle(null);
        if (typeof window !== 'undefined') {
          localStorage.removeItem(`${SUBTITLE_PREFIX}${boardId}`);
        }
      }

      return {};
    },
    [boardId, adminToken]
  );

  const decryptPostImages = useCallback(
    async (postId: string) => {
      await decryptPostImagesInternal(postId);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [posts, boardId]
  );

  // ─── 댓글 로드 ───

  const loadCommentsInternal = useCallback(
    async (postId: string, cursor?: string) => {
      const key = encryptionKeyRef.current;
      const keyHash = authKeyHashRef.current;
      if (!key || !keyHash) return;

      setCommentsLoading(true);
      try {
        const result = await getComments(boardId, postId, keyHash, cursor);
        if (!isMountedRef.current) return;
        if ('error' in result) return;

        const decrypted: DecryptedComment[] = result.comments.map((c) => {
          if (c.isBlinded) {
            return {
              id: c.id,
              postId: c.postId,
              authorName: '',
              content: '',
              createdAt: c.createdAt,
              isBlinded: true,
              isMine: false,
              images: [],
            };
          }

          const authorName = decryptSymmetric(
            { ciphertext: c.authorNameEncrypted, nonce: c.authorNameNonce },
            key
          );
          const content = decryptSymmetric(
            { ciphertext: c.contentEncrypted, nonce: c.contentNonce },
            key
          );

          return {
            id: c.id,
            postId: c.postId,
            authorName: authorName ?? '[DECRYPTION FAILED]',
            content: content ?? '[DECRYPTION FAILED]',
            createdAt: c.createdAt,
            isBlinded: false,
            isMine: authorName === usernameRef.current,
            images: [],
            _encryptedImages: c.images.map((img) => ({
              id: img.id,
              encryptedNonce: img.encryptedNonce,
              mimeType: img.mimeType,
              width: img.width,
              height: img.height,
            })),
          };
        });

        setCommentsMap((prev) => ({
          ...prev,
          [postId]: cursor ? [...(prev[postId] ?? []), ...decrypted] : decrypted,
        }));
        setCommentsHasMore((prev) => ({ ...prev, [postId]: result.hasMore }));
        if (result.comments.length > 0) {
          commentCursorsRef.current[postId] = result.comments[result.comments.length - 1].id;
        }
      } finally {
        if (isMountedRef.current) setCommentsLoading(false);
      }
    },
    [boardId]
  );

  const loadComments = useCallback(
    async (postId: string) => {
      commentCursorsRef.current[postId] = undefined;
      await loadCommentsInternal(postId);
    },
    [loadCommentsInternal]
  );

  const loadMoreComments = useCallback(
    async (postId: string) => {
      await loadCommentsInternal(postId, commentCursorsRef.current[postId]);
    },
    [loadCommentsInternal]
  );

  // ─── 댓글 작성 ───

  const submitComment = useCallback(
    async (postId: string, content: string, images?: File[]): Promise<{ error?: string }> => {
      if (!authKeyHashRef.current || !encryptionKeyRef.current) {
        return { error: 'NOT_AUTHENTICATED' };
      }

      const trimmed = content.trim();
      if (!trimmed && (!images || images.length === 0)) {
        return { error: 'EMPTY_CONTENT' };
      }

      const encName = encryptSymmetric(usernameRef.current, encryptionKeyRef.current);
      const encContent = encryptSymmetric(trimmed || ' ', encryptionKeyRef.current);

      const result = await createComment(
        boardId,
        postId,
        authKeyHashRef.current,
        encName.ciphertext,
        encName.nonce,
        encContent.ciphertext,
        encContent.nonce
      );

      if ('error' in result) return { error: result.error };

      // 이미지 업로드
      if (images && images.length > 0) {
        await uploadImages(
          postId,
          images,
          encryptionKeyRef.current,
          authKeyHashRef.current,
          result.commentId
        );
      }

      // 로컬 미리보기 이미지
      const localImages: DecryptedPostImage[] = (images ?? []).map((file, i) => ({
        id: `local-comment-${i}`,
        objectUrl: URL.createObjectURL(file),
        mimeType: file.type,
        width: null,
        height: null,
      }));
      localImages.forEach((img) => blobUrlsRef.current.add(img.objectUrl));

      const newComment: DecryptedComment = {
        id: result.commentId,
        postId,
        authorName: usernameRef.current,
        content: trimmed,
        createdAt: new Date().toISOString(),
        isBlinded: false,
        isMine: true,
        images: localImages,
      };

      setCommentsMap((prev) => ({
        ...prev,
        [postId]: [...(prev[postId] ?? []), newComment],
      }));

      // 게시글의 commentCount 증가
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId ? { ...p, commentCount: (p.commentCount ?? 0) + 1 } : p
        )
      );

      return {};
    },
    [boardId]
  );

  // ─── 댓글 삭제 ───

  const deleteCommentFn = useCallback(
    async (commentId: string, postId: string, token?: string): Promise<{ error?: string }> => {
      let result: { success: boolean; error?: string };

      if (token) {
        result = await adminDeleteComment(boardId, commentId, token);
      } else {
        if (!authKeyHashRef.current) return { error: 'NOT_AUTHENTICATED' };
        result = await deleteOwnComment(boardId, commentId, authKeyHashRef.current);
      }

      if (!result.success) return { error: result.error };

      // 로컬 상태에서 제거
      setCommentsMap((prev) => ({
        ...prev,
        [postId]: (prev[postId] ?? []).filter((c) => c.id !== commentId),
      }));

      // commentCount 감소
      setPosts((prev) =>
        prev.map((p) =>
          p.id === postId ? { ...p, commentCount: Math.max(0, (p.commentCount ?? 0) - 1) } : p
        )
      );

      return {};
    },
    [boardId]
  );

  // ─── 댓글 신고 ───

  const submitCommentReport = useCallback(
    async (commentId: string, reason: ReportReason): Promise<{ error?: string }> => {
      if (!authKeyHashRef.current) return { error: 'NOT_AUTHENTICATED' };
      const result = await reportComment(boardId, commentId, authKeyHashRef.current, reason);
      if (!result.success) return { error: result.error };
      return {};
    },
    [boardId]
  );

  // ─── 댓글 이미지 복호화 (lazy) ───

  // ─── 초대 코드 갱신 (관리자) ───

  const rotateInviteCodeFn = useCallback(
    async (): Promise<{ inviteCode?: string; error?: string }> => {
      if (!adminToken || !encryptionKeyRef.current) {
        return { error: 'NOT_ADMIN' };
      }

      try {
        // 새 초대 코드 생성
        const newInviteCode = generateInviteCode();
        const newCodeHash = await hashInviteCode(newInviteCode);

        // encryptionSeed를 새 코드로 wrap
        const newWrappingKey = await deriveWrappingKey(newInviteCode, boardId);
        const wrapped = wrapEncryptionKey(encryptionKeyRef.current, newWrappingKey);

        // 서버에 저장
        const result = await rotateInviteCodeAction(
          boardId,
          adminToken,
          newCodeHash,
          wrapped.ciphertext,
          wrapped.nonce
        );

        if (!result.success) return { error: result.error };

        return { inviteCode: newInviteCode };
      } catch {
        return { error: 'ROTATE_FAILED' };
      }
    },
    [boardId, adminToken]
  );

  const decryptCommentImagesFn = useCallback(
    async (commentId: string, postId: string) => {
      const key = encryptionKeyRef.current;
      const keyHash = authKeyHashRef.current;
      if (!key || !keyHash) return;

      const comments = commentsMap[postId] ?? [];
      const comment = comments.find((c) => c.id === commentId);
      if (!comment?._encryptedImages || comment._encryptedImages.length === 0) return;
      if (comment.images.length > 0) return;

      const decryptedImages: DecryptedPostImage[] = [];

      for (const imgMeta of comment._encryptedImages) {
        try {
          const res = await fetch(
            `/api/board/image?imageId=${imgMeta.id}&authKeyHash=${encodeURIComponent(keyHash)}`
          );
          if (!res.ok) continue;

          const encryptedBuffer = await res.arrayBuffer();
          const decrypted = decryptBinaryRaw(
            new Uint8Array(encryptedBuffer),
            decodeBase64(imgMeta.encryptedNonce),
            key
          );
          if (!decrypted) continue;

          const blob = new Blob([new Uint8Array(decrypted)], { type: imgMeta.mimeType });
          const objectUrl = URL.createObjectURL(blob);
          blobUrlsRef.current.add(objectUrl);

          decryptedImages.push({
            id: imgMeta.id,
            objectUrl,
            mimeType: imgMeta.mimeType,
            width: imgMeta.width,
            height: imgMeta.height,
          });
        } catch {
          // 개별 이미지 복호화 실패 무시
        }
      }

      if (!isMountedRef.current || decryptedImages.length === 0) return;

      setCommentsMap((prev) => ({
        ...prev,
        [postId]: (prev[postId] ?? []).map((c) =>
          c.id === commentId ? { ...c, images: decryptedImages } : c
        ),
      }));
    },
    [commentsMap, boardId]
  );

  return {
    status,
    boardName,
    boardSubtitle,
    posts,
    hasMore,
    myUsername: usernameRef.current,
    isPasswordSaved,
    adminToken,

    // 댓글 상태
    commentsMap,
    commentsHasMore,
    commentsLoading,

    authenticate,
    loadMore,
    submitPost,
    editPost,
    deletePost,
    submitReport,
    refreshPosts,
    forgetSavedPassword,
    saveAdminToken: saveAdminTokenFn,
    forgetSavedAdminToken,
    decryptPostImages,
    updateSubtitle: updateSubtitleFn,
    rotateInviteCode: rotateInviteCodeFn,

    // 공유
    initialPostId,
    clearInitialPostId: () => setInitialPostId(null),
    getShareUrl: (postId: string) => {
      const pw = getSavedPassword(boardId);
      const origin = typeof window !== 'undefined' ? window.location.origin : '';
      const locale = typeof window !== 'undefined' ? window.location.pathname.split('/')[1] : 'en';
      const base = `${origin}/${locale}/board/${boardId}`;
      return pw
        ? `${base}#pw=${encodeURIComponent(pw)}&p=${postId}`
        : `${base}#p=${postId}`;
    },

    // 댓글 액션
    loadComments,
    loadMoreComments,
    submitComment,
    deleteComment: deleteCommentFn,
    submitCommentReport,
    decryptCommentImages: decryptCommentImagesFn,
  };
}
