import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { encodeBase64 } from 'tweetnacl-util';

const ADMIN_LIMIT = { windowMs: 3600_000, maxRequests: 20 };

async function hashString(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(input));
  return encodeBase64(new Uint8Array(hashBuffer));
}

export async function POST(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ success: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const { boardId, adminToken, encryptedSubtitle, encryptedSubtitleNonce } =
      await request.json();

    if (!boardId || !adminToken) {
      return Response.json({ success: false, error: 'MISSING_PARAMS' }, { status: 400 });
    }

    const supabase = createServerSupabase();

    const { data: board } = await supabase
      .from('boards')
      .select('admin_token_hash')
      .eq('id', boardId)
      .single();

    if (!board) {
      return Response.json({ success: false, error: 'BOARD_NOT_FOUND' }, { status: 404 });
    }

    const tokenHash = await hashString(adminToken);
    if (tokenHash !== board.admin_token_hash) {
      return Response.json({ success: false, error: 'INVALID_ADMIN_TOKEN' }, { status: 403 });
    }

    const { error } = await supabase
      .from('boards')
      .update({
        encrypted_subtitle: encryptedSubtitle ?? null,
        encrypted_subtitle_nonce: encryptedSubtitleNonce ?? null,
      })
      .eq('id', boardId);

    if (error) {
      return Response.json({ success: false, error: 'UPDATE_FAILED' }, { status: 500 });
    }

    return Response.json({ success: true });
  } catch {
    return Response.json({ success: false, error: 'Internal error' }, { status: 500 });
  }
}
