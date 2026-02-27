import type { Metadata } from 'next';
import { generatePageMetadata } from '@/lib/seo/metadata';
import AboutClient from './AboutClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'aboutTitle',
    descriptionKey: 'aboutDescription',
    path: '/about',
  });
}

export default function AboutPage() {
  return <AboutClient />;
}
