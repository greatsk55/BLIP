import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import PasswordEntry from './PasswordEntry';

// next-intl mock
vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => {
    const map: Record<string, string> = {
      'join.title': 'ENTER ACCESS KEY',
      'join.connect': 'CONNECT',
    };
    return map[key] ?? key;
  },
}));

// framer-motion mock (테스트에서 애니메이션 불필요)
vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    p: ({ children, ...props }: any) => <p {...props}>{children}</p>,
    button: ({ children, whileHover, whileTap, ...props }: any) => (
      <button {...props}>{children}</button>
    ),
  },
}));

describe('PasswordEntry', () => {
  it('입력 시 자동 대문자 변환', async () => {
    render(<PasswordEntry onSubmit={vi.fn()} />);
    const input = screen.getByPlaceholderText('XXXX-XXXX');

    fireEvent.change(input, { target: { value: 'abcd' } });
    expect(input).toHaveValue('ABCD');
  });

  it('4자 입력 후 자동 하이픈 삽입', async () => {
    render(<PasswordEntry onSubmit={vi.fn()} />);
    const input = screen.getByPlaceholderText('XXXX-XXXX');

    fireEvent.change(input, { target: { value: 'ABCDE' } });
    expect(input).toHaveValue('ABCD-E');
  });

  it('특수문자/공백 입력 차단', async () => {
    render(<PasswordEntry onSubmit={vi.fn()} />);
    const input = screen.getByPlaceholderText('XXXX-XXXX');

    fireEvent.change(input, { target: { value: 'AB!@#CD' } });
    expect(input).toHaveValue('ABCD');
  });

  it('Enter 키로 제출한다', async () => {
    const onSubmit = vi.fn();
    render(<PasswordEntry onSubmit={onSubmit} />);
    const input = screen.getByPlaceholderText('XXXX-XXXX');

    fireEvent.change(input, { target: { value: 'ABCD1234' } });
    fireEvent.keyDown(input, { key: 'Enter' });

    expect(onSubmit).toHaveBeenCalledWith('ABCD-1234');
  });

  it('빈 입력으로는 제출할 수 없다', async () => {
    const onSubmit = vi.fn();
    render(<PasswordEntry onSubmit={onSubmit} />);

    const button = screen.getByText('CONNECT');
    expect(button).toBeDisabled();

    fireEvent.click(button);
    expect(onSubmit).not.toHaveBeenCalled();
  });

  it('에러 메시지를 표시한다', () => {
    render(<PasswordEntry onSubmit={vi.fn()} error="INVALID_KEY" />);
    expect(screen.getByText('INVALID_KEY')).toBeInTheDocument();
  });

  it('loading 상태에서는 "..."을 표시한다', () => {
    render(<PasswordEntry onSubmit={vi.fn()} loading />);
    expect(screen.getByText('...')).toBeInTheDocument();
  });
});
