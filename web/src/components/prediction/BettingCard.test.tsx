import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import BettingCard from './BettingCard';
import type { Prediction } from '@/types/prediction';

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    button: ({ children, whileHover, whileTap, ...props }: any) => (
      <button {...props}>{children}</button>
    ),
    span: ({ children, ...props }: any) => <span {...props}>{children}</span>,
  },
  AnimatePresence: ({ children }: any) => <>{children}</>,
}));

const basePrediction: Prediction = {
  id: 'pred-1',
  creatorFingerprint: 'fp-1',
  question: 'BTC가 10만 달러를 돌파할까?',
  category: 'crypto',
  type: 'yes_no',
  options: ['YES', 'NO'],
  correctAnswer: null,
  status: 'active',
  totalPool: 1000,
  createdAt: '2026-03-20T00:00:00Z',
  closesAt: '2026-03-30T23:59:59Z',
  revealsAt: '2026-03-31T00:00:00Z',
  settledAt: null,
};

describe('BettingCard', () => {
  it('질문 텍스트 표시', () => {
    render(
      <BettingCard
        prediction={basePrediction}
        yesOdds={1.8}
        noOdds={2.2}
        balance={500}
        onBet={vi.fn()}
      />
    );
    expect(screen.getByText('BTC가 10만 달러를 돌파할까?')).toBeInTheDocument();
  });

  it('카테고리 표시', () => {
    render(
      <BettingCard
        prediction={basePrediction}
        yesOdds={1.8}
        noOdds={2.2}
        balance={500}
        onBet={vi.fn()}
      />
    );
    expect(screen.getByText('crypto')).toBeInTheDocument();
  });

  it('배당률 YES/NO 표시', () => {
    render(
      <BettingCard
        prediction={basePrediction}
        yesOdds={1.8}
        noOdds={2.2}
        balance={500}
        onBet={vi.fn()}
      />
    );
    expect(screen.getByText('1.80x')).toBeInTheDocument();
    expect(screen.getByText('2.20x')).toBeInTheDocument();
  });

  it('마감 시간 표시', () => {
    render(
      <BettingCard
        prediction={basePrediction}
        yesOdds={1.8}
        noOdds={2.2}
        balance={500}
        onBet={vi.fn()}
      />
    );
    expect(screen.getByText(/2026/)).toBeInTheDocument();
  });

  it('마감된 질문 -> 버튼 disabled', () => {
    const closedPrediction = { ...basePrediction, status: 'closed' as const };
    render(
      <BettingCard
        prediction={closedPrediction}
        yesOdds={1.8}
        noOdds={2.2}
        balance={500}
        onBet={vi.fn()}
      />
    );
    const buttons = screen.getAllByRole('button');
    buttons.forEach((btn) => {
      expect(btn).toBeDisabled();
    });
  });

  it('베팅 버튼 클릭 가능 (선택 후 확정)', () => {
    const onBet = vi.fn();
    render(
      <BettingCard
        prediction={basePrediction}
        yesOdds={1.8}
        noOdds={2.2}
        balance={500}
        onBet={onBet}
      />
    );
    const yesButton = screen.getByText('YES');
    // 첫 클릭: 옵션 선택
    fireEvent.click(yesButton);
    expect(onBet).not.toHaveBeenCalled();
    // 두 번째 클릭: 베팅 확정
    fireEvent.click(yesButton);
    expect(onBet).toHaveBeenCalledWith('YES', expect.any(Number));
  });
});
