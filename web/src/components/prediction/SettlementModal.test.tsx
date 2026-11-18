import type { ComponentProps, ReactNode } from 'react';
import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import SettlementModal from './SettlementModal';
import type { SettlementResult } from '@/types/prediction';

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: ComponentProps<'div'> & Record<string, unknown>) => <div {...props}>{children}</div>,
    span: ({ children, ...props }: ComponentProps<'span'> & Record<string, unknown>) => <span {...props}>{children}</span>,
    button: ({ children, whileHover, whileTap, ...props }: ComponentProps<'button'> & Record<string, unknown>) => (
      <button {...props}>{children}</button>
    ),
  },
  AnimatePresence: ({ children }: { children?: ReactNode }) => <>{children}</>,
}));

const winResult: SettlementResult = {
  won: true,
  betAmount: 100,
  odds: 2.5,
  payout: 250,
  balanceChange: 150,
};

const loseResult: SettlementResult = {
  won: false,
  betAmount: 100,
  odds: 2.5,
  payout: 0,
  balanceChange: -100,
};

describe('SettlementModal', () => {
  it('승리 -> 텍스트 + 양수 표시', () => {
    render(<SettlementModal result={winResult} onClose={vi.fn()} />);
    expect(screen.getByText(/WIN/i)).toBeInTheDocument();
    expect(screen.getByText('+150 BP')).toBeInTheDocument();
  });

  it('패배 -> 텍스트 + 음수 표시', () => {
    render(<SettlementModal result={loseResult} onClose={vi.fn()} />);
    expect(screen.getByText(/LOSE/i)).toBeInTheDocument();
    expect(screen.getByText('-100 BP')).toBeInTheDocument();
  });

  it('확인 버튼 -> onClose 호출', () => {
    const onClose = vi.fn();
    render(<SettlementModal result={winResult} onClose={onClose} />);
    const button = screen.getByRole('button');
    fireEvent.click(button);
    expect(onClose).toHaveBeenCalledOnce();
  });

  it('승리 시 배당률 표시', () => {
    render(<SettlementModal result={winResult} onClose={vi.fn()} />);
    expect(screen.getByText('2.50x')).toBeInTheDocument();
  });

  it('패배 시 베팅 금액 표시', () => {
    render(<SettlementModal result={loseResult} onClose={vi.fn()} />);
    expect(screen.getByText('100 BP')).toBeInTheDocument();
  });
});
