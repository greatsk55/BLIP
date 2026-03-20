import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import MyRoomsClient from './MyRoomsClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Metadata' });

  return {
    title: t('myRoomsTitle'),
    description: t('myRoomsDescription'),
    openGraph: {
      title: t('myRoomsTitle'),
      description: t('myRoomsDescription'),
      url: `${siteConfig.url}/${locale}/my-rooms`,
      siteName: siteConfig.name,
    },
  };
}

export default async function MyRoomsPage() {
  return <MyRoomsClient />;
}
