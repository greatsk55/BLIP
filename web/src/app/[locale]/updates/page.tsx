import type { Metadata } from 'next';
import { generatePageMetadata } from '@/lib/seo/metadata';
import UpdatesClient from './UpdatesClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'updatesTitle',
    descriptionKey: 'updatesDescription',
    path: '/updates',
  });
}

export default function UpdatesPage() {
  return <UpdatesClient />;
}
