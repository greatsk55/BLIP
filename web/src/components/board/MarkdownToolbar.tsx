'use client';

import { useCallback, type RefObject } from 'react';
import { Bold, Italic, Code, Quote, List, ListOrdered, Link2, Minus } from 'lucide-react';

interface MarkdownToolbarProps {
  textareaRef: RefObject<HTMLTextAreaElement | null>;
  value: string;
  onChange: (value: string) => void;
}

const tools = [
  { icon: Bold, before: '**', after: '**', label: 'Bold' },
  { icon: Italic, before: '_', after: '_', label: 'Italic' },
  { icon: Code, before: '`', after: '`', label: 'Code' },
  { icon: Quote, before: '> ', after: '', label: 'Quote' },
  { icon: List, before: '- ', after: '', label: 'List' },
  { icon: ListOrdered, before: '1. ', after: '', label: 'Ordered list' },
  { icon: Link2, before: '[', after: '](url)', label: 'Link' },
  { icon: Minus, before: '\n---\n', after: '', label: 'Divider' },
] as const;

export default function MarkdownToolbar({ textareaRef, value, onChange }: MarkdownToolbarProps) {
  const handleTool = useCallback(
    (before: string, after: string) => {
      const textarea = textareaRef.current;
      if (!textarea) return;

      const start = textarea.selectionStart;
      const end = textarea.selectionEnd;
      const selected = value.substring(start, end);

      const newValue =
        value.substring(0, start) + before + selected + after + value.substring(end);
      onChange(newValue);

      requestAnimationFrame(() => {
        textarea.focus();
        const newPos = start + before.length + selected.length;
        textarea.setSelectionRange(newPos, newPos);
      });
    },
    [textareaRef, value, onChange]
  );

  return (
    <div className="flex items-center gap-0.5 overflow-x-auto py-1 px-1">
      {tools.map((tool) => (
        <button
          key={tool.label}
          onClick={() => handleTool(tool.before, tool.after)}
          className="w-7 h-7 flex-shrink-0 flex items-center justify-center text-ghost-grey/70 hover:text-ink/70 active:text-signal-green transition-colors"
          aria-label={tool.label}
          type="button"
        >
          <tool.icon className="w-3.5 h-3.5" />
        </button>
      ))}
    </div>
  );
}
