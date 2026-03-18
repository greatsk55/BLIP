import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import GroupCreateClient from './GroupCreateClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Group' });

  return {
    title: t('create.pageTitle'),
    description: t('create.pageDescription'),
    robots: { index: false, follow: false },
  };
}

export default async function GroupCreatePage() {
  return <GroupCreateClient />;
}
