import { NextResponse } from 'next/server';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 10회
const UPLOAD_LIMIT = { windowMs: 60_000, maxRequests: 10 };

// 암호화 후 최대 크기
const MAX_IMAGE_ENCRYPTED_SIZE = 6 * 1024 * 1024;   // 이미지: 6MB
const MAX_VIDEO_ENCRYPTED_SIZE = 50 * 1024 * 1024;   // 동영상: 50MB

/**
 * POST /api/board/upload-image
 *
 * FormData:
 *   - file: 암호화된 바이너리 (Blob)
 *   - boardId: string
 *   - postId: string
 *   - authKeyHash: string
 *   - nonce: string (암호화 nonce, Base64)
 *   - mimeType: string (원본 MIME)
 *   - width: string (optional)
 *   - height: string (optional)
 *   - displayOrder: string
 */
export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:upload:${ip}`, UPLOAD_LIMIT);
    if (!rateCheck.allowed) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
    }

    const formData = await request.formData();
    const file = formData.get('file') as Blob | null;
    const boardId = formData.get('boardId') as string | null;
    const postId = formData.get('postId') as string | null;
    const commentId = formData.get('commentId') as string | null;
    const authKeyHash = formData.get('authKeyHash') as string | null;
    const nonce = formData.get('nonce') as string | null;
    const mimeType = formData.get('mimeType') as string | null;
    const widthStr = formData.get('width') as string | null;
    const heightStr = formData.get('height') as string | null;
    const displayOrderStr = formData.get('displayOrder') as string | null;

    // postId 또는 commentId 중 하나 필수
    if (!file || !boardId || (!postId && !commentId) || !authKeyHash || !nonce || !mimeType) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    const isVideo = mimeType?.startsWith('video/');
    const maxSize = isVideo ? MAX_VIDEO_ENCRYPTED_SIZE : MAX_IMAGE_ENCRYPTED_SIZE;
    if (file.size > maxSize) {
      return NextResponse.json(
        { error: isVideo ? 'Video too large (max 50MB)' : 'Image too large (max 6MB)' },
        { status: 413 }
      );
    }

    const supabase = createServerSupabase();

    // 게시판 인증 검증
    const { data: board } = await supabase
      .from('boards')
      .select('auth_key_hash, status')
      .eq('id', boardId)
      .single();

    if (!board || board.status !== 'active') {
      return NextResponse.json({ error: 'Board not found' }, { status: 404 });
    }
    if (board.auth_key_hash !== authKeyHash) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // 게시글 또는 댓글 존재 확인
    if (postId) {
      const { data: post } = await supabase
        .from('board_posts')
        .select('id')
        .eq('id', postId)
        .eq('board_id', boardId)
        .single();

      if (!post) {
        return NextResponse.json({ error: 'Post not found' }, { status: 404 });
      }
    } else if (commentId) {
      const { data: comment } = await supabase
        .from('board_comments')
        .select('id')
        .eq('id', commentId)
        .eq('board_id', boardId)
        .single();

      if (!comment) {
        return NextResponse.json({ error: 'Comment not found' }, { status: 404 });
      }

      // 댓글당 이미지 최대 2장
      const { count } = await supabase
        .from('board_post_images')
        .select('id', { count: 'exact', head: true })
        .eq('comment_id', commentId);

      if ((count ?? 0) >= 2) {
        return NextResponse.json({ error: 'Max 2 images per comment' }, { status: 400 });
      }
    }

    // Storage 업로드 (암호화된 바이너리)
    const ownerId = postId ?? commentId;
    const storagePath = `${boardId}/${ownerId}/${crypto.randomUUID()}`;
    const buffer = await file.arrayBuffer();

    const { error: uploadError } = await supabase.storage
      .from('board-images')
      .upload(storagePath, buffer, {
        contentType: 'application/octet-stream',
        upsert: false,
      });

    if (uploadError) {
      console.error('[Board Upload] Storage error:', uploadError.message);
      return NextResponse.json({ error: 'Upload failed' }, { status: 500 });
    }

    // DB 기록
    const insertData: Record<string, unknown> = {
      board_id: boardId,
      storage_path: storagePath,
      encrypted_nonce: nonce,
      mime_type: mimeType,
      size_bytes: file.size,
      width: widthStr ? parseInt(widthStr, 10) : null,
      height: heightStr ? parseInt(heightStr, 10) : null,
      display_order: displayOrderStr ? parseInt(displayOrderStr, 10) : 0,
    };
    if (postId) insertData.post_id = postId;
    if (commentId) insertData.comment_id = commentId;

    const { data: imageRecord, error: dbError } = await supabase
      .from('board_post_images')
      .insert(insertData)
      .select('id')
      .single();

    if (dbError || !imageRecord) {
      console.error('[Board Upload] DB error:', dbError?.message);
      // DB 실패 시 Storage 정리
      await supabase.storage.from('board-images').remove([storagePath]);
      return NextResponse.json({ error: 'Record failed' }, { status: 500 });
    }

    return NextResponse.json({ imageId: imageRecord.id });
  } catch (err) {
    console.error('[Board Upload] Unexpected error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
