export const CHUNK_SIZE = 64 * 1024; // 64KB (Safari DataChannel 안전 범위)

/**
 * 파일을 64KB 청크로 분할
 */
export function splitIntoChunks(data: Uint8Array): Uint8Array[] {
  const chunks: Uint8Array[] = [];
  for (let offset = 0; offset < data.length; offset += CHUNK_SIZE) {
    chunks.push(data.slice(offset, offset + CHUNK_SIZE));
  }
  return chunks;
}

/**
 * 청크 배열을 하나의 Uint8Array로 재조립
 */
export function reassembleChunks(
  chunks: Map<number, Uint8Array>,
  totalChunks: number
): Uint8Array {
  let totalLength = 0;
  for (let i = 0; i < totalChunks; i++) {
    const chunk = chunks.get(i);
    if (!chunk) throw new Error(`Missing chunk ${i}`);
    totalLength += chunk.length;
  }

  const result = new Uint8Array(totalLength);
  let offset = 0;
  for (let i = 0; i < totalChunks; i++) {
    const chunk = chunks.get(i)!;
    result.set(chunk, offset);
    offset += chunk.length;
  }

  return result;
}

/**
 * SHA-256 해시 계산 (무결성 검증)
 */
export async function computeChecksum(data: Uint8Array): Promise<string> {
  // @ts-expect-error -- TS strict ArrayBuffer typing vs runtime Uint8Array acceptance
  const hash = await crypto.subtle.digest('SHA-256', data);
  return arrayBufferToHex(hash);
}

/**
 * checksum 검증
 */
export async function verifyChecksum(
  data: Uint8Array,
  expectedChecksum: string
): Promise<boolean> {
  const actual = await computeChecksum(data);
  return actual === expectedChecksum;
}

function arrayBufferToHex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}
