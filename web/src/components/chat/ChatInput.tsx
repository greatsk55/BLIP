'use client';

import { useState, useCallback, useRef, type KeyboardEvent } from 'react';
import { Send } from 'lucide-react';
import { AnimatePresence } from 'framer-motion';
import MediaAttachButton from './MediaAttachButton';
import MediaPreview from './MediaPreview';

interface ChatInputProps {
  onSend: (message: string) => void;
  onSendFile?: (file: File) => void;
  disabled?: boolean;
  mediaDisabled?: boolean;
}

export default function ChatInput({
  onSend,
  onSendFile,
  disabled = false,
  mediaDisabled = false,
}: ChatInputProps) {
  const [value, setValue] = useState('');
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const handleSend = useCallback(() => {
    if (!value.trim() || disabled) return;
    onSend(value.trim());
    setValue('');
    if (textareaRef.current) {
      textareaRef.current.style.height = 'auto';
    }
  }, [value, onSend, disabled]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend]
  );

  const handleInput = useCallback(() => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = 'auto';
      textarea.style.height = `${Math.min(textarea.scrollHeight, 120)}px`;
    }
  }, []);

  const handleFileSelected = useCallback((file: File) => {
    setSelectedFile(file);
  }, []);

  const handleFileConfirm = useCallback(
    (file: File) => {
      onSendFile?.(file);
      setSelectedFile(null);
    },
    [onSendFile]
  );

  const handleFileCancel = useCallback(() => {
    setSelectedFile(null);
  }, []);

  return (
    <>
      {/* 미디어 미리보기 (파일 선택 시) */}
      <AnimatePresence>
        {selectedFile && (
          <MediaPreview
            file={selectedFile}
            onConfirm={handleFileConfirm}
            onCancel={handleFileCancel}
          />
        )}
      </AnimatePresence>

      <div className="border-t border-ink/5 bg-void-black/80 backdrop-blur-md px-3 sm:px-4 py-2 sm:py-3 pb-[max(0.5rem,env(safe-area-inset-bottom))]">
        <div className="flex items-end gap-2 sm:gap-3">
          {/* 미디어 첨부 버튼 */}
          {onSendFile && (
            <MediaAttachButton
              onFileSelected={handleFileSelected}
              disabled={disabled || mediaDisabled}
            />
          )}

          <textarea
            ref={textareaRef}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={handleKeyDown}
            onInput={handleInput}
            placeholder="TYPE_MESSAGE..."
            disabled={disabled}
            rows={1}
            enterKeyHint="send"
            autoComplete="off"
            autoCorrect="off"
            className="flex-1 bg-ink/3 border border-ink/10 focus:border-signal-green/30 text-ink/90 font-sans text-[16px] sm:text-sm placeholder:text-ghost-grey/30 placeholder:font-mono rounded-none px-3 sm:px-4 py-3 resize-none min-h-[44px] max-h-[120px] outline-none transition-colors"
          />
          <button
            onClick={handleSend}
            disabled={!value.trim() || disabled}
            className="w-12 h-12 shrink-0 flex items-center justify-center border border-signal-green/30 bg-transparent text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black disabled:opacity-20 disabled:border-ink/5 disabled:hover:bg-transparent disabled:hover:text-signal-green transition-all"
            aria-label="Send message"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </>
  );
}
