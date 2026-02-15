import { NextResponse } from 'next/server';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

// IP당 1시간에 10회
const TURN_LIMIT = { windowMs: 3_600_000, maxRequests: 10 };

/**
 * GET /api/turn-credentials
 *
 * Cloudflare Calls TURN 임시 크레덴셜 발급
 * TTL: 300초 (5분) — WebRTC 연결 수립 후 크레덴셜 만료되어도 기존 연결 유지
 */
export async function GET(request: Request) {
  try {
    const ip = getClientIp(new Headers(request.headers));
    const rateCheck = await checkRateLimit(`turn:${ip}`, TURN_LIMIT);
    if (!rateCheck.allowed) {
      return NextResponse.json({ error: 'Too many requests' }, { status: 429 });
    }

    const keyId = process.env.CLOUDFLARE_TURN_KEY_ID;
    const apiToken = process.env.CLOUDFLARE_TURN_KEY_API_TOKEN;

    if (!keyId || !apiToken) {
      return NextResponse.json(
        { error: 'TURN server not configured' },
        { status: 503 }
      );
    }

    const response = await fetch(
      `https://rtc.live.cloudflare.com/v1/turn/keys/${keyId}/credentials/generate-ice-servers`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ ttl: 300 }),
      }
    );

    if (!response.ok) {
      return NextResponse.json(
        { error: 'Failed to generate TURN credentials' },
        { status: 502 }
      );
    }

    // Cloudflare 응답: { iceServers: { urls: [...], username, credential } }
    const data = await response.json();

    return NextResponse.json({
      iceServers: data.iceServers,
    });
  } catch {
    return NextResponse.json({ error: 'Internal error' }, { status: 500 });
  }
}
