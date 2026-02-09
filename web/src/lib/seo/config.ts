import { routing } from '@/i18n/routing';

export const siteConfig = {
  url: process.env.NEXT_PUBLIC_SITE_URL || 'https://blip-blip.vercel.app',
  name: 'BLIP',
  locales: routing.locales,
  defaultLocale: routing.defaultLocale,
} as const;
