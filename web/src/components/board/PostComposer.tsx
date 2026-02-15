'use client';

import { useState, useCallback, useRef, type KeyboardEvent } from 'react';
import { Send, ImagePlus, X } from 'lucide-react';
import { useTranslations } from 'next-intl';
import MarkdownToolbar from './MarkdownToolbar';
import { getMediaType, validateFileSize } from '@/lib/media/thumbnail';

const MAX_IMAGES = 4;

interface PostComposerProps {
  onSubmit: (content: string, images?: File[]) => Promise<{ error?: string }>;
}

export default function PostComposer({ onSubmit }: PostComposerProps) {
  const t = useTranslations('Board');
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleSubmit = useCallback(async () => {
    if ((!content.trim() && images.length === 0) || loading) return;

    setLoading(true);
    const result = await onSubmit(content, images.length > 0 ? images : undefined);
    setLoading(false);

    if (!result.error) {
      setContent('');
      previews.forEach((url) => URL.revokeObjectURL(url));
      setImages([]);
      setPreviews([]);
    }
  }, [content, images, loading, onSubmit, previews]);

  const handleKeyDown = useCallback(
    (e: KeyboardEvent<HTMLTextAreaElement>) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSubmit();
      }
    },
    [handleSubmit]
  );

  const handleImageSelect = useCallback(() => {
    if (images.length >= MAX_IMAGES) return;
    fileInputRef.current?.click();
  }, [images.length]);

  const handleFileChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = Array.from(e.target.files ?? []);
      if (files.length === 0) return;

      const remaining = MAX_IMAGES - images.length;
      const toAdd = files.slice(0, remaining);

      const validFiles: File[] = [];
      const newPreviews: string[] = [];

      for (const file of toAdd) {
        const mediaType = getMediaType(file.type);
        if (mediaType !== 'image') continue;

        const { valid } = validateFileSize(file);
        if (!valid) continue;

        validFiles.push(file);
        newPreviews.push(URL.createObjectURL(file));
      }

      if (validFiles.length > 0) {
        setImages((prev) => [...prev, ...validFiles]);
        setPreviews((prev) => [...prev, ...newPreviews]);
      }

      // reset input
      e.target.value = '';
    },
    [images.length]
  );

  const removeImage = useCallback(
    (index: number) => {
      URL.revokeObjectURL(previews[index]);
      setImages((prev) => prev.filter((_, i) => i !== index));
      setPreviews((prev) => prev.filter((_, i) => i !== index));
    },
    [previews]
  );

  return (
    <div className="flex-shrink-0 border-t border-ink/10 bg-void-black pb-[env(safe-area-inset-bottom)]">
      {/* 마크다운 툴바 */}
      <MarkdownToolbar textareaRef={textareaRef} value={content} onChange={setContent} />

      {/* 이미지 미리보기 */}
      {previews.length > 0 && (
        <div className="flex gap-2 px-4 py-2 overflow-x-auto">
          {previews.map((url, i) => (
            <div key={url} className="relative flex-shrink-0 w-16 h-16">
              <img
                src={url}
                alt=""
                className="w-full h-full object-cover rounded-sm"
                draggable={false}
              />
              <button
                onClick={() => removeImage(i)}
                className="absolute -top-1.5 -right-1.5 w-5 h-5 flex items-center justify-center bg-void-black border border-ink/20 rounded-full text-ink/60 hover:text-glitch-red transition-colors"
                type="button"
              >
                <X className="w-3 h-3" />
              </button>
            </div>
          ))}
        </div>
      )}

      {/* 입력 영역 */}
      <div className="flex items-end gap-2 px-4 py-3">
        <button
          onClick={handleImageSelect}
          disabled={images.length >= MAX_IMAGES}
          className="min-h-[42px] px-2 py-2.5 text-ghost-grey/40 hover:text-signal-green disabled:opacity-20 transition-colors"
          aria-label={t('post.attachImage')}
          type="button"
        >
          <ImagePlus className="w-4 h-4" />
        </button>

        <textarea
          ref={textareaRef}
          value={content}
          onChange={(e) => setContent(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={t('post.placeholder')}
          rows={1}
          className="flex-1 bg-transparent border border-ink/10 focus:border-signal-green/30 text-ink font-mono text-sm px-3 py-2.5 outline-none transition-colors resize-none placeholder:text-ghost-grey/20 min-h-[42px] max-h-[120px]"
          style={{ fieldSizing: 'content' } as React.CSSProperties}
          enterKeyHint="send"
        />
        <button
          onClick={handleSubmit}
          disabled={(!content.trim() && images.length === 0) || loading}
          className="min-h-[42px] px-4 py-2.5 border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black active:bg-signal-green active:text-void-black transition-all duration-200 disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-signal-green"
          aria-label={t('post.submit')}
        >
          <Send className="w-4 h-4" />
        </button>
      </div>

      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        onChange={handleFileChange}
        className="hidden"
      />
    </div>
  );
}
