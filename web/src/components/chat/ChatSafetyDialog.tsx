'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { deriveKeysFromPassword, hashAuthKey } from '@/lib/crypto';
import type { DecryptedMessage } from '@/types/chat';

export default function ChatSafetyDialog({ roomId, password, messages, onBlock, onClose }: {
  roomId: string; password: string; messages: DecryptedMessage[];
  onBlock: () => Promise<void>; onClose: () => void;
}) {
  const t = useTranslations('Safety');
  const [reason, setReason] = useState('harassment');
  const [includeEvidence, setIncludeEvidence] = useState(false);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState('');

  async function submitReport() {
    setBusy(true); setStatus('');
    try {
      const keys = await deriveKeysFromPassword(password, roomId);
      const authKeyHash = await hashAuthKey(keys.authKey);
      keys.authKey.fill(0); keys.encryptionSeed.fill(0);
      const response = await fetch('/api/safety/report', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ roomId, authKeyHash, reason, includeEvidence,
          ...(includeEvidence ? { messages: messages.filter(m => m.type === 'text').slice(-4)
            .map(({ content, senderName, timestamp }) => ({ content, senderName, timestamp })) } : {}),
        }),
      });
      if (!response.ok) throw new Error('report rejected');
      setStatus(t('reported'));
    } catch { setStatus(t('failed')); }
    finally { setBusy(false); }
  }

  async function block() {
    setBusy(true); setStatus('');
    try { await onBlock(); }
    catch { setStatus(t('failed')); setBusy(false); }
  }

  return <div className="fixed inset-0 z-[100] bg-black/70 flex items-center justify-center p-5">
    <section role="dialog" aria-modal="true" aria-labelledby="chat-safety-title"
      className="bg-void-black border border-ink/20 p-6 w-full max-w-md space-y-5">
      <h2 id="chat-safety-title" className="font-mono text-lg text-ink">{t('title')}</h2>
      <p className="text-sm text-ghost-grey">{t('notice')}</p>
      <label className="block text-sm text-ink">{t('reason')}
        <select value={reason} onChange={e => setReason(e.target.value)} disabled={busy}
          className="block mt-2 w-full bg-void-black border border-ink/20 p-2">
          {['harassment','sexual','hate','violence','scam','other'].map(reason =>
            <option key={reason} value={reason}>{t(reason)}</option>)}
        </select>
      </label>
      <label className="flex gap-3 text-sm text-ghost-grey">
        <input type="checkbox" checked={includeEvidence} disabled={busy}
          onChange={e => setIncludeEvidence(e.target.checked)} />{t('evidence')}
      </label>
      {status && <p role="status" className="text-sm text-signal-green">{status}</p>}
      <button disabled={busy} onClick={submitReport} className="w-full min-h-11 border border-ink/30 p-3 text-ink disabled:opacity-40">{t('report')}</button>
      <button disabled={busy} onClick={block} className="w-full min-h-11 border border-glitch-red/60 p-3 text-glitch-red disabled:opacity-40">{t('block')}</button>
      <p className="text-xs text-ghost-grey">{t('blockNotice')}</p>
      <a className="block text-sm text-signal-green" href="mailto:wonwookimnida@gmail.com">wonwookimnida@gmail.com</a>
      <button disabled={busy} onClick={onClose} className="w-full min-h-11 text-ghost-grey">{t('close')}</button>
    </section>
  </div>;
}
