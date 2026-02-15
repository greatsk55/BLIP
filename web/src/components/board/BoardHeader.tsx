'use client';

import { useRouter } from 'next/navigation';
import { Shield, KeyRound, RefreshCw } from 'lucide-react';
import { useTranslations } from 'next-intl';

interface BoardHeaderProps {
  boardName: string;
  onAdmin: () => void;
  hasAdminToken: boolean;
  isPasswordSaved: boolean;
  onForgetPassword: () => void;
}

export default function BoardHeader({
  boardName,
  onAdmin,
  hasAdminToken,
  isPasswordSaved,
  onForgetPassword,
}: BoardHeaderProps) {
  const t = useTranslations('Board');
  const router = useRouter();

  return (
    <header className="flex-shrink-0 flex items-center justify-between px-4 py-3 border-b border-ink/10 bg-void-black/80 backdrop-blur-sm pt-[env(safe-area-inset-top)]">
      <div className="flex items-center gap-3 min-w-0">
        <button
          onClick={() => router.push('/')}
          className="font-mono text-xs text-ghost-grey/40 hover:text-ghost-grey transition-colors"
          aria-label="Back to home"
        >
          ←
        </button>
        <div className="min-w-0">
          <h1 className="font-mono text-sm text-ink uppercase tracking-wider truncate">
            {boardName}
          </h1>
          <p className="font-mono text-[9px] text-signal-green/60 uppercase tracking-wider">
            {t('header.encrypted')}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2">
        {isPasswordSaved && (
          <button
            onClick={onForgetPassword}
            className="p-2 text-ghost-grey/40 hover:text-glitch-red transition-colors"
            aria-label={t('header.forgetPassword')}
            title={t('header.forgetPassword')}
          >
            <KeyRound className="w-4 h-4" />
          </button>
        )}

        {hasAdminToken && (
          <button
            onClick={onAdmin}
            className="p-2 text-ghost-grey/40 hover:text-signal-green transition-colors"
            aria-label={t('header.admin')}
            title={t('header.admin')}
          >
            <Shield className="w-4 h-4" />
          </button>
        )}
      </div>
    </header>
  );
}
