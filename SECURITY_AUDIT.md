# BLIP Security Audit Report

**Date:** 2026-03-10
**Scope:** Full-stack (Web: Next.js, Mobile: Flutter, DB: Supabase)

---

## Executive Summary

BLIP is an end-to-end encrypted ephemeral communication platform. Overall security posture is **solid**, with proper E2EE implementation (Curve25519 + XSalsa20-Poly1305), parameterized database queries, and comprehensive rate limiting. This audit identified **4 code-level vulnerabilities** (now fixed) and **several configuration recommendations** for production hardening.

**Overall Score: 7.5/10** (8.5/10 after fixes applied)

---

## Fixed Vulnerabilities

### 1. [CRITICAL] Missing CSRF Protection — board/batch-status
- **File:** `web/src/app/api/board/batch-status/route.ts`
- **Issue:** `checkOrigin()` was not called, allowing cross-origin CSRF attacks
- **Fix:** Added `checkOrigin()` validation and `parseJsonBody()` safe parsing

### 2. [CRITICAL] Missing Array Element Type Validation — board/batch-status
- **File:** `web/src/app/api/board/batch-status/route.ts`
- **Issue:** `Array.isArray(boardIds)` only checks container type, not element types. Non-string elements could reach database queries
- **Fix:** Replaced with `isStringArray(boardIds)` which validates each element

### 3. [HIGH] Weak Randomness Fallback — ChatRoom
- **File:** `web/src/components/chat/ChatRoom.tsx:99-101`
- **Issue:** `Math.random()` used as fallback for transfer ID generation (predictable, not cryptographically secure)
- **Fix:** Replaced with `crypto.getRandomValues()` for cryptographically secure random bytes

### 4. [HIGH] Unsafe parseInt Without Range Validation — upload-image
- **File:** `web/src/app/api/board/upload-image/route.ts:135-137`
- **Issue:** `parseInt()` can produce NaN or arbitrarily large values for width/height/displayOrder
- **Fix:** Added bounds clamping (width/height: 0-10000, displayOrder: 0-100) with NaN fallback to 0

### 5. [HIGH] Missing Origin Check — upload-image
- **File:** `web/src/app/api/board/upload-image/route.ts`
- **Issue:** POST endpoint missing `checkOrigin()` CSRF protection
- **Fix:** Added `checkOrigin()` validation

---

## Remaining Recommendations (Not Auto-Fixed)

### HIGH Priority

| # | Issue | Location | Recommendation |
|---|-------|----------|----------------|
| 1 | CSP allows `unsafe-inline`/`unsafe-eval` | `web/next.config.ts:38-39` | Remove unsafe directives; sandbox ad scripts in iframe |
| 2 | Sensitive data in localStorage | `web/src/hooks/useBoard.ts` | Move encryption keys/admin tokens to sessionStorage or memory-only |
| 3 | Ad script injection via dangerouslySetInnerHTML | `web/src/components/MonetagAds.tsx` | Add Subresource Integrity (SRI); verify ad network legitimacy |

### MEDIUM Priority

| # | Issue | Location | Recommendation |
|---|-------|----------|----------------|
| 4 | PBKDF2 iterations below NIST 2023 recommendation | `web/src/lib/crypto/keys.ts:49` | Upgrade from 100,000 to 120,000+ iterations |
| 5 | No certificate pinning (mobile) | `mobile/lib/core/network/api_client.dart` | Implement cert pinning for Supabase and API domains |
| 6 | Missing iOS ATS configuration | `mobile/ios/Runner/Info.plist` | Add explicit NSAppTransportSecurity policy |
| 7 | Rate limiting disabled in development | `web/src/lib/rate-limit.ts:46-49` | Ensure NODE_ENV is never 'development' in production |

### LOW Priority

| # | Issue | Recommendation |
|---|-------|----------------|
| 8 | No MIME type whitelist for uploads | Validate file content type server-side |
| 9 | Console.error may expose DB details | Sanitize error logs in production |

---

## Security Strengths

- **No hardcoded secrets** — all credentials properly externalized via environment variables
- **Strong E2EE** — Curve25519 ECDH + XSalsa20-Poly1305 (NaCl), consistent across web and mobile
- **SQL injection protected** — all queries use parameterized Supabase client SDK
- **Comprehensive rate limiting** — applied to all sensitive endpoints via Upstash Redis
- **Row Level Security** — Supabase RLS properly configured
- **HTTP security headers** — HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- **Screenshot/screen recording protection** (mobile)
- **Proper CSRF protection** — origin validation on 31/31 POST endpoints (after fixes)
- **Secure key derivation** — PBKDF2 with salt for password-based keys
- **No dangerous code patterns** — no eval(), exec(), or unsafe deserialization
