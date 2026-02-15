'use client';

import { useRef, useCallback } from 'react';
import { Paperclip } from 'lucide-react';
import { getMediaType } from '@/lib/media/thumbnail';

interface MediaAttachButtonProps {
  onFileSelected: (file: File) => void;
  disabled?: boolean;
}

const ACCEPT = 'image/*,video/*';

export default function MediaAttachButton({ onFileSelected, disabled }: MediaAttachButtonProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleClick = useCallback(() => {
    inputRef.current?.click();
  }, []);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

      // 미디어 타입 검증
      if (!getMediaType(file.type)) return;

      onFileSelected(file);

      // 같은 파일 재선택 허용
      e.target.value = '';
    },
    [onFileSelected]
  );

  return (
    <>
      <input
        ref={inputRef}
        type="file"
        accept={ACCEPT}
        capture="environment"
        onChange={handleChange}
        className="hidden"
        aria-hidden="true"
      />
      <button
        onClick={handleClick}
        disabled={disabled}
        className="w-12 h-12 flex-shrink-0 flex items-center justify-center border border-ink/10 text-ink/30 hover:text-ink/60 hover:border-ink/20 active:text-ink/80 disabled:opacity-20 disabled:hover:text-ink/30 disabled:hover:border-ink/10 transition-all"
        aria-label="Attach media"
      >
        <Paperclip className="w-5 h-5" />
      </button>
    </>
  );
}
