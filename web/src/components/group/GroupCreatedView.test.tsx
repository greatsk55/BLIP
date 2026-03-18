import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';

vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => key,
}));

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    p: ({ children, ...props }: any) => <p {...props}>{children}</p>,
    button: ({ children, onClick, ...props }: any) => <button onClick={onClick} {...props}>{children}</button>,
  },
}));

vi.mock('@/components/shared/CopyButton', () => ({
  default: ({ text }: { text: string }) => <button aria-label={`Copy ${text}`}>Copy</button>,
}));

import GroupCreatedView from './GroupCreatedView';

describe('GroupCreatedView', () => {
  const defaultProps = {
    roomId: 'test-room-id',
    password: 'ABCD-EFGH-IJKL',
    adminToken: 'MNOP-QRST-UVWX',
    title: 'My Test Group',
    onEnter: vi.fn(),
  };

  it('비밀번호를 표시한다', () => {
    render(<GroupCreatedView {...defaultProps} />);
    expect(screen.getByText('ABCD-EFGH-IJKL')).toBeInTheDocument();
  });

  it('관리자 토큰을 표시한다', () => {
    render(<GroupCreatedView {...defaultProps} />);
    expect(screen.getByText('MNOP-QRST-UVWX')).toBeInTheDocument();
  });

  it('그룹 제목을 표시한다', () => {
    render(<GroupCreatedView {...defaultProps} />);
    expect(screen.getByText('My Test Group')).toBeInTheDocument();
  });

  it('입장 버튼이 있다', () => {
    render(<GroupCreatedView {...defaultProps} />);
    expect(screen.getByText('created.enter')).toBeInTheDocument();
  });

  it('입장 버튼 클릭 시 onEnter 호출', () => {
    render(<GroupCreatedView {...defaultProps} />);
    screen.getByText('created.enter').click();
    expect(defaultProps.onEnter).toHaveBeenCalled();
  });
});
