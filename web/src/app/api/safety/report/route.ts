import { createHash, createHmac, randomUUID, timingSafeEqual } from 'node:crypto';
import { createServerSupabase } from '@/lib/supabase/server';
import { checkOrigin, parseJsonBody, isString } from '@/lib/api-utils';
import { checkRateLimit, getClientIp } from '@/lib/rate-limit';

const REASONS = new Set(['harassment', 'sexual', 'hate', 'violence', 'scam', 'other']);
const BUCKET = 'abuse-reports';

/** Reports are explicitly user-submitted exceptions to ephemeral chat storage.
 * The private bucket is service-role-only; room keys and raw IPs are never stored.
 */
export async function POST(request: Request) {
  try {
    if (!checkOrigin(request)) return Response.json({ error: 'FORBIDDEN' }, { status: 403 });
    const body = await parseJsonBody(request);
    if (!body || !isString(body.roomId) || !/^[a-zA-Z0-9]{6,32}$/.test(body.roomId)
        || !isString(body.authKeyHash) || !isString(body.reason) || !REASONS.has(body.reason)) {
      return Response.json({ error: 'INVALID_REPORT' }, { status: 400 });
    }
    const messages: { content: string; senderName: string; timestamp: number }[] = [];
    if (body.messages !== undefined) {
      if (body.includeEvidence !== true || !Array.isArray(body.messages) || body.messages.length > 4) {
        return Response.json({ error: 'EVIDENCE_CONSENT_REQUIRED' }, { status: 400 });
      }
      for (const message of body.messages) {
        if (!message || typeof message !== 'object'
            || typeof message.content !== 'string' || message.content.length > 5000
            || typeof message.senderName !== 'string' || message.senderName.length > 80
            || typeof message.timestamp !== 'number' || !Number.isFinite(message.timestamp)) {
          return Response.json({ error: 'INVALID_EVIDENCE' }, { status: 400 });
        }
        messages.push({ content: message.content, senderName: message.senderName, timestamp: message.timestamp });
      }
    }
    const ip = getClientIp(new Headers(request.headers));
    const limit = await checkRateLimit(`safety-report:${ip}`, { windowMs: 3_600_000, maxRequests: 3 });
    if (!limit.allowed) return Response.json({ error: 'TOO_MANY_REQUESTS' }, { status: 429 });
    const supabase = createServerSupabase();
    const { data: room } = await supabase.from('rooms').select('auth_key_hash').eq('id', body.roomId).single();
    const digest = (value: string) => createHash('sha256').update(value).digest();
    if (!room || !timingSafeEqual(digest(body.authKeyHash), digest(room.auth_key_hash))) {
      return Response.json({ error: 'UNAUTHORIZED' }, { status: 401 });
    }
    const { data: bucket } = await supabase.storage.getBucket(BUCKET);
    if (!bucket) {
      const { error } = await supabase.storage.createBucket(BUCKET, {
        public: false, fileSizeLimit: 65536, allowedMimeTypes: ['application/json'],
      });
      if (error && !/already exists/i.test(error.message)) throw error;
      const { data: createdBucket } = await supabase.storage.getBucket(BUCKET);
      if (!createdBucket || createdBucket.public) throw new Error('Unsafe report bucket configuration');
    } else if (bucket.public) {
      // Fail closed if an administrator accidentally exposes the moderation bucket.
      throw new Error('Unsafe report bucket configuration');
    }
    const reportId = randomUUID();
    const report = {
      reportId, roomId: body.roomId, reason: body.reason,
      createdAt: new Date().toISOString(),
      reporter: createHmac('sha256', process.env.SUPABASE_SERVICE_ROLE_KEY!).update(ip).digest('hex'),
      includeEvidence: body.includeEvidence === true,
      ...(body.includeEvidence === true ? { messages } : {}),
    };
    const { error } = await supabase.storage.from(BUCKET).upload(`${reportId}.json`,
      JSON.stringify(report), { contentType: 'application/json', upsert: false });
    if (error) throw error;
    return Response.json({ reportId });
  } catch {
    return Response.json({ error: 'REPORT_UNAVAILABLE' }, { status: 503 });
  }
}
