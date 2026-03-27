import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import VoteDetailClient from './VoteDetailClient';

type Props = {
  params: Promise<{ locale: string; id: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Metadata' });

  return {
    title: t('voteTitle'),
    description: t('voteDescription'),
    openGraph: {
      title: t('voteTitle'),
      description: t('voteDescription'),
      url: siteConfig.url,
      siteName: siteConfig.name,
    },
    robots: {
      index: false,
      follow: false,
    },
  };
}

export default async function VoteDetailPage({ params }: Props) {
  const { id } = await params;
  return <VoteDetailClient predictionId={id} />;
}
