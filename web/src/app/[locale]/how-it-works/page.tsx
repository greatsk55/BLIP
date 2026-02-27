import type { Metadata } from 'next';
import { generatePageMetadata } from '@/lib/seo/metadata';
import HowItWorksClient from './HowItWorksClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'howItWorksTitle',
    descriptionKey: 'howItWorksDescription',
    path: '/how-it-works',
  });
}

export default function HowItWorksPage() {
  return <HowItWorksClient />;
}
