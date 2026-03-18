import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import GroupRoomClient from './GroupRoomClient';

type Props = {
  params: Promise<{ locale: string; roomId: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Group' });

  return {
    title: t('room.pageTitle'),
    description: t('room.pageDescription'),
    robots: { index: false, follow: false },
  };
}

export default async function GroupRoomPage({ params }: Props) {
  const { roomId } = await params;
  return <GroupRoomClient roomId={roomId} />;
}
