import {defineRouting} from 'next-intl/routing';

export const routing = defineRouting({
  locales: ['ko', 'en', 'ja', 'es', 'fr', 'zh'],
  defaultLocale: 'ko'
});
