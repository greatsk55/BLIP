'use client';

import { motion } from 'framer-motion';
import type { DecryptedMessage } from '@/types/chat';
import MediaBubble from './MediaBubble';

interface MessageBubbleProps {
  message: DecryptedMessage;
  onImageClick?: (src: string) => void;
}

export default function MessageBubble({ message, onImageClick }: MessageBubbleProps) {
  const time = new Date(message.timestamp).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });

  if (message.senderId === 'system') {
    return null;
  }

  const isMedia = message.type === 'image' || message.type === 'video';

  return (
    <motion.div
      initial={{ opacity: 0, x: message.isMine ? 20 : -20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.15 }}
      className={`flex ${message.isMine ? 'justify-end' : 'justify-start'} mb-2`}
    >
      <div
        className={`max-w-[80%] md:max-w-[60%] ${isMedia ? 'p-1.5' : 'px-4 py-3'} ${
          message.isMine
            ? 'bg-signal-green/10 border border-signal-green/20'
            : 'bg-ink/[0.04] border border-ink/5'
        } rounded-sm`}
      >
        {!message.isMine && (
          <p className={`font-mono text-xs text-signal-green/60 mb-1 uppercase tracking-wider ${isMedia ? 'px-2 pt-1' : ''}`}>
            {message.senderName}
          </p>
        )}

        {isMedia ? (
          <MediaBubble message={message} onImageClick={onImageClick} />
        ) : (
          <p className="font-sans text-sm text-ink/90 leading-relaxed wrap-break-word whitespace-pre-wrap">
            {message.content}
          </p>
        )}

        <p className={`font-mono text-[10px] text-ink/20 mt-1 text-right ${isMedia ? 'px-2 pb-1' : ''}`}>
          {time}
        </p>
      </div>
    </motion.div>
  );
}
