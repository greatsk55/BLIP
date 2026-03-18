import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';

// jsdom에 scrollIntoView가 없으므로 모킹
Element.prototype.scrollIntoView = vi.fn();

// Mock all heavy dependencies
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), back: vi.fn() }),
}));

vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
}));

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    p: ({ children, ...props }: any) => <p {...props}>{children}</p>,
    button: ({ children, ...props }: any) => <button {...props}>{children}</button>,
  },
  AnimatePresence: ({ children }: any) => <>{children}</>,
}));

vi.mock('@/hooks/useGroupChat', () => ({
  useGroupChat: () => ({
    messages: [],
    participants: [
      { userId: 'user-1', username: 'Agent-Fox', isAdmin: true },
      { userId: 'user-2', username: 'Agent-Wolf', isAdmin: false },
    ],
    myId: 'user-1',
    myUsername: 'Agent-Fox',
    status: 'active',
    sendMessage: vi.fn(),
    disconnect: vi.fn(),
    kickUser: vi.fn(),
    channel: null,
  }),
}));

vi.mock('@/hooks/useNotification', () => ({
  useNotification: () => ({ notifyMessage: vi.fn() }),
}));

vi.mock('@/hooks/useVisualViewport', () => ({
  useVisualViewport: vi.fn(),
}));

vi.mock('@/lib/crypto', () => ({
  deriveKeysFromPassword: vi.fn(),
  hashAuthKey: vi.fn(),
}));

vi.mock('@/lib/group/actions', () => ({
  updateGroupParticipantCount: vi.fn(),
  destroyGroupRoom: vi.fn(),
  toggleGroupLock: vi.fn(),
  banUserFromGroup: vi.fn(),
}));

import GroupChatRoom from './GroupChatRoom';

describe('GroupChatRoom', () => {
  const defaultProps = {
    roomId: 'test-room',
    password: 'TEST-PASS-1234',
    isAdmin: true,
    adminToken: 'ADMIN-TOKEN',
    title: 'Test Group',
  };

  it('렌더링된다', () => {
    render(<GroupChatRoom {...defaultProps} />);
    expect(screen.getByText(/E2E ENCRYPTION ACTIVE/)).toBeInTheDocument();
  });

  it('사용자 이름을 SystemMessage로 표시한다', () => {
    render(<GroupChatRoom {...defaultProps} />);
    expect(screen.getByText(/YOU ARE Agent-Fox/)).toBeInTheDocument();
  });
});
