import type { Metadata } from 'next';
import { generatePageMetadata } from '@/lib/seo/metadata';
import EmbedGuideClient from './EmbedGuideClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'embedGuideTitle',
    descriptionKey: 'embedGuideDescription',
    path: '/embed-guide',
  });
}

export default function EmbedGuidePage() {
  return <EmbedGuideClient />;
}
