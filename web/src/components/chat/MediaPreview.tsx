'use client';

import { useState, useEffect, useCallback } from 'react';
import { motion } from 'framer-motion';
import { X, Send, AlertTriangle } from 'lucide-react';
import { getMediaType, validateFileSize } from '@/lib/media/thumbnail';

interface MediaPreviewProps {
  file: File;
  onConfirm: (file: File) => void;
  onCancel: () => void;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
}

export default function MediaPreview({ file, onConfirm, onCancel }: MediaPreviewProps) {
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const mediaType = getMediaType(file.type);
  const sizeCheck = validateFileSize(file);

  useEffect(() => {
    const url = URL.createObjectURL(file);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [file]);

  const handleConfirm = useCallback(() => {
    if (sizeCheck.valid) onConfirm(file);
  }, [file, onConfirm, sizeCheck.valid]);

  // ESC로 취소
  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onCancel();
      if (e.key === 'Enter' && sizeCheck.valid) handleConfirm();
    };
    document.addEventListener('keydown', handleKey);
    return () => document.removeEventListener('keydown', handleKey);
  }, [onCancel, handleConfirm, sizeCheck.valid]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 20 }}
      className="border-t border-ink/5 bg-void-black/95 backdrop-blur-md px-3 sm:px-4 py-3"
    >
      <div className="flex items-end gap-3">
        {/* 미리보기 */}
        <div className="relative flex-shrink-0 w-20 h-20 rounded-sm overflow-hidden border border-ink/10">
          {previewUrl && mediaType === 'image' && (
            <img
              src={previewUrl}
              alt="Preview"
              className="w-full h-full object-cover"
            />
          )}
          {previewUrl && mediaType === 'video' && (
            <video
              src={previewUrl}
              className="w-full h-full object-cover"
              muted
              playsInline
            />
          )}
        </div>

        {/* 파일 정보 */}
        <div className="flex-1 min-w-0">
          <p className="font-mono text-xs text-ink/60 truncate">
            {file.name}
          </p>
          <p className="font-mono text-[10px] text-ink/30 mt-0.5">
            {formatFileSize(file.size)}
          </p>

          {!sizeCheck.valid && (
            <div className="flex items-center gap-1 mt-1 text-red-400/80">
              <AlertTriangle className="w-3 h-3" />
              <span className="font-mono text-[10px]">
                MAX {formatFileSize(sizeCheck.maxSize)}
              </span>
            </div>
          )}
        </div>

        {/* 버튼 */}
        <div className="flex gap-2 flex-shrink-0">
          <button
            onClick={onCancel}
            className="w-10 h-10 flex items-center justify-center border border-ink/10 text-ink/40 hover:text-ink/70 transition-colors"
            aria-label="Cancel"
          >
            <X className="w-4 h-4" />
          </button>
          <button
            onClick={handleConfirm}
            disabled={!sizeCheck.valid}
            className="w-10 h-10 flex items-center justify-center border border-signal-green/30 text-signal-green hover:bg-signal-green hover:text-void-black disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-signal-green transition-all"
            aria-label="Send"
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>
    </motion.div>
  );
}
