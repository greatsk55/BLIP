'use server';

import { headers } from 'next/headers';
import { createServerSupabase } from '@/lib/supabase/server';
import { generateRoomId, generateRoomPassword } from '@/lib/room/password';
import {
  deriveKeysFromPassword,
  hashAuthKey,
  generateInviteCode,
  deriveWrappingKey,
  wrapEncryptionKey,
  hashEncryptionKeyForAuth,
  hashInviteCode,
} from '@/lib/crypto';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { encodeBase64 } from 'tweetnacl-util';

// ─── Rate Limit 설정 ───

const CREATE_BOARD_LIMIT = { windowMs: 3_600_000, maxRequests: 2 };
const JOIN_BOARD_LIMIT = { windowMs: 3_600_000, maxRequests: 10 };
const CREATE_POST_LIMIT = { windowMs: 60_000, maxRequests: 5 };
const CREATE_COMMENT_LIMIT = { windowMs: 60_000, maxRequests: 10 };
const DELETE_COMMENT_LIMIT = { windowMs: 60_000, maxRequests: 5 };
const REPORT_POST_LIMIT = { windowMs: 3_600_000, maxRequests: 10 };
const ADMIN_LIMIT = { windowMs: 3_600_000, maxRequests: 20 };

const BLIND_THRESHOLD = 3;

// ─── 유틸리티 ───

/** 이중 인증: password-derived authKeyHash OR encryptionKey-derived eAuthHash */
function verifyBoardAuth(
  board: { auth_key_hash: string; encryption_key_auth_hash?: string | null },
  providedAuthHash: string
): boolean {
  if (board.auth_key_hash === providedAuthHash) return true;
  if (board.encryption_key_auth_hash && board.encryption_key_auth_hash === providedAuthHash) return true;
  return false;
}

async function hashString(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(input));
  return encodeBase64(new Uint8Array(hashBuffer));
}

/** Storage 이미지 파일 삭제 (DB 행은 CASCADE로 처리) */
async function deleteMediaImages(
  supabase: ReturnType<typeof createServerSupabase>,
  filter: { postId: string } | { commentId: string } | { boardId: string }
) {
  const query = supabase.from('board_post_images').select('storage_path');
  let filtered;
  if ('postId' in filter) {
    filtered = query.eq('post_id', filter.postId);
  } else if ('commentId' in filter) {
    filtered = query.eq('comment_id', filter.commentId);
  } else {
    filtered = query.eq('board_id', filter.boardId);
  }

  const { data: images } = await filtered;
  if (images && images.length > 0) {
    const paths = images.map((img) => img.storage_path);
    await supabase.storage.from('board-images').remove(paths);
  }
}

// ─── 게시판 생성 ───

export async function createBoard(
  encryptedName: string,
  encryptedNameNonce: string
): Promise<
  { boardId: string; password: string; adminToken: string; inviteCode: string } | { error: string }
> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:create:${ip}`, CREATE_BOARD_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();
  const boardId = generateRoomId();
  const password = generateRoomPassword();
  const adminToken = crypto.randomUUID();

  const { authKey, encryptionSeed } = await deriveKeysFromPassword(password, boardId);
  const authKeyHash = await hashAuthKey(authKey);
  const adminTokenHash = await hashString(adminToken);

  // 초대 코드 생성 + encryptionSeed wrapping
  const inviteCode = generateInviteCode();
  const inviteCodeHash = await hashInviteCode(inviteCode);
  const wrappingKey = await deriveWrappingKey(inviteCode, boardId);
  const wrapped = wrapEncryptionKey(encryptionSeed, wrappingKey);
  const encKeyAuthHash = await hashEncryptionKeyForAuth(encryptionSeed);

  const { error } = await supabase.from('boards').insert({
    id: boardId,
    auth_key_hash: authKeyHash,
    admin_token_hash: adminTokenHash,
    encrypted_name: encryptedName,
    encrypted_name_nonce: encryptedNameNonce,
    status: 'active',
    invite_code_hash: inviteCodeHash,
    wrapped_encryption_key: wrapped.ciphertext,
    wrapped_key_nonce: wrapped.nonce,
    invite_version: 1,
    encryption_key_auth_hash: encKeyAuthHash,
  });

  if (error) {
    console.error('[createBoard] Supabase insert error:', error.message, error.code, error.details);
    return { error: 'CREATION_FAILED' };
  }

  return { boardId, password, adminToken, inviteCode };
}

// ─── 게시판 이름 업데이트 (생성 직후 암호화된 이름 설정) ───

export async function updateBoardName(
  boardId: string,
  authKeyHash: string,
  encryptedName: string,
  encryptedNameNonce: string,
  encryptedSubtitle?: string,
  encryptedSubtitleNonce?: string
): Promise<{ success: boolean; error?: string }> {
  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { success: false, error: 'UNAUTHORIZED' };

  const updateData: Record<string, unknown> = {
    encrypted_name: encryptedName,
    encrypted_name_nonce: encryptedNameNonce,
  };

  if (encryptedSubtitle && encryptedSubtitleNonce) {
    updateData.encrypted_subtitle = encryptedSubtitle;
    updateData.encrypted_subtitle_nonce = encryptedSubtitleNonce;
  } else {
    updateData.encrypted_subtitle = null;
    updateData.encrypted_subtitle_nonce = null;
  }

  const { error } = await supabase
    .from('boards')
    .update(updateData)
    .eq('id', boardId);

  if (error) {
    console.error('[updateBoardName] Supabase update error:', error.message, error.code, error.details);
    return { success: false, error: 'UPDATE_FAILED' };
  }
  return { success: true };
}

// ─── 부제목 업데이트 (관리자 전용) ───

export async function updateBoardSubtitle(
  boardId: string,
  adminToken: string,
  encryptedSubtitle?: string,
  encryptedSubtitleNonce?: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('admin_token_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };

  const tokenHash = await hashString(adminToken);
  if (tokenHash !== board.admin_token_hash) {
    return { success: false, error: 'INVALID_ADMIN_TOKEN' };
  }

  const updateData: Record<string, unknown> = {
    encrypted_subtitle: encryptedSubtitle ?? null,
    encrypted_subtitle_nonce: encryptedSubtitleNonce ?? null,
  };

  const { error } = await supabase
    .from('boards')
    .update(updateData)
    .eq('id', boardId);

  if (error) return { success: false, error: 'UPDATE_FAILED' };
  return { success: true };
}

// ─── 비밀번호 검증 (게시판 참여) ───

export async function joinBoard(
  boardId: string,
  password: string
): Promise<{ valid: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(
    `board:join:${ip}:${boardId}`,
    JOIN_BOARD_LIMIT
  );
  if (!rateCheck.allowed) return { valid: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();
  const { data: board, error } = await supabase
    .from('boards')
    .select('auth_key_hash, status')
    .eq('id', boardId)
    .single();

  if (error || !board) return { valid: false, error: 'BOARD_NOT_FOUND' };
  if (board.status !== 'active') return { valid: false, error: 'BOARD_INACTIVE' };

  const { authKey } = await deriveKeysFromPassword(password, boardId);
  const authKeyHash = await hashAuthKey(authKey);

  if (authKeyHash !== board.auth_key_hash) {
    return { valid: false, error: 'INVALID_PASSWORD' };
  }

  return { valid: true };
}

// ─── 게시판 메타데이터 조회 ───

export async function getBoardMeta(
  boardId: string,
  authKeyHash: string
): Promise<
  | {
      encryptedName: string;
      encryptedNameNonce: string;
      encryptedSubtitle: string | null;
      encryptedSubtitleNonce: string | null;
      status: string;
      reportThreshold: number;
    }
  | { error: string }
> {
  const supabase = createServerSupabase();
  const { data: board, error } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, encrypted_name, encrypted_name_nonce, encrypted_subtitle, encrypted_subtitle_nonce, status, report_threshold')
    .eq('id', boardId)
    .single();

  if (error || !board) return { error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { error: 'UNAUTHORIZED' };

  return {
    encryptedName: board.encrypted_name,
    encryptedNameNonce: board.encrypted_name_nonce,
    encryptedSubtitle: board.encrypted_subtitle ?? null,
    encryptedSubtitleNonce: board.encrypted_subtitle_nonce ?? null,
    status: board.status,
    reportThreshold: board.report_threshold,
  };
}

// ─── 게시글 작성 ───

export async function createPost(
  boardId: string,
  authKeyHash: string,
  authorNameEncrypted: string,
  authorNameNonce: string,
  contentEncrypted: string,
  contentNonce: string,
  titleEncrypted?: string,
  titleNonce?: string
): Promise<{ postId: string } | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:post:${ip}`, CREATE_POST_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, status')
    .eq('id', boardId)
    .single();

  if (!board || board.status !== 'active') return { error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { error: 'UNAUTHORIZED' };

  const insertData: Record<string, unknown> = {
    board_id: boardId,
    author_name_encrypted: authorNameEncrypted,
    author_name_nonce: authorNameNonce,
    content_encrypted: contentEncrypted,
    content_nonce: contentNonce,
  };
  if (titleEncrypted && titleNonce) {
    insertData.title_encrypted = titleEncrypted;
    insertData.title_nonce = titleNonce;
  }

  const { data, error } = await supabase
    .from('board_posts')
    .insert(insertData)
    .select('id')
    .single();

  if (error || !data) return { error: 'POST_FAILED' };
  return { postId: data.id };
}

