'use client';

import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import type { Components } from 'react-markdown';

interface MarkdownContentProps {
  content: string;
}

const components: Components = {
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
  // 외부 이미지 URL 차단 (보안)
  img: () => null,
};

export default function MarkdownContent({ content }: MarkdownContentProps) {
  return (
    <div className="font-mono text-sm text-ink leading-relaxed break-words">
      <ReactMarkdown remarkPlugins={[remarkGfm]} components={components}>
        {content}
      </ReactMarkdown>
    </div>
  );
}
