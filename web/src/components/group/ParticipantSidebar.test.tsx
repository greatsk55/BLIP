import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';

vi.mock('next-intl', () => ({
  useTranslations: () => (key: string, params?: any) => {
    if (params?.name) return `${key}:${params.name}`;
    return key;
  },
}));

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
  },
  AnimatePresence: ({ children }: any) => <>{children}</>,
}));

import ParticipantSidebar from './ParticipantSidebar';

const participants = [
  { userId: 'u1', username: 'Agent-Fox', isAdmin: true },
  { userId: 'u2', username: 'Agent-Wolf', isAdmin: false },
  { userId: 'u3', username: 'Agent-Bear', isAdmin: false },
];

describe('ParticipantSidebar', () => {
  const defaultProps = {
    isOpen: true,
    participants,
    myId: 'u1',
    isAdmin: true,
    onClose: vi.fn(),
    onKick: vi.fn(),
    onBan: vi.fn(),
  };

  it('참여자 목록을 표시한다', () => {
    render(<ParticipantSidebar {...defaultProps} />);
    expect(screen.getByText(/Agent-Fox/)).toBeInTheDocument();
    expect(screen.getByText(/Agent-Wolf/)).toBeInTheDocument();
    expect(screen.getByText(/Agent-Bear/)).toBeInTheDocument();
  });

  it('참여자 수를 표시한다', () => {
    render(<ParticipantSidebar {...defaultProps} />);
    expect(screen.getByText(/sidebar\.title/)).toBeInTheDocument();
    expect(screen.getByText(/\(3\)/)).toBeInTheDocument();
  });

  it('자신에게 (you) 표시', () => {
    render(<ParticipantSidebar {...defaultProps} />);
    expect(screen.getByText('(you)')).toBeInTheDocument();
  });

  it('isOpen=false일 때 렌더링하지 않는다', () => {
    render(<ParticipantSidebar {...defaultProps} isOpen={false} />);
    expect(screen.queryByText(/Agent-Fox/)).not.toBeInTheDocument();
  });
});
