import createNextIntlPlugin from 'next-intl/plugin';

const withNextIntl = createNextIntlPlugin(
  './src/i18n/request.ts'
);

/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    const commonSecurityHeaders = [
      { key: 'X-Content-Type-Options', value: 'nosniff' },
      { key: 'Referrer-Policy', value: 'strict-origin-when-cross-origin' },
      { key: 'X-XSS-Protection', value: '1; mode=block' },
      {
        key: 'Strict-Transport-Security',
        value: 'max-age=63072000; includeSubDomains; preload',
      },
      {
        key: 'Permissions-Policy',
        value: 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
      },
    ];

    const embedCSP = [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' https:",
      "style-src 'self' 'unsafe-inline' https:",
      "img-src 'self' data: blob: https:",
      "media-src 'self' blob:",
      "font-src 'self' https:",
      "connect-src 'self' wss://*.supabase.co https://*.supabase.co https:",
      "frame-src 'self' https:",
      "frame-ancestors *",
      "base-uri 'self'",
      "form-action 'self'",
    ].join('; ');

    const embedHeaders = [
      ...commonSecurityHeaders,
      // X-Frame-Options 명시적 허용 (catch-all의 DENY를 오버라이드)
      { key: 'X-Frame-Options', value: 'ALLOWALL' },
      { key: 'Content-Security-Policy', value: embedCSP },
    ];

    return [
      // AASA: Apple Universal Links — Content-Type must be application/json
      {
        source: '/.well-known/apple-app-site-association',
        headers: [
          { key: 'Content-Type', value: 'application/json' },
        ],
      },
      // 기본 경로: iframe 차단 (먼저 선언하여 embed 규칙이 오버라이드할 수 있게)
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
          ...commonSecurityHeaders,
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              // Monetag 광고: 도메인이 동적으로 변경되므로 https: 허용
              "script-src 'self' 'unsafe-inline' 'unsafe-eval' https:",
              "style-src 'self' 'unsafe-inline' https:",
              "img-src 'self' data: blob: https:",
              "media-src 'self' blob:",
              "font-src 'self' https:",
              "connect-src 'self' wss://*.supabase.co https://*.supabase.co https:",
              "frame-src 'self' https:",
              "frame-ancestors 'none'",
              "base-uri 'self'",
              "form-action 'self'",
            ].join('; '),
          },
        ],
      },
      // Embed 루트: iframe 허용 (catch-all 이후 선언하여 오버라이드)
      {
        source: '/embed',
        headers: embedHeaders,
      },
      // Embed 하위 경로: iframe 허용
      {
        source: '/embed/:path*',
        headers: embedHeaders,
      },
    ];
  },
};

export default withNextIntl(nextConfig);
