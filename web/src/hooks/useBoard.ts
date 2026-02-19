'use client';

import { useState, useCallback, useRef, useEffect } from 'react';
import {
  deriveKeysFromPassword,
  hashAuthKey,
  encryptSymmetric,
  decryptSymmetric,
  encryptBinary,
  decryptBinaryRaw,
} from '@/lib/crypto';
import { decodeBase64 } from 'tweetnacl-util';
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
} from '@/lib/board/actions';
import type { DecryptedPost, DecryptedPostImage, BoardStatus, ReportReason } from '@/types/board';

// ─── localStorage 헬퍼 ───

const STORAGE_PREFIX = 'blip-board-';
const ADMIN_PREFIX = 'blip-board-admin-';
const USERNAME_PREFIX = 'blip-board-user-';
const NAME_PREFIX = 'blip-board-name-';

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

// ─── 저장된 커뮤니티 목록 (대시보드용) ───

export interface SavedBoard {
  boardId: string;
  name: string | null;
  hasAdminToken: boolean;
}

/** localStorage에서 저장된 커뮤니티 목록을 반환 */
export function getSavedBoards(): SavedBoard[] {
  if (typeof window === 'undefined') return [];
  const boards: SavedBoard[] = [];
  for (let i = 0; i < localStorage.length; i++) {
    const key = localStorage.key(i);
    if (!key?.startsWith(STORAGE_PREFIX)) continue;
    // admin/user/name prefix 제외
    if (key.startsWith(ADMIN_PREFIX) || key.startsWith(USERNAME_PREFIX) || key.startsWith(NAME_PREFIX)) continue;
    const boardId = key.slice(STORAGE_PREFIX.length);
    boards.push({
      boardId,
      name: getSavedBoardName(boardId),
      hasAdminToken: !!getSavedAdminToken(boardId),
    });
  }
  return boards;
}

/** 커뮤니티의 모든 로컬 데이터를 삭제 */
export function removeSavedBoard(boardId: string): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(`${STORAGE_PREFIX}${boardId}`);
  localStorage.removeItem(`${ADMIN_PREFIX}${boardId}`);
  localStorage.removeItem(`${USERNAME_PREFIX}${boardId}`);
  localStorage.removeItem(`${NAME_PREFIX}${boardId}`);
}

// ─── 타입 ───

interface UseBoardOptions {
  boardId: string;
}

interface UseBoardReturn {
  // 상태
  status: BoardStatus;
  boardName: string | null;
  posts: DecryptedPost[];
  hasMore: boolean;
  myUsername: string;
  isPasswordSaved: boolean;
  adminToken: string | null;

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
}

export function useBoard({ boardId }: UseBoardOptions): UseBoardReturn {
  const [status, setStatus] = useState<BoardStatus>('loading');
  const [boardName, setBoardName] = useState<string | null>(null);
  const [posts, setPosts] = useState<DecryptedPost[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [isPasswordSaved, setIsPasswordSaved] = useState(false);
  const [adminToken, setAdminToken] = useState<string | null>(null);

  const encryptionKeyRef = useRef<Uint8Array | null>(null);
  const authKeyHashRef = useRef<string | null>(null);
  const usernameRef = useRef(getOrCreateUsername(boardId));
  const cursorRef = useRef<string | undefined>(undefined);
  const loadingRef = useRef(false);
  // 복호화된 blob URL 추적 (unmount 시 cleanup)
  const blobUrlsRef = useRef<Set<string>>(new Set());

  // blob URL cleanup on unmount
  useEffect(() => {
    return () => {
      blobUrlsRef.current.forEach((url) => URL.revokeObjectURL(url));
    };
  }, []);

  // 초기화: localStorage에서 저장된 비밀번호 + 관리자 토큰 확인
  useEffect(() => {
    // 관리자 토큰 복원
    const savedToken = getSavedAdminToken(boardId);
    if (savedToken) {
      setAdminToken(savedToken);
    }

    const saved = getSavedPassword(boardId);
    if (saved) {
      setIsPasswordSaved(true);
      // 자동 인증 시도
      void authenticateInternal(saved, true);
    } else {
      setStatus('password_required');
    }
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

      // 게시판 이름 복호화
      const name = decryptSymmetric(
        { ciphertext: meta.encryptedName, nonce: meta.encryptedNameNonce },
        encryptionSeed
      );
      setBoardName(name);

      // 이름 캐시 (대시보드 목록용)
      if (name) saveBoardName(boardId, name);

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
    keyHash: string
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
        formData.append('postId', postId);
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

  const decryptPostImages = useCallback(
    async (postId: string) => {
      await decryptPostImagesInternal(postId);
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [posts, boardId]
  );

  return {
    status,
    boardName,
    posts,
    hasMore,
    myUsername: usernameRef.current,
    isPasswordSaved,
    adminToken,
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
  };
}