// ─── 게시글 수정 ───

export async function updatePost(
  boardId: string,
  postId: string,
  authKeyHash: string,
  authorNameEncrypted: string,
  authorNameNonce: string,
  contentEncrypted: string,
  contentNonce: string,
  titleEncrypted?: string,
  titleNonce?: string
): Promise<{ success: boolean } | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:post:${ip}`, CREATE_POST_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, status')
    .eq('id', boardId)
    .single();

  if (!board || board.status !== 'active') return { error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { error: 'UNAUTHORIZED' };

  // 게시글 존재 + 블라인드 여부 확인
  const { data: post } = await supabase
    .from('board_posts')
    .select('id, is_blinded')
    .eq('id', postId)
    .eq('board_id', boardId)
    .single();

  if (!post) return { error: 'POST_NOT_FOUND' };
  if (post.is_blinded) return { error: 'POST_BLINDED' };

  const updateData: Record<string, unknown> = {
    author_name_encrypted: authorNameEncrypted,
    author_name_nonce: authorNameNonce,
    content_encrypted: contentEncrypted,
    content_nonce: contentNonce,
    title_encrypted: titleEncrypted ?? null,
    title_nonce: titleNonce ?? null,
  };

  const { error } = await supabase
    .from('board_posts')
    .update(updateData)
    .eq('id', postId);

  if (error) return { error: 'UPDATE_FAILED' };
  return { success: true };
}

// ─── 게시글 목록 조회 ───

export async function getPosts(
  boardId: string,
  authKeyHash: string,
  cursor?: string,
  limit: number = 20
): Promise<
  | {
      posts: Array<{
        id: string;
        authorNameEncrypted: string;
        authorNameNonce: string;
        titleEncrypted: string | null;
        titleNonce: string | null;
        contentEncrypted: string;
        contentNonce: string;
        createdAt: string;
        isBlinded: boolean;
        commentCount: number;
        images: Array<{
          id: string;
          storagePath: string;
          encryptedNonce: string;
          mimeType: string;
          sizeBytes: number;
          width: number | null;
          height: number | null;
          displayOrder: number;
        }>;
      }>;
      hasMore: boolean;
    }
  | { error: string }
> {
  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { error: 'UNAUTHORIZED' };

  let query = supabase
    .from('board_posts')
    .select(
      'id, author_name_encrypted, author_name_nonce, title_encrypted, title_nonce, content_encrypted, content_nonce, created_at, is_blinded, comment_count, board_post_images(id, storage_path, encrypted_nonce, mime_type, size_bytes, width, height, display_order)'
    )
    .eq('board_id', boardId)
    .order('created_at', { ascending: false })
    .limit(limit + 1);

  if (cursor) {
    const { data: cursorPost } = await supabase
      .from('board_posts')
      .select('created_at')
      .eq('id', cursor)
      .single();

    if (cursorPost) {
      query = query.lt('created_at', cursorPost.created_at);
    }
  }

  const { data: posts, error } = await query;
  if (error) return { error: 'FETCH_FAILED' };

  const hasMore = (posts?.length ?? 0) > limit;
  const sliced = (posts ?? []).slice(0, limit);

  return {
    posts: sliced.map((p) => ({
      id: p.id,
      authorNameEncrypted: p.author_name_encrypted,
      authorNameNonce: p.author_name_nonce,
      titleEncrypted: p.title_encrypted ?? null,
      titleNonce: p.title_nonce ?? null,
      contentEncrypted: p.content_encrypted,
      contentNonce: p.content_nonce,
      createdAt: p.created_at,
      isBlinded: p.is_blinded,
      commentCount: (p as Record<string, unknown>).comment_count as number ?? 0,
      images: ((p as Record<string, unknown>).board_post_images as Array<Record<string, unknown>> ?? [])
        .sort((a, b) => (a.display_order as number) - (b.display_order as number))
        .map((img) => ({
          id: img.id as string,
          storagePath: img.storage_path as string,
          encryptedNonce: img.encrypted_nonce as string,
          mimeType: img.mime_type as string,
          sizeBytes: img.size_bytes as number,
          width: img.width as number | null,
          height: img.height as number | null,
          displayOrder: img.display_order as number,
        })),
    })),
    hasMore,
  };
}

// ─── 게시글 신고 ───

export async function reportPost(
  boardId: string,
  postId: string,
  authKeyHash: string,
  reason: 'spam' | 'abuse' | 'illegal' | 'other'
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const ua = headersList.get('user-agent') ?? '';
  const rateCheck = await checkRateLimit(`board:report:${ip}`, REPORT_POST_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, report_threshold')
    .eq('id', boardId)
    .single();

  if (!board || !verifyBoardAuth(board, authKeyHash)) {
    return { success: false, error: 'UNAUTHORIZED' };
  }

  // 신고자 fingerprint (익명, 중복 방지)
  const fingerprint = await hashString(`${ip}:${ua}`);

  const { error } = await supabase.from('board_reports').insert({
    post_id: postId,
    reporter_fingerprint: fingerprint,
    reason,
  });

  if (error) {
    if (error.code === '23505') {
      return { success: false, error: 'ALREADY_REPORTED' };
    }
    return { success: false, error: 'REPORT_FAILED' };
  }

  // 신고 카운트 증가 + 자동 블라인드
  const threshold = board.report_threshold ?? BLIND_THRESHOLD;
  await supabase.rpc('increment_report_count', {
    p_post_id: postId,
    p_threshold: threshold,
  });

  return { success: true };
}

// ─── 본인 게시글 삭제 ───

export async function deleteOwnPost(
  boardId: string,
  postId: string,
  authKeyHash: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:post:${ip}`, CREATE_POST_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 게시판 인증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, status')
    .eq('id', boardId)
    .single();

  if (!board || board.status !== 'active') return { success: false, error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { success: false, error: 'UNAUTHORIZED' };

  // 게시글이 해당 게시판에 속하는지 확인
  const { data: post } = await supabase
    .from('board_posts')
    .select('id')
    .eq('id', postId)
    .eq('board_id', boardId)
    .single();

  if (!post) return { success: false, error: 'POST_NOT_FOUND' };

  await deleteMediaImages(supabase, { postId });
  await supabase.from('board_posts').delete().eq('id', postId);
  return { success: true };
}

