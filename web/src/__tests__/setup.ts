import '@testing-library/jest-dom/vitest';

// jsdom에는 Web Crypto API (SubtleCrypto)가 없으므로 Node.js의 crypto를 사용
import { webcrypto } from 'node:crypto';

if (!globalThis.crypto?.subtle) {
  Object.defineProperty(globalThis, 'crypto', {
    value: webcrypto,
  });
}
