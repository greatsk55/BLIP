'use client';

import { useRef, useCallback } from 'react';
import { Paperclip } from 'lucide-react';

interface MediaAttachButtonProps {
  onFileSelected: (file: File) => void;
  disabled?: boolean;
}

// Accept all file types (images, videos, and general files)
const ACCEPT = '*/*';

export default function MediaAttachButton({ onFileSelected, disabled }: MediaAttachButtonProps) {
  const inputRef = useRef<HTMLInputElement>(null);

  const handleClick = useCallback(() => {
    inputRef.current?.click();
  }, []);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const file = e.target.files?.[0];
      if (!file) return;

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
        onChange={handleChange}
        className="hidden"
        aria-hidden="true"
      />
      <button
        onClick={handleClick}
        disabled={disabled}
        className="w-12 h-12 flex-shrink-0 flex items-center justify-center border border-ink/10 text-ink/40 hover:text-ink/60 hover:border-ink/20 active:text-ink/80 disabled:opacity-50 disabled:hover:text-ink/40 disabled:hover:border-ink/10 transition-all"
        aria-label="Attach media"
      >
        <Paperclip className="w-5 h-5" />
      </button>
    </>
  );
}
