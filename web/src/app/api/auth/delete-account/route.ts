import { generateAppleClientSecret } from '@/lib/apple/client-secret';
import { createServerSupabase } from '@/lib/supabase/server';
import { parseJsonBody, isString } from '@/lib/api-utils';

/**
 * 계정 삭제 API — Apple ID 토큰 철회 + Supabase 유저 삭제
 *
 * Apple App Store 심사 가이드라인 5.1.1(v):
 * Apple Sign In으로 가입한 유저에게 계정 삭제 기능 필수 제공
 *
 * Flow:
 * 1. Supabase access token으로 유저 확인
 * 2. Apple authorization code → refresh token 교환
 * 3. Apple refresh token 철회 (appleid.apple.com/auth/revoke)
 * 4. Supabase Admin API로 유저 삭제
 */
export async function POST(request: Request) {
  try {
    const body = await parseJsonBody(request);
    if (
      !body ||
      !isString(body.accessToken) ||
      !isString(body.authorizationCode)
    ) {
      return Response.json({ error: 'INVALID_BODY' }, { status: 400 });
    }

    const accessToken = body.accessToken as string;
    const authorizationCode = body.authorizationCode as string;

    const supabase = createServerSupabase();

    // ── 1. Supabase access token으로 유저 확인 ──
    const {
      data: { user },
      error: userError,
    } = await supabase.auth.getUser(accessToken);

    if (userError || !user) {
      return Response.json({ error: 'UNAUTHORIZED' }, { status: 401 });
    }

    // ── 2. Apple 토큰 철회 ──
    const appleRevoked = await revokeAppleToken(authorizationCode);
    if (!appleRevoked) {
      // Apple 철회 실패해도 계정 삭제는 계속 진행
      // (Apple 서버 장애 시에도 유저가 탈퇴할 수 있어야 함)
      console.warn(
        `[BLIP] Apple token revocation failed for user ${user.id}, proceeding with account deletion`
      );
    }

    // ── 3. Supabase에서 유저 삭제 ──
    const { error: deleteError } = await supabase.auth.admin.deleteUser(
      user.id
    );

    if (deleteError) {
      console.error(
        `[BLIP] Supabase user deletion failed: ${deleteError.message}`
      );
      return Response.json({ error: 'DELETE_FAILED' }, { status: 500 });
    }

    return Response.json({ success: true });
  } catch (e) {
    console.error('[BLIP] Account deletion error:', e);
    return Response.json({ error: 'Internal error' }, { status: 500 });
  }
}

/**
 * Apple authorization code → client_secret 생성 → refresh token 교환 → 철회
 *
 * Apple REST API:
 * - Token exchange: POST https://appleid.apple.com/auth/token
 * - Token revoke:   POST https://appleid.apple.com/auth/revoke
 */
async function revokeAppleToken(authorizationCode: string): Promise<boolean> {
  const teamId = process.env.APPLE_TEAM_ID;
  const clientId = process.env.APPLE_CLIENT_ID; // = Service ID (bundle id)
  const keyId = process.env.APPLE_KEY_ID;
  const privateKey = process.env.APPLE_PRIVATE_KEY; // P8 key content

  if (!teamId || !clientId || !keyId || !privateKey) {
    console.warn('[BLIP] Apple credentials not configured, skipping revocation');
    return false;
  }

  try {
    // ── client_secret (JWT) 생성 ──
    const clientSecret = await generateAppleClientSecret(
      teamId,
      clientId,
      keyId,
      privateKey
    );

    // ── authorization code → refresh token 교환 ──
    const tokenResponse = await fetch('https://appleid.apple.com/auth/token', {
      method: 'POST',
      signal: AbortSignal.timeout(10000),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        code: authorizationCode,
        grant_type: 'authorization_code',
      }),
    });

    if (!tokenResponse.ok) {
      console.warn(
        `[BLIP] Apple token exchange failed: ${tokenResponse.status}`
      );
      return false;
    }

    const tokenData = (await tokenResponse.json()) as {
      refresh_token?: string;
    };
    const refreshToken = tokenData.refresh_token;

    if (!refreshToken) {
      console.warn('[BLIP] No refresh token from Apple token exchange');
      return false;
    }

    // ── refresh token 철회 ──
    const revokeResponse = await fetch('https://appleid.apple.com/auth/revoke', {
      method: 'POST',
      signal: AbortSignal.timeout(10000),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        token: refreshToken,
        token_type_hint: 'refresh_token',
      }),
    });

    if (!revokeResponse.ok) {
      console.warn(
        `[BLIP] Apple token revocation failed: ${revokeResponse.status}`
      );
      return false;
    }

    return true;
  } catch (e) {
    console.error('[BLIP] Apple token revocation error:', e);
    return false;
  }
}
