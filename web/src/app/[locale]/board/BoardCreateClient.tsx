'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { motion, AnimatePresence } from 'framer-motion';
import { MessageSquarePlus, LogIn } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { createBoard, updateBoardName } from '@/lib/board/actions';
import { deriveKeysFromPassword, hashAuthKey, encryptSymmetric } from '@/lib/crypto';
import { saveAdminTokenToStorage, savePassword, saveBoardName, saveBoardSubtitle } from '@/hooks/useBoard';
import { ThemeToggle } from '@/components/ThemeToggle';
import SavedBoardsList from '@/components/board/SavedBoardsList';

/** 생성 직후 정보를 sessionStorage에 임시 저장 (BoardRoom에서 모달로 표시) */
const CREATED_INFO_PREFIX = 'blip-board-created-';

export function getCreatedInfo(boardId: string): { password: string; adminToken: string; inviteCode?: string } | null {
  if (typeof window === 'undefined') return null;
  const raw = sessionStorage.getItem(`${CREATED_INFO_PREFIX}${boardId}`);
  if (!raw) return null;
  sessionStorage.removeItem(`${CREATED_INFO_PREFIX}${boardId}`);
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

type TabMode = 'create' | 'join';

export default function BoardCreateClient() {
  const t = useTranslations('Board');
  const router = useRouter();

  const [mode, setMode] = useState<TabMode>('create');

  // ─── 생성 모드 ───
  const [boardName, setBoardName] = useState('');
  const [boardSubtitle, setBoardSubtitle] = useState('');
  const [createLoading, setCreateLoading] = useState(false);
  const [createError, setCreateError] = useState<string | null>(null);

  // ─── 참여 모드 ───
  const [joinBoardId, setJoinBoardId] = useState('');
  const [joinPassword, setJoinPassword] = useState('');
  const [joinLoading, setJoinLoading] = useState(false);
  const [joinError, setJoinError] = useState<string | null>(null);

  // ─── 생성 핸들러 ───
  const handleCreate = useCallback(async () => {
    if (!boardName.trim() || createLoading) return;

    setCreateLoading(true);
    setCreateError(null);

    const result = await createBoard('', '');

    if ('error' in result) {
      setCreateError(result.error);
      setCreateLoading(false);
      return;
    }

    // 암호화 키 유도 → 이름/부제목 암호화 → 서버 업데이트
    const { encryptionSeed, authKey } = await deriveKeysFromPassword(result.password, result.boardId);
    const encName = encryptSymmetric(boardName.trim(), encryptionSeed);
    const authKeyHash = await hashAuthKey(authKey);

    const trimmedSubtitle = boardSubtitle.trim();
    let encSubtitleCiphertext: string | undefined;
    let encSubtitleNonce: string | undefined;
    if (trimmedSubtitle) {
      const encSub = encryptSymmetric(trimmedSubtitle, encryptionSeed);
      encSubtitleCiphertext = encSub.ciphertext;
      encSubtitleNonce = encSub.nonce;
    }

    const updateResult = await updateBoardName(
      result.boardId,
      authKeyHash,
      encName.ciphertext,
      encName.nonce,
      encSubtitleCiphertext,
      encSubtitleNonce
    );

    if (!updateResult.success) {
      setCreateError(updateResult.error ?? 'UPDATE_FAILED');
      setCreateLoading(false);
      return;
    }

    // localStorage에 자동 저장
    savePassword(result.boardId, result.password);
    saveAdminTokenToStorage(result.boardId, result.adminToken);
    saveBoardName(result.boardId, boardName.trim());
    if (trimmedSubtitle) saveBoardSubtitle(result.boardId, trimmedSubtitle);

    // sessionStorage에 생성 정보 임시 저장 (BoardRoom에서 안내 모달 표시용)
    sessionStorage.setItem(
      `${CREATED_INFO_PREFIX}${result.boardId}`,
      JSON.stringify({
        password: result.password,
        adminToken: result.adminToken,
        inviteCode: result.inviteCode,
      })
    );

    // 바로 입장
    router.push(`/board/${result.boardId}`);
  }, [boardName, boardSubtitle, createLoading, router]);

  // ─── 참여 핸들러 ───
  const handleJoin = useCallback(() => {
    const trimmedId = joinBoardId.trim();
    if (!trimmedId || joinLoading) return;

    setJoinLoading(true);
    setJoinError(null);

    // 비밀번호가 있으면 localStorage에 미리 저장 → BoardRoom에서 자동 인증
    const trimmedPw = joinPassword.trim().toUpperCase();
    if (trimmedPw) {
      savePassword(trimmedId, trimmedPw);
    }

    router.push(`/board/${trimmedId}`);
  }, [joinBoardId, joinPassword, joinLoading, router]);

  return (
    <div className="min-h-dvh bg-void-black flex flex-col items-center justify-center px-6 py-12 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <div className="fixed top-4 right-4 z-50 pt-[env(safe-area-inset-top)]">
        <ThemeToggle />
      </div>

      {/* 저장된 커뮤니티 목록 */}
      <SavedBoardsList />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="w-full max-w-sm text-center"
      >
        {/* 탭 전환 */}
        <div className="flex mb-8 border-b border-ink/10 dark:border-ink/20">
          <button
            onClick={() => setMode('create')}
            className={`flex-1 flex items-center justify-center gap-2 py-3 font-mono text-xs uppercase tracking-wider transition-colors ${
              mode === 'create'
                ? 'text-signal-green border-b-2 border-signal-green'
                : 'text-ghost-grey/60 dark:text-ghost-grey/50 hover:text-ghost-grey/80 dark:hover:text-ghost-grey/70'
            }`}
          >
            <MessageSquarePlus className="w-3.5 h-3.5" />
            {t('create.createButton')}
          </button>
          <button
            onClick={() => setMode('join')}
            className={`flex-1 flex items-center justify-center gap-2 py-3 font-mono text-xs uppercase tracking-wider transition-colors ${
              mode === 'join'
                ? 'text-signal-green border-b-2 border-signal-green'
                : 'text-ghost-grey/60 dark:text-ghost-grey/50 hover:text-ghost-grey/80 dark:hover:text-ghost-grey/70'
            }`}
          >
            <LogIn className="w-3.5 h-3.5" />
            {t('join.joinButton')}
          </button>
        </div>

        <AnimatePresence mode="wait">
          {mode === 'create' ? (
            <motion.div
              key="create"
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.2 }}
            >
              <h1 className="font-mono text-sm text-ghost-grey/70 dark:text-ghost-grey uppercase tracking-[0.3em] mb-8">
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
                className="w-full bg-transparent border-b-2 border-ink/10 dark:border-ink/20 focus:border-signal-green text-ink font-mono text-lg text-center tracking-wider py-4 outline-none transition-colors placeholder:text-ink/10 dark:placeholder:text-ink/30"
              />

              <input
                type="text"
                value={boardSubtitle}
                onChange={(e) => setBoardSubtitle(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleCreate()}
                placeholder={t('create.subtitlePlaceholder')}
                maxLength={100}
                autoComplete="off"
                className="w-full bg-transparent border-b border-ink/5 dark:border-ink/15 focus:border-signal-green/50 text-ink/70 font-mono text-sm text-center tracking-wider py-3 outline-none transition-colors placeholder:text-ink/10 dark:placeholder:text-ink/30 mt-2"
              />

              {createError && (
                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="mt-4 font-mono text-xs text-glitch-red uppercase tracking-wider"
                >
                  {createError}
                </motion.p>
              )}

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={handleCreate}
                disabled={!boardName.trim() || createLoading}
                className="mt-10 w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider disabled:opacity-20 dark:disabled:opacity-30 disabled:hover:bg-transparent disabled:hover:text-signal-green"
              >
                {createLoading ? '...' : t('create.createButton')}
              </motion.button>
            </motion.div>
          ) : (
            <motion.div
              key="join"
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 20 }}
              transition={{ duration: 0.2 }}
            >
              <h1 className="font-mono text-sm text-ghost-grey/70 dark:text-ghost-grey uppercase tracking-[0.3em] mb-8">
                {t('join.title')}
              </h1>

              <input
                type="text"
                value={joinBoardId}
                onChange={(e) => setJoinBoardId(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && handleJoin()}
                placeholder={t('join.idPlaceholder')}
                maxLength={50}
                autoFocus
                autoComplete="off"
                className="w-full bg-transparent border-b-2 border-ink/10 dark:border-ink/20 focus:border-signal-green text-ink font-mono text-lg text-center tracking-wider py-4 outline-none transition-colors placeholder:text-ink/10 dark:placeholder:text-ink/30"
              />

              <input
                type="text"
                value={joinPassword}
                onChange={(e) => {
                  const raw = e.target.value.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
                  const formatted = raw.length > 4
                    ? `${raw.slice(0, 4)}-${raw.slice(4, 8)}`
                    : raw;
                  setJoinPassword(formatted);
                }}
                onKeyDown={(e) => e.key === 'Enter' && handleJoin()}
                placeholder={t('join.passwordPlaceholder')}
                maxLength={9}
                autoComplete="off"
                autoCorrect="off"
                autoCapitalize="characters"
                spellCheck={false}
                className="w-full bg-transparent border-b border-ink/5 dark:border-ink/15 focus:border-signal-green/50 text-ink/70 font-mono text-sm text-center tracking-[0.3em] py-3 outline-none transition-colors placeholder:text-ink/10 dark:placeholder:text-ink/30 mt-2"
              />

              <p className="mt-3 font-mono text-[10px] text-ghost-grey/50 dark:text-ghost-grey/60 uppercase tracking-wider">
                {t('join.passwordOptional')}
              </p>

              {joinError && (
                <motion.p
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="mt-4 font-mono text-xs text-glitch-red uppercase tracking-wider"
                >
                  {joinError}
                </motion.p>
              )}

              <motion.button
                whileHover={{ scale: 1.02 }}
                whileTap={{ scale: 0.98 }}
                onClick={handleJoin}
                disabled={!joinBoardId.trim() || joinLoading}
                className="mt-10 w-full min-h-[48px] px-8 py-4 bg-transparent border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-300 rounded-none font-mono text-sm uppercase tracking-wider disabled:opacity-20 dark:disabled:opacity-30 disabled:hover:bg-transparent disabled:hover:text-signal-green"
              >
                {joinLoading ? '...' : t('join.joinButton')}
              </motion.button>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
