import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import BoardPageClient from './BoardPageClient';

type Props = {
  params: Promise<{ locale: string; boardId: string }>;
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
      url: siteConfig.url,
      siteName: siteConfig.name,
    },
    robots: {
      index: false,
      follow: false,
    },
  };
}

export default async function BoardPage({ params }: Props) {
  const { boardId } = await params;

  return <BoardPageClient boardId={boardId} />;
}
