'use client';

import { Download } from 'lucide-react';
import type { DecryptedMessage } from '@/types/chat';
import TransferProgress from './TransferProgress';

interface FileBubbleProps {
  message: DecryptedMessage;
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes}B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)}KB`;
  if (bytes < 1024 * 1024 * 1024) return `${(bytes / (1024 * 1024)).toFixed(1)}MB`;
  return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)}GB`;
}

function getFileIcon(fileName: string): string {
  const ext = fileName.split('.').pop()?.toLowerCase() ?? '';
  switch (ext) {
    case 'pdf': return '📄';
    case 'doc': case 'docx': return '📝';
    case 'xls': case 'xlsx': return '📊';
    case 'ppt': case 'pptx': return '📑';
    case 'zip': case 'rar': case '7z': case 'tar': case 'gz': return '🗜️';
    case 'mp3': case 'wav': case 'flac': case 'aac': case 'ogg': return '🎵';
    case 'txt': case 'md': case 'rtf': return '📃';
    case 'html': case 'css': case 'js': case 'ts': case 'json': case 'xml': return '💻';
    case 'py': case 'java': case 'cpp': case 'c': case 'rs': case 'go': return '💻';
    case 'apk': case 'ipa': return '📱';
    case 'exe': case 'msi': case 'dmg': case 'app': return '⚙️';
    default: return '📎';
  }
}

export default function FileBubble({ message }: FileBubbleProps) {
  const isTransferring = message.transferProgress !== undefined && message.transferProgress < 1;
  const meta = message.mediaMetadata;
  const fileName = meta?.fileName ?? 'unknown';

  const handleDownload = () => {
    if (!message.mediaUrl) return;
    const a = document.createElement('a');
    a.href = message.mediaUrl;
    a.download = fileName;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
  };

  return (
    <div className="relative min-w-[200px]">
      <div className="flex items-center gap-3">
        <span className="text-2xl flex-shrink-0">{getFileIcon(fileName)}</span>
        <div className="flex-1 min-w-0">
          <p className="font-mono text-xs text-ink/80 truncate">{fileName}</p>
          {meta?.size && (
            <p className="font-mono text-[10px] text-ink/30 mt-0.5">
              {formatFileSize(meta.size)}
            </p>
          )}
        </div>
        {message.mediaUrl && !isTransferring && (
          <button
            onClick={handleDownload}
            className="flex-shrink-0 w-8 h-8 flex items-center justify-center border border-signal-green/30 text-signal-green hover:bg-signal-green hover:text-void-black transition-all rounded-sm"
            aria-label="Download file"
          >
            <Download className="w-4 h-4" />
          </button>
        )}
      </div>

      {isTransferring && (
        <div className="mt-2">
          <TransferProgress progress={message.transferProgress!} />
        </div>
      )}
    </div>
  );
}
