'use client';

import { useState, useCallback, useRef } from 'react';
import { ImageIcon, Send, X, Play } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { getMediaType, validateFileSize } from '@/lib/media/thumbnail';

const MAX_COMMENT_MEDIA = 2;

interface CommentComposerProps {
  postId: string;
  onSubmit: (postId: string, content: string, images?: File[]) => Promise<{ error?: string }>;
}

export default function CommentComposer({ postId, onSubmit }: CommentComposerProps) {
  const t = useTranslations('Board');
  const [content, setContent] = useState('');
  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  const canSubmit = (content.trim() || images.length > 0) && !loading;

  const handleSubmit = useCallback(async () => {
    if (!canSubmit) return;
    setLoading(true);
    const result = await onSubmit(postId, content.trim(), images.length > 0 ? images : undefined);
    setLoading(false);

    if (!result.error) {
      setContent('');
      setImages([]);
      previews.forEach((url) => URL.revokeObjectURL(url));
      setPreviews([]);
    }
  }, [canSubmit, onSubmit, postId, content, images, previews]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        handleSubmit();
      }
    },
    [handleSubmit]
  );

  const handleFileSelect = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = Array.from(e.target.files ?? []);
      if (!files.length) return;

      const remaining = MAX_COMMENT_MEDIA - images.length;
      const toAdd = files.slice(0, remaining);

      const validFiles = toAdd.filter((f) => {
        const mediaType = getMediaType(f.type);
        if (!mediaType) return false;
        const sizeCheck = validateFileSize(f);
        return sizeCheck.valid;
      });
      if (!validFiles.length) return;

      setImages((prev) => [...prev, ...validFiles]);
      const newPreviews = validFiles.map((f) => URL.createObjectURL(f));
      setPreviews((prev) => [...prev, ...newPreviews]);

      // 입력 초기화
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
    <div className="border-t border-ink/10 bg-void-black">
      {/* 이미지 미리보기 */}
      {previews.length > 0 && (
        <div className="flex gap-2 px-4 pt-3">
          {previews.map((url, i) => {
            const isVideo = images[i]?.type.startsWith('video/');
            return (
              <div key={url} className="relative w-14 h-14 border border-ink/10 overflow-hidden group">
                {isVideo ? (
                  <div className="w-full h-full bg-ink/5 flex items-center justify-center">
                    <Play className="w-4 h-4 text-ghost-grey/60" />
                  </div>
                ) : (
                  /* eslint-disable-next-line @next/next/no-img-element */
                  <img src={url} alt="" className="w-full h-full object-cover" />
                )}
                <button
                  onClick={() => removeImage(i)}
                  className="absolute top-0 right-0 p-0.5 bg-void-black/80 text-ghost-grey/60 hover:text-glitch-red"
                >
                  <X className="w-3 h-3" />
                </button>
              </div>
            );
          })}
        </div>
      )}

      {/* 입력 영역 */}
      <div className="flex items-end gap-2 px-4 py-3">
        {/* 이미지 첨부 */}
        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={images.length >= MAX_COMMENT_MEDIA || loading}
          className="p-2 text-ghost-grey/40 hover:text-ghost-grey/70 transition-colors disabled:opacity-30"
          aria-label={t('comment.attachImage')}
        >
          <ImageIcon className="w-4 h-4" />
        </button>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/*,video/*"
          multiple
          onChange={handleFileSelect}
          className="hidden"
        />

        {/* 텍스트 입력 */}
        <textarea
          ref={textareaRef}
          value={content}
          onChange={(e) => setContent(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={t('comment.placeholder')}
          rows={1}
          className="flex-1 bg-transparent font-mono text-xs text-ink placeholder:text-ghost-grey/30 resize-none outline-none py-2 max-h-20 overflow-y-auto"
          style={{ lineHeight: '1.5' }}
          disabled={loading}
        />

        {/* 전송 */}
        <button
          onClick={handleSubmit}
          disabled={!canSubmit}
          className="p-2 text-signal-green hover:text-signal-green/80 transition-colors disabled:text-ghost-grey/20 disabled:cursor-not-allowed"
          aria-label={t('comment.submit')}
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
