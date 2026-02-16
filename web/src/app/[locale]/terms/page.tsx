"use client";

import { useTranslations } from "next-intl";
import LegalPageLayout from "@/components/LegalPageLayout";

const SECTION_COUNT = 11;

export default function TermsPage() {
  const t = useTranslations("Terms");

  const sections = Array.from({ length: SECTION_COUNT }, (_, i) => ({
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
