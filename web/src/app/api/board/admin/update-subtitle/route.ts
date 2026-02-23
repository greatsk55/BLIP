import { createServerSupabase } from '@/lib/supabase/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';
import { encodeBase64 } from 'tweetnacl-util';
import { parseJsonBody, isString, checkOrigin } from '@/lib/api-utils';

const ADMIN_LIMIT = { windowMs: 3600_000, maxRequests: 20 };

async function hashString(input: string): Promise<string> {
  const encoder = new TextEncoder();
  const hashBuffer = await crypto.subtle.digest('SHA-256', encoder.encode(input));
  return encodeBase64(new Uint8Array(hashBuffer));
}

export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) {
      return Response.json({ success: false, error: 'FORBIDDEN' }, { status: 403 });
    }

    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`board:admin:${ip}`, ADMIN_LIMIT);
    if (!rateCheck.allowed) {
      return Response.json({ success: false, error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    }

    const body = await parseJsonBody(request);
    if (!body) {
      return Response.json({ success: false, error: 'INVALID_JSON' }, { status: 400 });
    }

    const { boardId, adminToken, encryptedSubtitle, encryptedSubtitleNonce } = body;

    if (!isString(boardId) || !isString(adminToken)) {
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
      return Response.json({ success: false, error: 'UNAUTHORIZED' }, { status: 403 });
    }

    const { error } = await supabase
      .from('boards')
      .update({
        encrypted_subtitle: typeof encryptedSubtitle === 'string' ? encryptedSubtitle : null,
        encrypted_subtitle_nonce: typeof encryptedSubtitleNonce === 'string' ? encryptedSubtitleNonce : null,
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
