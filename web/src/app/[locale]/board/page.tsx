import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import BoardCreateClient from './BoardCreateClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Metadata' });

  return {
    title: t('boardTitle'),
    description: t('boardDescription'),
    openGraph: {
      title: t('boardTitle'),
      description: t('boardDescription'),
      url: `${siteConfig.url}/${locale}/board`,
      siteName: siteConfig.name,
      images: [{
        url: `/api/og?locale=${locale}`,
        width: 1200,
        height: 630,
        alt: t('boardTitle'),
      }],
    },
    twitter: {
      card: 'summary_large_image',
      title: t('boardTitle'),
      description: t('boardDescription'),
    },
  };
}

export default async function BoardCreatePage() {
  return <BoardCreateClient />;
}
