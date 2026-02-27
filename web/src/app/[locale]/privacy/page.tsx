import type { Metadata } from 'next';
import { generatePageMetadata } from '@/lib/seo/metadata';
import PrivacyClient from './PrivacyClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'privacyTitle',
    descriptionKey: 'privacyDescription',
    path: '/privacy',
  });
}

export default function PrivacyPage() {
  return <PrivacyClient />;
}
