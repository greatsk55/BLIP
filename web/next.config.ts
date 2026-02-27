import createNextIntlPlugin from 'next-intl/plugin';
 
const withNextIntl = createNextIntlPlugin(
  './src/i18n/request.ts'
);
 
/** @type {import('next').NextConfig} */
const nextConfig = {
  async headers() {
    return [
      // AASA: Apple Universal Links — Content-Type must be application/json
      {
        source: '/.well-known/apple-app-site-association',
        headers: [
          { key: 'Content-Type', value: 'application/json' },
        ],
      },
      {
        source: '/(.*)',
        headers: [
          { key: 'X-Frame-Options', value: 'DENY' },
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
          {
            key: 'Content-Security-Policy',
            value: [
              "default-src 'self'",
              "script-src 'self' 'unsafe-inline' 'unsafe-eval' https://quge5.com https://al5sm.com https://gizokraijaw.net https://5gvci.com",
              "style-src 'self' 'unsafe-inline'",
              "img-src 'self' data: blob: https://*.monetag.com https://*.gizokraijaw.net",
              "media-src 'self' blob:",
              "font-src 'self'",
              "connect-src 'self' wss://*.supabase.co https://*.supabase.co https://quge5.com https://al5sm.com https://gizokraijaw.net https://5gvci.com",
              "frame-src https://quge5.com https://al5sm.com https://gizokraijaw.net",
              "frame-ancestors 'none'",
              "base-uri 'self'",
              "form-action 'self'",
            ].join('; '),
          },
        ],
      },
    ];
  },
};
 
export default withNextIntl(nextConfig);
