/** Apple expects an ES256 JWT with a 64-byte IEEE P1363 signature. */
export async function generateAppleClientSecret(
  teamId: string, clientId: string, keyId: string, privateKeyPem: string,
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const encode = (value: object) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const header = encode({ alg: 'ES256', kid: keyId });
  const payload = encode({ iss: teamId, iat: now, exp: now + 300,
    aud: 'https://appleid.apple.com', sub: clientId });
  const pem = privateKeyPem.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, '');
  const key = await crypto.subtle.importKey('pkcs8', Buffer.from(pem, 'base64'),
    { name: 'ECDSA', namedCurve: 'P-256' }, false, ['sign']);
  // Web Crypto already returns raw r||s. Interpreting it as DER corrupts the JWT.
  const signature = new Uint8Array(await crypto.subtle.sign(
    { name: 'ECDSA', hash: 'SHA-256' }, key, new TextEncoder().encode(`${header}.${payload}`)));
  if (signature.length !== 64) throw new Error('Invalid ES256 signature length');
  return `${header}.${payload}.${Buffer.from(signature).toString('base64url')}`;
}
