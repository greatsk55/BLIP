import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { generatePageMetadata } from '@/lib/seo/metadata';
import { siteConfig } from '@/lib/seo/config';
import FAQClient from './FAQClient';

type Props = {
  params: Promise<{ locale: string }>;
};

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  return generatePageMetadata({
    locale,
    titleKey: 'faqTitle',
    descriptionKey: 'faqDescription',
    path: '/faq',
  });
}

export default async function FAQPage({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'FAQ' });

  const faqItems = [1, 2, 3].map((i) => ({
    '@type': 'Question' as const,
    name: t(`items.${i}.question`),
    acceptedAnswer: {
      '@type': 'Answer' as const,
      text: t(`items.${i}.answer`),
    },
  }));

  const jsonLd = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqItems,
    url: `${siteConfig.url}/${locale}/faq`,
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <FAQClient />
    </>
  );
}
