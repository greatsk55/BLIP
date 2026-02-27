import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from './config';

type PageMetadataOptions = {
  locale: string;
  titleKey: string;
  descriptionKey: string;
  path: string;
  noIndex?: boolean;
};

export async function generatePageMetadata({
  locale,
  titleKey,
  descriptionKey,
  path,
  noIndex = false,
}: PageMetadataOptions): Promise<Metadata> {
  const t = await getTranslations({ locale, namespace: 'Metadata' });
  const title = t(titleKey);
  const description = t(descriptionKey);

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      url: `${siteConfig.url}/${locale}${path}`,
      siteName: siteConfig.name,
      images: [{
        url: `/api/og?locale=${locale}`,
        width: 1200,
        height: 630,
        alt: title,
      }],
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
    },
    ...(noIndex && {
      robots: { index: false, follow: false },
    }),
  };
}
