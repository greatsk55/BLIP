import type { Metadata } from 'next';
import { generatePageMetadata } from '@/lib/seo/metadata';
import TermsClient from './TermsClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'termsTitle',
    descriptionKey: 'termsDescription',
    path: '/terms',
  });
}

export default function TermsPage() {
  return <TermsClient />;
}
