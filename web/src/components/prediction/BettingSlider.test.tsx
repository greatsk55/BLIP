import { describe, it, expect, vi } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import BettingSlider from './BettingSlider';

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    span: ({ children, ...props }: any) => <span {...props}>{children}</span>,
  },
}));

describe('BettingSlider', () => {
  it('슬라이더 렌더링: min=1, max=maxBet', () => {
    render(
      <BettingSlider
        amount={10}
        maxBet={100}
        odds={2.0}
        onChange={vi.fn()}
      />
    );
    const slider = screen.getByRole('slider');
    expect(slider).toBeInTheDocument();
    expect(slider).toHaveAttribute('min', '1');
    expect(slider).toHaveAttribute('max', '100');
  });

  it('onChange 콜백 호출', () => {
    const onChange = vi.fn();
    render(
      <BettingSlider
        amount={10}
        maxBet={100}
        odds={2.0}
        onChange={onChange}
      />
    );
    const slider = screen.getByRole('slider');
    fireEvent.change(slider, { target: { value: '50' } });
    expect(onChange).toHaveBeenCalledWith(50);
  });

  it('예상 수익 표시: amount=50, odds=2.5 -> "+125 BP"', () => {
    render(
      <BettingSlider
        amount={50}
        maxBet={200}
        odds={2.5}
        onChange={vi.fn()}
      />
    );
    expect(screen.getByText('+125 BP')).toBeInTheDocument();
  });

  it('잔액 부족 경고 미표시 (정상)', () => {
    render(
      <BettingSlider
        amount={10}
        maxBet={100}
        odds={2.0}
        onChange={vi.fn()}
      />
    );
    expect(screen.queryByText(/부족/)).not.toBeInTheDocument();
    expect(screen.queryByText(/insufficient/i)).not.toBeInTheDocument();
  });

  it('현재 베팅 금액 표시', () => {
    render(
      <BettingSlider
        amount={42}
        maxBet={100}
        odds={1.5}
        onChange={vi.fn()}
      />
    );
    expect(screen.getByText('42 BP')).toBeInTheDocument();
  });
});
