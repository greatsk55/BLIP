import type { Metadata, Viewport } from "next";
import { Geist_Mono } from "next/font/google";
import "../globals.css";
import { NextIntlClientProvider } from 'next-intl';
import { ThemeProvider } from "@/components/ThemeProvider";
import { routing } from '@/i18n/routing';

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "BLIP Embed",
  robots: { index: false, follow: false },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  interactiveWidget: "resizes-content",
};

export default async function EmbedLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // embed에서는 쿠키/헤더 기반 locale 대신 클라이언트에서 ?lang= 으로 결정
  // 서버에서는 기본 locale로 메시지를 로드하고, 클라이언트에서 동적으로 변경
  const locale = routing.defaultLocale;
  const messages = (await import(`../../../messages/${locale}.json`)).default;

  return (
    <html lang={locale} suppressHydrationWarning>
      <body className={`${geistMono.variable} antialiased bg-void-black`}>
        <ThemeProvider>
          <NextIntlClientProvider messages={messages} locale={locale}>
            {children}
          </NextIntlClientProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
