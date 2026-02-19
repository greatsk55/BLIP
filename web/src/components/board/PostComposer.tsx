'use client';

import { useState, useCallback, useRef } from 'react';
import { ArrowLeft, Paperclip, ImageDown, X, Send, Play } from 'lucide-react';
import { useTranslations } from 'next-intl';
import MarkdownToolbar from './MarkdownToolbar';
import { ThemeToggle } from '@/components/ThemeToggle';
import { getMediaType, validateFileSize } from '@/lib/media/thumbnail';

const MAX_MEDIA = 4;

interface PostComposerProps {
  /** 편집 모드: 기존 게시글 데이터 전달 */
  editPost?: { id: string; title: string; content: string };
  onSubmit: (title: string, content: string, images?: File[]) => Promise<{ error?: string }>;
  onBack: () => void;
}

export default function PostComposer({ editPost, onSubmit, onBack }: PostComposerProps) {
  const t = useTranslations('Board');
  const isEditMode = !!editPost;
  const [title, setTitle] = useState(editPost?.title ?? '');
  const [content, setContent] = useState(editPost?.content ?? '');
  const [loading, setLoading] = useState(false);
  const [images, setImages] = useState<File[]>([]);
  const [previews, setPreviews] = useState<string[]>([]);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const canSubmit = (title.trim() || content.trim() || (!isEditMode && images.length > 0)) && !loading;

  const handleSubmit = useCallback(async () => {
    if (!canSubmit) return;

    setLoading(true);
    const result = await onSubmit(title, content, !isEditMode && images.length > 0 ? images : undefined);
    setLoading(false);

    if (!result.error) {
      if (!isEditMode) {
        setTitle('');
        setContent('');
        previews.forEach((url) => URL.revokeObjectURL(url));
        setImages([]);
        setPreviews([]);
      }
      onBack();
    }
  }, [canSubmit, title, content, images, isEditMode, onSubmit, previews, onBack]);

  const handleImageSelect = useCallback(() => {
    if (images.length >= MAX_MEDIA) return;
    fileInputRef.current?.click();
  }, [images.length]);

  const handleFileChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      const files = Array.from(e.target.files ?? []);
      if (files.length === 0) return;

      const remaining = MAX_MEDIA - images.length;
      const toAdd = files.slice(0, remaining);

      const validFiles: File[] = [];
      const newPreviews: string[] = [];

      for (const file of toAdd) {
        const mediaType = getMediaType(file.type);
        if (!mediaType) continue;

        const { valid } = validateFileSize(file);
        if (!valid) continue;

        validFiles.push(file);
        newPreviews.push(URL.createObjectURL(file));
      }

      if (validFiles.length > 0) {
        setImages((prev) => [...prev, ...validFiles]);
        setPreviews((prev) => [...prev, ...newPreviews]);
      }

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

  /** 커서 위치에 인라인 이미지 마크다운 삽입 */
  const insertImageInline = useCallback(
    (index: number) => {
      const ta = textareaRef.current;
      if (!ta) return;

      const tag = `![image](img:${index})`;
      const start = ta.selectionStart;
      const end = ta.selectionEnd;

      // 앞뒤로 줄바꿈 보장
      const before = content.slice(0, start);
      const after = content.slice(end);
      const prefix = before.length > 0 && !before.endsWith('\n') ? '\n' : '';
      const suffix = after.length > 0 && !after.startsWith('\n') ? '\n' : '';

      const newContent = before + prefix + tag + suffix + after;
      setContent(newContent);

      // 커서 위치 복원
      requestAnimationFrame(() => {
        const newPos = start + prefix.length + tag.length + suffix.length;
        ta.focus();
        ta.setSelectionRange(newPos, newPos);
      });
    },
    [content]
  );

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* 헤더 */}
      <div className="flex-shrink-0 flex items-center justify-between px-4 py-3 border-b border-ink/10 bg-void-black/90 backdrop-blur-sm">
        <div className="flex items-center gap-3">
          <button
            onClick={onBack}
            className="p-1 text-ghost-grey/60 hover:text-ink transition-colors"
            aria-label="Back"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <span className="font-mono text-xs text-ghost-grey/70 uppercase tracking-wider">
            {isEditMode ? t('post.editTitle') : t('post.compose')}
          </span>
        </div>

        <div className="flex items-center gap-2">
          <ThemeToggle />
          <button
            onClick={handleSubmit}
            disabled={!canSubmit}
            className="flex items-center gap-2 px-4 py-1.5 border border-signal-green text-signal-green hover:bg-signal-green hover:text-void-black transition-all duration-200 disabled:opacity-20 disabled:hover:bg-transparent disabled:hover:text-signal-green font-mono text-[10px] uppercase tracking-wider"
          >
            {loading ? (
              <span className="animate-pulse">{t('post.uploading')}</span>
            ) : (
              <>
                <Send className="w-3 h-3" />
                {isEditMode ? t('post.save') : t('post.submit')}
              </>
            )}
          </button>
        </div>
      </div>

      {/* 제목 입력 */}
      <div className="flex-shrink-0 px-4 py-3 border-b border-ink/10">
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder={t('post.titlePlaceholder')}
          maxLength={200}
          className="w-full bg-transparent text-ink font-mono text-base font-bold outline-none placeholder:text-ghost-grey/40"
        />
      </div>

      {/* 마크다운 툴바 */}
      <MarkdownToolbar textareaRef={textareaRef} value={content} onChange={setContent} />

      {/* 본문 입력 */}
      <div className="flex-1 overflow-y-auto px-4 py-4">
        <textarea
          ref={textareaRef}
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder={t('post.placeholder')}
          autoFocus
          className="w-full h-full min-h-[200px] bg-transparent text-ink font-mono text-sm leading-relaxed outline-none resize-none placeholder:text-ghost-grey/40"
        />
      </div>

      {/* 이미지 미리보기 + 인라인 삽입 (편집 모드에서는 숨김) */}
      {!isEditMode && previews.length > 0 && (
        <div className="flex-shrink-0 flex gap-2 px-4 py-3 border-t border-ink/10 overflow-x-auto">
          {previews.map((url, i) => {
            const isVideo = getMediaType(images[i]?.type ?? '') === 'video';
            return (
            <div key={url} className="relative flex-shrink-0 w-20 h-20 group">
              {isVideo ? (
                <div className="relative w-full h-full">
                  <video
                    src={url}
                    className="w-full h-full object-cover rounded-sm"
                    muted
                    playsInline
                    preload="metadata"
                  />
                  <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                    <Play className="w-6 h-6 text-white/80 drop-shadow-md" />
                  </div>
                </div>
              ) : (
                <img
                  src={url}
                  alt=""
                  className="w-full h-full object-cover rounded-sm"
                  draggable={false}
                />
              )}
              {/* 삭제 버튼 */}
              <button
                onClick={() => removeImage(i)}
                className="absolute -top-1.5 -right-1.5 w-5 h-5 flex items-center justify-center bg-void-black border border-ink/20 rounded-full text-ink/60 hover:text-glitch-red transition-colors z-10"
                type="button"
              >
                <X className="w-3 h-3" />
              </button>
              {/* 본문에 삽입 버튼 */}
              <button
                onClick={() => insertImageInline(i)}
                className="absolute bottom-0 left-0 right-0 flex items-center justify-center gap-1 py-1 bg-void-black/80 text-signal-green/80 hover:text-signal-green transition-colors"
                type="button"
                title={t('post.insertInline')}
              >
                <ImageDown className="w-3 h-3" />
                <span className="font-mono text-[8px] uppercase tracking-wider">Insert</span>
              </button>
            </div>
            );
          })}
        </div>
      )}

      {/* 하단 액션바 (편집 모드에서는 숨김) */}
      {!isEditMode && (
        <div className="flex-shrink-0 flex items-center gap-3 px-4 py-3 border-t border-ink/10 pb-[env(safe-area-inset-bottom)]">
          <button
            onClick={handleImageSelect}
            disabled={images.length >= MAX_MEDIA}
            className="flex items-center gap-2 px-3 py-1.5 text-ghost-grey/70 hover:text-signal-green disabled:opacity-20 transition-colors"
            aria-label={t('post.attachImage')}
            type="button"
          >
            <Paperclip className="w-4 h-4" />
            <span className="font-mono text-[10px] uppercase tracking-wider">
              {t('post.attachImage')}
            </span>
          </button>
          {images.length > 0 && (
            <span className="font-mono text-[9px] text-ghost-grey/60 uppercase tracking-wider">
              {images.length}/{MAX_MEDIA}
            </span>
          )}
        </div>
      )}

      {!isEditMode && (
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*,video/*"
          multiple
          onChange={handleFileChange}
          className="hidden"
        />
      )}
    </div>
  );
}
