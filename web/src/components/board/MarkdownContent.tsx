'use client';

import { useState, useMemo, useCallback } from 'react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import type { Components } from 'react-markdown';
import type { DecryptedPostImage } from '@/types/board';
import ImageViewer from '@/components/chat/ImageViewer';

interface MarkdownContentProps {
  content: string;
  /** 인라인 이미지용: ![](img:0) → images[0] */
  images?: DecryptedPostImage[];
}

/** img:N 스킴 매칭 */
const IMG_SCHEME_RE = /^img:(\d+)$/;

export default function MarkdownContent({ content, images }: MarkdownContentProps) {
  const [viewerSrc, setViewerSrc] = useState<string | null>(null);

  const handleImageClick = useCallback((src: string) => {
    setViewerSrc(src);
  }, []);

  const components = useMemo<Components>(() => ({
    a: ({ href, children }) => (
      <a
        href={href}
        target="_blank"
        rel="noopener noreferrer"
        className="text-signal-green underline underline-offset-2 hover:text-signal-green/80 transition-colors"
      >
        {children}
      </a>
    ),
    code: ({ className, children }) => {
      const isBlock = !!className;
      if (!isBlock) {
        return (
          <code className="bg-ink/5 text-signal-green/80 px-1 py-0.5 text-[13px] font-mono rounded-sm">
            {children}
          </code>
        );
      }
      return (
        <code className="block bg-ink/5 border border-ink/10 p-3 text-xs font-mono overflow-x-auto my-2 rounded-sm">
          {children}
        </code>
      );
    },
    pre: ({ children }) => <pre className="my-2">{children}</pre>,
    strong: ({ children }) => (
      <strong className="font-bold text-ink">{children}</strong>
    ),
    em: ({ children }) => (
      <em className="italic text-ink/80">{children}</em>
    ),
    blockquote: ({ children }) => (
      <blockquote className="border-l-2 border-signal-green/30 pl-3 my-2 text-ink/60 italic">
        {children}
      </blockquote>
    ),
    ul: ({ children }) => (
      <ul className="list-disc list-inside my-1 space-y-0.5">{children}</ul>
    ),
    ol: ({ children }) => (
      <ol className="list-decimal list-inside my-1 space-y-0.5">{children}</ol>
    ),
    hr: () => <hr className="border-ink/10 my-3" />,
    table: ({ children }) => (
      <div className="overflow-x-auto my-2">
        <table className="w-full border border-ink/10 text-xs font-mono">
          {children}
        </table>
      </div>
    ),
    th: ({ children }) => (
      <th className="border border-ink/10 px-2 py-1 bg-ink/5 text-left font-medium">
        {children}
      </th>
    ),
    td: ({ children }) => (
      <td className="border border-ink/10 px-2 py-1">{children}</td>
    ),
    h1: ({ children }) => (
      <h1 className="text-lg font-bold text-ink mt-3 mb-1">{children}</h1>
    ),
    h2: ({ children }) => (
      <h2 className="text-base font-bold text-ink mt-3 mb-1">{children}</h2>
    ),
    h3: ({ children }) => (
      <h3 className="text-sm font-bold text-ink mt-2 mb-1">{children}</h3>
    ),
    p: ({ children }) => <p className="my-1">{children}</p>,
    // img:N 스킴 → 인라인 이미지, 그 외 외부 URL 차단
    img: ({ src, alt }) => {
      if (!src || typeof src !== 'string') return null;
      const match = IMG_SCHEME_RE.exec(src);
      if (!match) return null; // 외부 URL 차단

      const index = parseInt(match[1], 10);
      const image = images?.[index];
      if (!image) return null;

      return (
        <span className="block my-3">
          <button
            type="button"
            onClick={() => handleImageClick(image.objectUrl)}
            className="block max-w-full cursor-zoom-in"
          >
            <img
              src={image.objectUrl}
              alt={alt ?? ''}
              className="max-w-full h-auto rounded-sm border border-ink/10"
              style={{ objectFit: 'contain' }}
              draggable={false}
            />
          </button>
        </span>
      );
    },
  }), [images, handleImageClick]);

  return (
    <>
      <div className="font-mono text-sm text-ink leading-relaxed wrap-break-word">
        <ReactMarkdown
          remarkPlugins={[remarkGfm]}
          components={components}
          urlTransform={(url) => {
            // img:N 스킴은 인라인 이미지용 → sanitization 우회
            if (/^img:\d+$/.test(url)) return url;
            // 그 외는 기본 sanitization (http/https만 허용)
            return url;
          }}
        >
          {content}
        </ReactMarkdown>
      </div>
      <ImageViewer src={viewerSrc} onClose={() => setViewerSrc(null)} />
    </>
  );
}
