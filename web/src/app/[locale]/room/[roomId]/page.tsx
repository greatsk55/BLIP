import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';
import RoomPageClient from './RoomPageClient';

type Props = {
  params: Promise<{ locale: string; roomId: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Metadata' });

  return {
    title: t('roomTitle'),
    description: t('roomDescription'),
    openGraph: {
      title: t('roomTitle'),
      description: t('roomDescription'),
      url: siteConfig.url,
      siteName: siteConfig.name,
      images: [{
        url: `/api/og?locale=${locale}&type=room`,
        width: 1200,
        height: 630,
      }],
    },
    twitter: {
      card: 'summary_large_image',
      title: t('roomTitle'),
      description: t('roomDescription'),
      images: [`/api/og?locale=${locale}&type=room`],
    },
    robots: {
      index: false,
      follow: false,
    },
  };
}

export default async function RoomPage({ params }: Props) {
  const { roomId } = await params;

  // 비밀번호는 URL fragment(#p=...)로 전달되어 서버에 도달하지 않음
  // 클라이언트 컴포넌트(RoomPageClient)에서 window.location.hash로 읽음
  return <RoomPageClient roomId={roomId} />;
}
