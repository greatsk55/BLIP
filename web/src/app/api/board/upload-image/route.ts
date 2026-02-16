import { NextResponse } from 'next/server';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 10회
const UPLOAD_LIMIT = { windowMs: 60_000, maxRequests: 10 };

// 암호화 후 최대 크기 (5MB + 암호화 오버헤드)
const MAX_ENCRYPTED_SIZE = 6 * 1024 * 1024;

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
    const authKeyHash = formData.get('authKeyHash') as string | null;
    const nonce = formData.get('nonce') as string | null;
    const mimeType = formData.get('mimeType') as string | null;
    const widthStr = formData.get('width') as string | null;
    const heightStr = formData.get('height') as string | null;
    const displayOrderStr = formData.get('displayOrder') as string | null;

    if (!file || !boardId || !postId || !authKeyHash || !nonce || !mimeType) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400 });
    }

    if (file.size > MAX_ENCRYPTED_SIZE) {
      return NextResponse.json({ error: 'File too large' }, { status: 413 });
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

    // 게시글 존재 확인
    const { data: post } = await supabase
      .from('board_posts')
      .select('id')
      .eq('id', postId)
      .eq('board_id', boardId)
      .single();

    if (!post) {
      return NextResponse.json({ error: 'Post not found' }, { status: 404 });
    }

    // Storage 업로드 (암호화된 바이너리)
    const storagePath = `${boardId}/${postId}/${crypto.randomUUID()}`;
    const buffer = await file.arrayBuffer();

    const { error: uploadError } = await supabase.storage
      .from('board-images')
      .upload(storagePath, buffer, {
        contentType: 'application/octet-stream',
        upsert: false,
      });

    if (uploadError) {
      console.error('[Board Upload] Storage error:', uploadError.message);
      return NextResponse.json({ error: 'Upload failed', detail: uploadError.message }, { status: 500 });
    }

    // DB 기록
    const { data: imageRecord, error: dbError } = await supabase
      .from('board_post_images')
      .insert({
        post_id: postId,
        board_id: boardId,
        storage_path: storagePath,
        encrypted_nonce: nonce,
        mime_type: mimeType,
        size_bytes: file.size,
        width: widthStr ? parseInt(widthStr, 10) : null,
        height: heightStr ? parseInt(heightStr, 10) : null,
        display_order: displayOrderStr ? parseInt(displayOrderStr, 10) : 0,
      })
      .select('id')
      .single();

    if (dbError || !imageRecord) {
      console.error('[Board Upload] DB error:', dbError?.message);
      // DB 실패 시 Storage 정리
      await supabase.storage.from('board-images').remove([storagePath]);
      return NextResponse.json({ error: 'Record failed', detail: dbError?.message }, { status: 500 });
    }

    return NextResponse.json({ imageId: imageRecord.id });
  } catch (err) {
    console.error('[Board Upload] Unexpected error:', err);
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
