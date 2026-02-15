import { describe, it, expect } from 'vitest';
import { splitIntoChunks, reassembleChunks, computeChecksum, verifyChecksum, CHUNK_SIZE } from './chunk';

describe('chunk splitting and reassembly', () => {
  it('splits data into correct number of chunks', () => {
    const data = new Uint8Array(CHUNK_SIZE * 3 + 100);
    const chunks = splitIntoChunks(data);

    expect(chunks.length).toBe(4);
    expect(chunks[0].length).toBe(CHUNK_SIZE);
    expect(chunks[1].length).toBe(CHUNK_SIZE);
    expect(chunks[2].length).toBe(CHUNK_SIZE);
    expect(chunks[3].length).toBe(100);
  });

  it('handles exact multiple of chunk size', () => {
    const data = new Uint8Array(CHUNK_SIZE * 2);
    const chunks = splitIntoChunks(data);

    expect(chunks.length).toBe(2);
    expect(chunks[0].length).toBe(CHUNK_SIZE);
    expect(chunks[1].length).toBe(CHUNK_SIZE);
  });

  it('handles single chunk', () => {
    const data = new Uint8Array(100);
    const chunks = splitIntoChunks(data);

    expect(chunks.length).toBe(1);
    expect(chunks[0].length).toBe(100);
  });

  it('handles empty data', () => {
    const data = new Uint8Array(0);
    const chunks = splitIntoChunks(data);

    expect(chunks.length).toBe(0);
  });

  it('reassembles chunks correctly', () => {
    const original = new Uint8Array(CHUNK_SIZE * 2 + 500);
    for (let i = 0; i < original.length; i++) original[i] = i % 256;

    const chunks = splitIntoChunks(original);
    const chunkMap = new Map<number, Uint8Array>();
    chunks.forEach((chunk, i) => chunkMap.set(i, chunk));

    const reassembled = reassembleChunks(chunkMap, chunks.length);
    expect(reassembled).toEqual(original);
  });

  it('reassembles out-of-order chunks', () => {
    const original = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]);
    const chunks = splitIntoChunks(original);

    // 역순으로 삽입
    const chunkMap = new Map<number, Uint8Array>();
    for (let i = chunks.length - 1; i >= 0; i--) {
      chunkMap.set(i, chunks[i]);
    }

    const reassembled = reassembleChunks(chunkMap, chunks.length);
    expect(reassembled).toEqual(original);
  });

  it('throws on missing chunk', () => {
    const chunkMap = new Map<number, Uint8Array>();
    chunkMap.set(0, new Uint8Array([1, 2]));
    // chunk 1 missing

    expect(() => reassembleChunks(chunkMap, 2)).toThrow('Missing chunk 1');
  });
});

describe('checksum', () => {
  it('computes consistent SHA-256', async () => {
    const data = new Uint8Array([1, 2, 3, 4, 5]);
    const hash1 = await computeChecksum(data);
    const hash2 = await computeChecksum(data);

    expect(hash1).toBe(hash2);
    expect(hash1.length).toBe(64); // SHA-256 = 32 bytes = 64 hex chars
  });

  it('different data produces different checksum', async () => {
    const a = new Uint8Array([1, 2, 3]);
    const b = new Uint8Array([1, 2, 4]);

    const hashA = await computeChecksum(a);
    const hashB = await computeChecksum(b);

    expect(hashA).not.toBe(hashB);
  });

  it('verifies correct checksum', async () => {
    const data = new Uint8Array([10, 20, 30]);
    const checksum = await computeChecksum(data);

    expect(await verifyChecksum(data, checksum)).toBe(true);
  });

  it('rejects wrong checksum', async () => {
    const data = new Uint8Array([10, 20, 30]);

    expect(await verifyChecksum(data, 'deadbeef')).toBe(false);
  });
});
