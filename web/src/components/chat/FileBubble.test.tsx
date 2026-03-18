import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import FileBubble from './FileBubble';
import type { DecryptedMessage } from '@/types/chat';

function makeFileMessage(overrides: Partial<DecryptedMessage> = {}): DecryptedMessage {
  return {
    id: 'msg-1',
    senderId: 'user-1',
    senderName: 'Alice',
    content: '',
    timestamp: Date.now(),
    isMine: false,
    type: 'file',
    mediaUrl: 'blob:http://localhost/abc',
    mediaMetadata: {
      fileName: 'report.pdf',
      mimeType: 'application/pdf',
      size: 1024 * 1024 * 2.5, // 2.5MB
    },
    ...overrides,
  };
}

describe('FileBubble', () => {
  it('파일 이름을 표시한다', () => {
    render(<FileBubble message={makeFileMessage()} />);
    expect(screen.getByText('report.pdf')).toBeInTheDocument();
  });

  it('파일 크기를 포맷하여 표시한다', () => {
    render(<FileBubble message={makeFileMessage()} />);
    expect(screen.getByText('2.5MB')).toBeInTheDocument();
  });

  it('PDF 아이콘(📄)을 표시한다', () => {
    render(<FileBubble message={makeFileMessage()} />);
    expect(screen.getByText('📄')).toBeInTheDocument();
  });

  it('ZIP 파일은 🗜️ 아이콘', () => {
    render(<FileBubble message={makeFileMessage({
      mediaMetadata: { fileName: 'archive.zip', mimeType: 'application/zip', size: 500 },
    })} />);
    expect(screen.getByText('🗜️')).toBeInTheDocument();
  });

  it('다운로드 버튼이 있다', () => {
    render(<FileBubble message={makeFileMessage()} />);
    expect(screen.getByLabelText('Download file')).toBeInTheDocument();
  });

  it('mediaUrl이 없으면 다운로드 버튼 없음', () => {
    render(<FileBubble message={makeFileMessage({ mediaUrl: undefined })} />);
    expect(screen.queryByLabelText('Download file')).not.toBeInTheDocument();
  });

  it('전송 중이면 다운로드 버튼 숨김', () => {
    render(<FileBubble message={makeFileMessage({ transferProgress: 0.5 })} />);
    expect(screen.queryByLabelText('Download file')).not.toBeInTheDocument();
  });
});
