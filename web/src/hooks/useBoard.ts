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
import {
  getPosts,
  createPost,
  reportPost,
  getBoardMeta,
} from '@/lib/board/actions';
import type { DecryptedPost, DecryptedPostImage, BoardStatus, ReportReason } from '@/types/board';

// ─── localStorage 헬퍼 ───

const STORAGE_PREFIX = 'blip-board-';

function getSavedPassword(boardId: string): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem(`${STORAGE_PREFIX}${boardId}`);
}

function savePassword(boardId: string, password: string): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(`${STORAGE_PREFIX}${boardId}`, password);
}

function forgetPassword(boardId: string): void {
  if (typeof window === 'undefined') return;
  localStorage.removeItem(`${STORAGE_PREFIX}${boardId}`);
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

  // 액션
  authenticate: (password: string, remember: boolean) => Promise<{ error?: string }>;
  loadMore: () => Promise<void>;
  submitPost: (content: string, images?: File[]) => Promise<{ error?: string }>;
  submitReport: (postId: string, reason: ReportReason) => Promise<{ error?: string }>;
  refreshPosts: () => Promise<void>;
  forgetSavedPassword: () => void;
  decryptPostImages: (postId: string) => Promise<void>;
}

export function useBoard({ boardId }: UseBoardOptions): UseBoardReturn {
  const [status, setStatus] = useState<BoardStatus>('loading');
  const [boardName, setBoardName] = useState<string | null>(null);
  const [posts, setPosts] = useState<DecryptedPost[]>([]);
  const [hasMore, setHasMore] = useState(false);
  const [isPasswordSaved, setIsPasswordSaved] = useState(false);

  const encryptionKeyRef = useRef<Uint8Array | null>(null);
  const authKeyHashRef = useRef<string | null>(null);
  const usernameRef = useRef(generateUsername());
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

  // 초기화: localStorage에서 저장된 비밀번호 확인
  useEffect(() => {
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
        const content = decryptSymmetric(
          { ciphertext: p.contentEncrypted, nonce: p.contentNonce },
          key
        );

        return {
          id: p.id,
          authorName: authorName ?? '[DECRYPTION FAILED]',
          content: content ?? '[DECRYPTION FAILED]',
          createdAt: p.createdAt,
          isBlinded: false,
          isMine: authorName === usernameRef.current,
          // 이미지 메타데이터만 저장 (복호화는 lazy)
          images: [],
          _encryptedImages: p.images,
        } as DecryptedPost & { _encryptedImages: typeof p.images };
      });

      if (cursor) {
        setPosts((prev) => [...prev, ...decrypted]);
      } else {
        setPosts(decrypted);
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

    const post = posts.find((p) => p.id === postId) as
      | (DecryptedPost & { _encryptedImages?: Array<{ id: string; encryptedNonce: string; mimeType: string; width: number | null; height: number | null }> })
      | undefined;

    if (!post?._encryptedImages || post._encryptedImages.length === 0) return;
    if (post.images.length > 0) return; // 이미 복호화됨

    const decryptedImages: DecryptedPostImage[] = [];

    for (const imgMeta of post._encryptedImages) {
      try {
        const res = await fetch(
          `/api/board/image?imageId=${imgMeta.id}&authKeyHash=${encodeURIComponent(keyHash)}`
        );
        if (!res.ok) continue;

        const nonce = res.headers.get('X-Encrypted-Nonce');
        if (!nonce) continue;

        const encryptedBuffer = await res.arrayBuffer();
        const decrypted = decryptBinaryRaw(
          new Uint8Array(encryptedBuffer),
          decodeBase64(nonce),
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
        // 개별 이미지 실패 무시
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

  // ─── 이미지 업로드 ───

  async function uploadImages(
    postId: string,
    files: File[],
    key: Uint8Array,
    keyHash: string
  ): Promise<void> {
    for (let i = 0; i < files.length; i++) {
      try {
        // 압축
        const { blob, width, height } = await compressImage(files[i]);
        const buffer = new Uint8Array(await blob.arrayBuffer());

        // 암호화
        const encrypted = encryptBinary(buffer, key);
        const ciphertextBytes = decodeBase64(encrypted.ciphertext);

        // FormData
        const formData = new FormData();
        formData.append('file', new Blob([new Uint8Array(ciphertextBytes)]), 'image.enc');
        formData.append('boardId', boardId);
        formData.append('postId', postId);
        formData.append('authKeyHash', keyHash);
        formData.append('nonce', encrypted.nonce);
        formData.append('mimeType', files[i].type || 'image/jpeg');
        formData.append('width', String(width));
        formData.append('height', String(height));
        formData.append('displayOrder', String(i));

        await fetch('/api/board/upload-image', {
          method: 'POST',
          body: formData,
        });
      } catch {
        // 개별 이미지 업로드 실패 무시 (게시글은 이미 생성됨)
      }
    }
  }

  // ─── 공개 API ───

  const authenticate = useCallback(
    async (password: string, remember: boolean): Promise<{ error?: string }> => {
      const result = await authenticateInternal(password, false);
      if (!result.error && remember) {
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
    async (content: string, images?: File[]): Promise<{ error?: string }> => {
      if (!authKeyHashRef.current || !encryptionKeyRef.current) {
        return { error: 'NOT_AUTHENTICATED' };
      }

      const trimmed = content.trim();
      if (!trimmed && (!images || images.length === 0)) return { error: 'EMPTY_CONTENT' };

      const encName = encryptSymmetric(usernameRef.current, encryptionKeyRef.current);
      const encContent = encryptSymmetric(trimmed || ' ', encryptionKeyRef.current);

      const result = await createPost(
        boardId,
        authKeyHashRef.current,
        encName.ciphertext,
        encName.nonce,
        encContent.ciphertext,
        encContent.nonce
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
        content: trimmed,
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
    authenticate,
    loadMore,
    submitPost,
    submitReport,
    refreshPosts,
    forgetSavedPassword,
    decryptPostImages,
  };
}
