import { NextResponse } from 'next/server';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 분당 60회 (이미지 여러 개 동시 로드)
const DOWNLOAD_LIMIT = { windowMs: 60_000, maxRequests: 60 };

/**
 * GET /api/board/image?imageId=xxx&authKeyHash=xxx
 *
 * 인증 후 Storage에서 암호문 다운로드 → raw 바이너리 반환
 * 클라이언트에서 decryptBinaryRaw() 후 blob URL 생성
 */
export async function GET(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:image:${ip}`, DOWNLOAD_LIMIT);
    if (!rateCheck.allowed) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
    }

    const { searchParams } = new URL(request.url);
    const imageId = searchParams.get('imageId');
    const authKeyHash = searchParams.get('authKeyHash');

    if (!imageId || !authKeyHash) {
      return NextResponse.json({ error: 'Missing params' }, { status: 400 });
    }

    const supabase = createServerSupabase();

    // 이미지 메타데이터 조회
    const { data: image } = await supabase
      .from('board_post_images')
      .select('storage_path, board_id, encrypted_nonce')
      .eq('id', imageId)
      .single();

    if (!image) {
      return NextResponse.json({ error: 'Image not found' }, { status: 404 });
    }

    // 게시판 인증 검증 (이중 인증: password hash OR encryption key hash)
    const { data: board } = await supabase
      .from('boards')
      .select('auth_key_hash, encryption_key_auth_hash')
      .eq('id', image.board_id)
      .single();

    if (
      !board ||
      (board.auth_key_hash !== authKeyHash &&
        (!board.encryption_key_auth_hash || board.encryption_key_auth_hash !== authKeyHash))
    ) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Storage에서 다운로드
    const { data: fileData, error: downloadError } = await supabase.storage
      .from('board-images')
      .download(image.storage_path);

    if (downloadError || !fileData) {
      return NextResponse.json({ error: 'Download failed' }, { status: 500 });
    }

    const buffer = await fileData.arrayBuffer();

    return new NextResponse(buffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/octet-stream',
        'X-Encrypted-Nonce': image.encrypted_nonce,
        'Cache-Control': 'private, max-age=3600',
      },
    });
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
