import type { Metadata } from 'next';
import { siteConfig } from '@/lib/seo/config';
import BlipMeVisitor from './BlipMeVisitor';

type Props = {
  params: Promise<{ linkId: string }>;
};

export async function generateMetadata(): Promise<Metadata> {
  return {
    title: `BLIP me | ${siteConfig.name}`,
    description: 'Someone wants to chat with you. Click to connect instantly.',
    openGraph: {
      title: `BLIP me | ${siteConfig.name}`,
      description: 'Someone wants to chat with you. Click to connect instantly.',
      url: siteConfig.url,
      siteName: siteConfig.name,
      images: [{
        url: `/api/og?type=blipme`,
        width: 1200,
        height: 630,
      }],
    },
    twitter: {
      card: 'summary_large_image',
      title: `BLIP me | ${siteConfig.name}`,
      description: 'Someone wants to chat with you. Click to connect instantly.',
    },
    robots: {
      index: false,
      follow: false,
    },
  };
}

export default async function BlipMePage({ params }: Props) {
  const { linkId } = await params;
  return <BlipMeVisitor linkId={linkId} />;
}