// ─── 관리자: 게시글 삭제 ───

export async function adminDeletePost(
  boardId: string,
  postId: string,
  adminToken: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('admin_token_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };

  const tokenHash = await hashString(adminToken);
  if (tokenHash !== board.admin_token_hash) {
    return { success: false, error: 'INVALID_ADMIN_TOKEN' };
  }

  await deleteMediaImages(supabase, { postId });
  await supabase.from('board_posts').delete().eq('id', postId);
  return { success: true };
}

// ─── 관리자: 블라인드 해제 ───

export async function adminUnblindPost(
  boardId: string,
  postId: string,
  adminToken: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('admin_token_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };

  const tokenHash = await hashString(adminToken);
  if (tokenHash !== board.admin_token_hash) {
    return { success: false, error: 'INVALID_ADMIN_TOKEN' };
  }

  await supabase
    .from('board_posts')
    .update({ is_blinded: false, report_count: 0 })
    .eq('id', postId);

  return { success: true };
}

// ─── 관리자: 게시판 파쇄 ───

export async function destroyBoard(
  boardId: string,
  adminToken: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('admin_token_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };

  const tokenHash = await hashString(adminToken);
  if (tokenHash !== board.admin_token_hash) {
    return { success: false, error: 'INVALID_ADMIN_TOKEN' };
  }

  // Storage 이미지 파일 삭제 (CASCADE 전에 경로 수집)
  await deleteMediaImages(supabase, { boardId });

  // CASCADE로 board_posts, board_reports, board_post_images, board_comments 자동 삭제
  await supabase.from('boards').delete().eq('id', boardId);
  return { success: true };
}

// ═══════════════════════════════════════════════════
// 댓글 (Comments)
// ═══════════════════════════════════════════════════

// ─── 댓글 목록 조회 ───

export async function getComments(
  boardId: string,
  postId: string,
  authKeyHash: string,
  cursor?: string,
  limit: number = 50
): Promise<
  | {
      comments: Array<{
        id: string;
        postId: string;
        authorNameEncrypted: string;
        authorNameNonce: string;
        contentEncrypted: string;
        contentNonce: string;
        createdAt: string;
        isBlinded: boolean;
        images: Array<{
          id: string;
          storagePath: string;
          encryptedNonce: string;
          mimeType: string;
          sizeBytes: number;
          width: number | null;
          height: number | null;
          displayOrder: number;
        }>;
      }>;
      hasMore: boolean;
    }
  | { error: string }
> {
  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { error: 'UNAUTHORIZED' };

  let query = supabase
    .from('board_comments')
    .select(
      'id, post_id, author_name_encrypted, author_name_nonce, content_encrypted, content_nonce, created_at, is_blinded, board_post_images(id, storage_path, encrypted_nonce, mime_type, size_bytes, width, height, display_order)'
    )
    .eq('post_id', postId)
    .eq('board_id', boardId)
    .order('created_at', { ascending: true })
    .limit(limit + 1);

  if (cursor) {
    const { data: cursorComment } = await supabase
      .from('board_comments')
      .select('created_at')
      .eq('id', cursor)
      .single();

    if (cursorComment) {
      query = query.gt('created_at', cursorComment.created_at);
    }
  }

  const { data: comments, error } = await query;
  if (error) return { error: 'FETCH_FAILED' };

  const hasMore = (comments?.length ?? 0) > limit;
  const sliced = (comments ?? []).slice(0, limit);

  return {
    comments: sliced.map((c) => ({
      id: c.id,
      postId: c.post_id,
      authorNameEncrypted: c.author_name_encrypted,
      authorNameNonce: c.author_name_nonce,
      contentEncrypted: c.content_encrypted,
      contentNonce: c.content_nonce,
      createdAt: c.created_at,
      isBlinded: c.is_blinded,
      images: ((c as Record<string, unknown>).board_post_images as Array<Record<string, unknown>> ?? [])
        .sort((a, b) => (a.display_order as number) - (b.display_order as number))
        .map((img) => ({
          id: img.id as string,
          storagePath: img.storage_path as string,
          encryptedNonce: img.encrypted_nonce as string,
          mimeType: img.mime_type as string,
          sizeBytes: img.size_bytes as number,
          width: img.width as number | null,
          height: img.height as number | null,
          displayOrder: img.display_order as number,
        })),
    })),
    hasMore,
  };
}

// ─── 댓글 작성 ───

export async function createComment(
  boardId: string,
  postId: string,
  authKeyHash: string,
  authorNameEncrypted: string,
  authorNameNonce: string,
  contentEncrypted: string,
  contentNonce: string
): Promise<{ commentId: string } | { error: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:comment:${ip}`, CREATE_COMMENT_LIMIT);
  if (!rateCheck.allowed) return { error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, status')
    .eq('id', boardId)
    .single();

  if (!board || board.status !== 'active') return { error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { error: 'UNAUTHORIZED' };

  // 게시글 존재 + 블라인드 확인
  const { data: post } = await supabase
    .from('board_posts')
    .select('id, is_blinded')
    .eq('id', postId)
    .eq('board_id', boardId)
    .single();

  if (!post) return { error: 'POST_NOT_FOUND' };
  if (post.is_blinded) return { error: 'POST_BLINDED' };

  const { data, error } = await supabase
    .from('board_comments')
    .insert({
      post_id: postId,
      board_id: boardId,
      author_name_encrypted: authorNameEncrypted,
      author_name_nonce: authorNameNonce,
      content_encrypted: contentEncrypted,
      content_nonce: contentNonce,
    })
    .select('id')
    .single();

  if (error || !data) return { error: 'COMMENT_FAILED' };
  return { commentId: data.id };
}

// ─── 본인 댓글 삭제 ───

export async function deleteOwnComment(
  boardId: string,
  commentId: string,
  authKeyHash: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:comment:delete:${ip}`, DELETE_COMMENT_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 게시판 인증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, status')
    .eq('id', boardId)
    .single();

  if (!board || board.status !== 'active') return { success: false, error: 'BOARD_NOT_FOUND' };
  if (!verifyBoardAuth(board, authKeyHash)) return { success: false, error: 'UNAUTHORIZED' };

  // 댓글이 해당 게시판에 속하는지 확인
  const { data: comment } = await supabase
    .from('board_comments')
    .select('id')
    .eq('id', commentId)
    .eq('board_id', boardId)
    .single();

  if (!comment) return { success: false, error: 'COMMENT_NOT_FOUND' };

  await deleteMediaImages(supabase, { commentId });
  await supabase.from('board_comments').delete().eq('id', commentId);
  return { success: true };
}

// ─── 댓글 신고 ───

export async function reportComment(
  boardId: string,
  commentId: string,
  authKeyHash: string,
  reason: 'spam' | 'abuse' | 'illegal' | 'other'
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const ua = headersList.get('user-agent') ?? '';
  const rateCheck = await checkRateLimit(`board:comment:report:${ip}`, REPORT_POST_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  // 인증 검증
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash, report_threshold')
    .eq('id', boardId)
    .single();

  if (!board || !verifyBoardAuth(board, authKeyHash)) {
    return { success: false, error: 'UNAUTHORIZED' };
  }

  // 신고자 fingerprint
  const fingerprint = await hashString(`${ip}:${ua}`);

  const { error } = await supabase.from('board_comment_reports').insert({
    comment_id: commentId,
    reporter_fingerprint: fingerprint,
    reason,
  });

  if (error) {
    if (error.code === '23505') {
      return { success: false, error: 'ALREADY_REPORTED' };
    }
    return { success: false, error: 'REPORT_FAILED' };
  }

  // 신고 카운트 증가 + 자동 블라인드
  const threshold = board.report_threshold ?? BLIND_THRESHOLD;
  await supabase.rpc('increment_comment_report_count', {
    p_comment_id: commentId,
    p_threshold: threshold,
  });

  return { success: true };
}

// ─── 관리자: 댓글 삭제 ───

export async function adminDeleteComment(
  boardId: string,
  commentId: string,
  adminToken: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('admin_token_hash')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };

  const tokenHash = await hashString(adminToken);
  if (tokenHash !== board.admin_token_hash) {
    return { success: false, error: 'INVALID_ADMIN_TOKEN' };
  }

  await deleteMediaImages(supabase, { commentId });
  await supabase.from('board_comments').delete().eq('id', commentId);
  return { success: true };
}

// ═══════════════════════════════════════════════════
// 초대 코드 (Invite Code)
// ═══════════════════════════════════════════════════

// ─── 초대 코드로 게시판 참여 (wrapped key 반환) ───

export async function joinBoardViaInviteCode(
  boardId: string,
  inviteCodeHash: string
): Promise<
  | {
      valid: true;
      wrappedEncryptionKey: string;
      wrappedKeyNonce: string;
      inviteVersion: number;
    }
  | { valid: false; error: string }
> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(
    `board:invite:${ip}:${boardId}`,
    JOIN_BOARD_LIMIT
  );
  if (!rateCheck.allowed) return { valid: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();
  const { data: board, error } = await supabase
    .from('boards')
    .select('invite_code_hash, wrapped_encryption_key, wrapped_key_nonce, invite_version, status')
    .eq('id', boardId)
    .single();

  if (error || !board) return { valid: false, error: 'BOARD_NOT_FOUND' };
  if (board.status !== 'active') return { valid: false, error: 'BOARD_INACTIVE' };
  if (!board.invite_code_hash) return { valid: false, error: 'INVITE_NOT_ENABLED' };

  if (board.invite_code_hash !== inviteCodeHash) {
    return { valid: false, error: 'INVALID_INVITE_CODE' };
  }

  return {
    valid: true,
    wrappedEncryptionKey: board.wrapped_encryption_key!,
    wrappedKeyNonce: board.wrapped_key_nonce!,
    inviteVersion: board.invite_version ?? 1,
  };
}

// ─── 관리자: 초대 코드 로테이션 ───

export async function rotateInviteCode(
  boardId: string,
  adminToken: string,
  newInviteCodeHash: string,
  newWrappedEncryptionKey: string,
  newWrappedKeyNonce: string
): Promise<{ success: boolean; error?: string }> {
  const headersList = await headers();
  const ip = getClientIp(headersList);
  const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
  if (!rateCheck.allowed) return { success: false, error: 'TOO_MANY_REQUESTS' };

  const supabase = createServerSupabase();

  const { data: board } = await supabase
    .from('boards')
    .select('admin_token_hash, invite_version')
    .eq('id', boardId)
    .single();

  if (!board) return { success: false, error: 'BOARD_NOT_FOUND' };

  const tokenHash = await hashString(adminToken);
  if (tokenHash !== board.admin_token_hash) {
    return { success: false, error: 'INVALID_ADMIN_TOKEN' };
  }

  const { error } = await supabase
    .from('boards')
    .update({
      invite_code_hash: newInviteCodeHash,
      wrapped_encryption_key: newWrappedEncryptionKey,
      wrapped_key_nonce: newWrappedKeyNonce,
      invite_version: (board.invite_version ?? 0) + 1,
    })
    .eq('id', boardId);

  if (error) return { success: false, error: 'UPDATE_FAILED' };
  return { success: true };
}

// ─── 레거시 마이그레이션: encryption_key_auth_hash 설정 ───

export async function updateEncryptionKeyAuthHash(
  boardId: string,
  authKeyHash: string,
  encryptionKeyAuthHash: string
): Promise<void> {
  const supabase = createServerSupabase();
  const { data: board } = await supabase
    .from('boards')
    .select('auth_key_hash, encryption_key_auth_hash')
    .eq('id', boardId)
    .single();

  if (!board || board.auth_key_hash !== authKeyHash) return;
  if (board.encryption_key_auth_hash) return; // 이미 설정됨

  await supabase
    .from('boards')
    .update({ encryption_key_auth_hash: encryptionKeyAuthHash })
    .eq('id', boardId);
}
