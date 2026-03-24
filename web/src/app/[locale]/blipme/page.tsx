import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import BlipMeClient from './BlipMeClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'BlipMe' });

  return {
    title: t('pageTitle'),
    description: t('pageDescription'),
    openGraph: {
      title: t('pageTitle'),
      description: t('pageDescription'),
      url: `${siteConfig.url}/${locale}/blipme`,
      siteName: siteConfig.name,
    },
  };
}

export default async function BlipMePage() {
  return <BlipMeClient />;
}
