"use client";

import { useTranslations } from "next-intl";
import LegalPageLayout from "@/components/LegalPageLayout";

const SECTION_COUNT = 9;

export default function PrivacyClient() {
  const t = useTranslations("Privacy");

  const sections = Array.from({ length: SECTION_COUNT }, (_, i) => ({
    id: i === 7 ? 'data-deletion' : undefined,
    title: t(`sections.${i + 1}.title`),
    content: t(`sections.${i + 1}.content`),
  }));

  return (
    <LegalPageLayout
      subtitle={t("subtitle")}
      title={t("title")}
      lastUpdated={t("lastUpdated")}
      intro={t("intro")}
      sections={sections}
    />
  );
}
