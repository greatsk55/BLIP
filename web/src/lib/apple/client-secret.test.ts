// @vitest-environment node
import { expect, it } from 'vitest';
import { generateAppleClientSecret } from './client-secret';

it('produces an Apple ES256 JWT that verifies with the matching public key', async () => {
  const keys = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
  const privateDer = await crypto.subtle.exportKey('pkcs8', keys.privateKey);
  const pem = `-----BEGIN PRIVATE KEY-----\n${Buffer.from(privateDer).toString('base64')}\n-----END PRIVATE KEY-----`;
  const jwt = await generateAppleClientSecret('test-team', 'com.bakkum.blip', 'test-key', pem);
  const [header, payload, signature] = jwt.split('.');
  const raw = Buffer.from(signature, 'base64url');
  expect(raw.length).toBe(64);
  expect(await crypto.subtle.verify({ name: 'ECDSA', hash: 'SHA-256' }, keys.publicKey,
    raw, new TextEncoder().encode(`${header}.${payload}`))).toBe(true);
  const claims = JSON.parse(Buffer.from(payload, 'base64url').toString());
  expect(claims).toMatchObject({ iss: 'test-team', sub: 'com.bakkum.blip', aud: 'https://appleid.apple.com' });
  expect(claims.exp - claims.iat).toBe(300);
});
