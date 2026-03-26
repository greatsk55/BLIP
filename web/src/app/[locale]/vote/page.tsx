import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import VoteClient from './VoteClient';

type Props = {
  params: Promise<{ locale: string }>;
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
      url: `${siteConfig.url}/${locale}/vote`,
      siteName: siteConfig.name,
      images: [{
        url: `/api/og?locale=${locale}&type=vote`,
        width: 1200,
        height: 630,
      }],
    },
    twitter: {
      card: 'summary_large_image',
      title: t('voteTitle'),
      description: t('voteDescription'),
      images: [`/api/og?locale=${locale}&type=vote`],
    },
  };
}

export default async function VotePage() {
  return <VoteClient />;
}
