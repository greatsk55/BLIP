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

/**
 * Apple client_secret JWT 생성 (ES256)
 *
 * Apple Developer 문서:
 * https://developer.apple.com/documentation/sign_in_with_apple/generate_and_validate_tokens
 */
async function generateAppleClientSecret(
  teamId: string,
  clientId: string,
  keyId: string,
  privateKeyPem: string
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  // JWT Header
  const header = {
    alg: 'ES256',
    kid: keyId,
  };

  // JWT Payload
  const payload = {
    iss: teamId,
    iat: now,
    exp: now + 15777000, // 6개월 (Apple 최대 허용)
    aud: 'https://appleid.apple.com',
    sub: clientId,
  };

  // Base64url encode
  const encode = (obj: object) =>
    Buffer.from(JSON.stringify(obj))
      .toString('base64url');

  const headerB64 = encode(header);
  const payloadB64 = encode(payload);
  const signingInput = `${headerB64}.${payloadB64}`;

  // Import P8 private key and sign
  const pemContents = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\s/g, '');

  const keyBuffer = Buffer.from(pemContents, 'base64');

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBuffer,
    { name: 'ECDSA', namedCurve: 'P-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' },
    cryptoKey,
    new TextEncoder().encode(signingInput)
  );

  // DER → raw r||s (64 bytes) 변환
  const signatureB64 = derToRaw(new Uint8Array(signature));

  return `${signingInput}.${signatureB64}`;
}

/**
 * ECDSA DER 시그니처를 raw (r||s) 형식으로 변환
 * Web Crypto API는 DER 형식을 반환하지만 JWT는 raw 형식 필요
 */
function derToRaw(der: Uint8Array): string {
  // DER: 0x30 [total-len] 0x02 [r-len] [r] 0x02 [s-len] [s]
  const rLen = der[3];
  const rStart = 4;
  const sLen = der[5 + rLen];
  const sStart = 6 + rLen;

  // r과 s를 32바이트로 패딩/트림
  const r = padTo32(der.slice(rStart, rStart + rLen));
  const s = padTo32(der.slice(sStart, sStart + sLen));

  const raw = new Uint8Array(64);
  raw.set(r, 0);
  raw.set(s, 32);

  return Buffer.from(raw).toString('base64url');
}

function padTo32(buf: Uint8Array): Uint8Array {
  if (buf.length === 32) return buf;
  if (buf.length > 32) return buf.slice(buf.length - 32);
  const padded = new Uint8Array(32);
  padded.set(buf, 32 - buf.length);
  return padded;
}
