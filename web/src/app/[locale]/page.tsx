import Hero from "@/components/Hero";
import Problem from "@/components/Problem";
import Solution from "@/components/Solution";
import CommunityBoard from "@/components/CommunityBoard";
import Philosophy from "@/components/Philosophy";
import Footer from "@/components/Footer";
import { ThemeToggle } from "@/components/ThemeToggle";
import { getTranslations } from 'next-intl/server';
import { siteConfig } from '@/lib/seo/config';

export default async function Home({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'Metadata' });

  const jsonLd = [
    {
      '@context': 'https://schema.org',
      '@type': 'WebApplication',
      name: siteConfig.name,
      description: t('description'),
      url: `${siteConfig.url}/${locale}`,
      applicationCategory: 'CommunicationApplication',
      operatingSystem: 'Any',
      offers: {
        '@type': 'Offer',
        price: '0',
        priceCurrency: 'USD',
      },
      featureList: [
        'End-to-end encryption',
        'No account required',
        'Ephemeral messages',
        'Zero data retention',
      ],
    },
    {
      '@context': 'https://schema.org',
      '@type': 'Organization',
      name: siteConfig.name,
      url: siteConfig.url,
      logo: `${siteConfig.url}/favicon-96x96.png`,
      sameAs: [
        'https://github.com/greatsk55/BLIP',
      ],
    },
  ];

  return (
    <main className="bg-void-black min-h-screen text-white">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <div className="fixed top-4 right-4 z-50">
        <ThemeToggle />
      </div>
      <Hero />
      <Problem />
      <Solution />
      <CommunityBoard />
      <Philosophy />
      <Footer />
    </main>
  );
}
