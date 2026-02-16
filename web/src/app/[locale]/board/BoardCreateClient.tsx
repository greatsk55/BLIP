'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { motion } from 'framer-motion';
import { MessageSquarePlus } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { createBoard, updateBoardName } from '@/lib/board/actions';
import { deriveKeysFromPassword, hashAuthKey, encryptSymmetric } from '@/lib/crypto';
import { saveAdminTokenToStorage } from '@/hooks/useBoard';
import { ThemeToggle } from '@/components/ThemeToggle';
import BoardCreatedView from '@/components/board/BoardCreatedView';

export default function BoardCreateClient() {
  const t = useTranslations('Board');
  const router = useRouter();

  const [boardName, setBoardName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createResult, setCreateResult] = useState<{
    boardId: string;
    password: string;
    adminToken: string;
  } | null>(null);

  const handleCreate = useCallback(async () => {
    if (!boardName.trim() || loading) return;

    setLoading(true);
    setError(null);

    // 1단계: 서버에서 boardId + password + adminToken 생성
    const result = await createBoard('', '');

    if ('error' in result) {
      setError(result.error);
      setLoading(false);
      return;
    }

    // 2단계: 반환된 비밀번호로 암호화 키 유도 → 게시판 이름 암호화 → 서버 업데이트
    const { encryptionSeed, authKey } = await deriveKeysFromPassword(result.password, result.boardId);
    const encName = encryptSymmetric(boardName.trim(), encryptionSeed);
    const authKeyHash = await hashAuthKey(authKey);

    const updateResult = await updateBoardName(
      result.boardId,
      authKeyHash,
      encName.ciphertext,
      encName.nonce
    );

    if (!updateResult.success) {
      setError(updateResult.error ?? 'UPDATE_FAILED');
      setLoading(false);
      return;
    }

    // 관리자 토큰을 localStorage에 자동 저장
    saveAdminTokenToStorage(result.boardId, result.adminToken);

    setCreateResult(result);
    setLoading(false);
  }, [boardName, loading]);

  // 생성 완료 화면
  if (createResult) {
    return (
      <BoardCreatedView
        boardId={createResult.boardId}
        password={createResult.password}
        adminToken={createResult.adminToken}
        onEnter={() => router.push(`/board/${createResult.boardId}`)}
      />
    );
  }

  // 생성 폼
  return (
    <div className="h-dvh bg-void-black flex items-center justify-center px-6 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
        <ThemeToggle />
      </div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-sm text-center"
      >
        <MessageSquarePlus className="w-8 h-8 text-signal-green/40 mx-auto mb-6" />

        <h1 className="font-mono text-sm text-ghost-grey uppercase tracking-[0.3em] mb-8">
          {t('create.subtitle')}
        </h1>

        <input
          type="text"
          value={boardName}
          onChange={(e) => setBoardName(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
          placeholder={t('create.namePlaceholder')}
          maxLength={50}
          autoFocus
          autoComplete="off"
          className="w-full bg-transparent border-b-2 border-ink/10 focus:border-signal-green text-ink font-mono text-lg text-center tracking-wider py-4 outline-none transition-colors placeholder:text-ink/10"
        />

        {error && (
          <motion.p
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="mt-4 font-mono text-xs text-glitch-red uppercase tracking-wider"
          >
            {error}
          </motion.p>
        )}

        <motion.button
          whileHover={{ scale: 1.02 }}
          whileTap={{ scale: 0.98 }}
          onClick={handleCreate}
          disabled={!boardName.trim() || loading}
          className="mt-10 w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-signal-green"
        >
          {loading ? '...' : t('create.createButton')}
        </motion.button>
      </motion.div>
    </div>
  );
}
