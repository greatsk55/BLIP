import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent } from '@testing-library/react';
import CreatePredictionForm from './CreatePredictionForm';

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    button: ({ children, whileHover, whileTap, ...props }: any) => (
      <button {...props}>{children}</button>
    ),
    form: ({ children, ...props }: any) => <form {...props}>{children}</form>,
  },
}));

describe('CreatePredictionForm', () => {
  const onSubmit = vi.fn();

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('폼 요소 전부 렌더링', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);
    expect(screen.getByLabelText('QUESTION')).toBeInTheDocument();
    expect(screen.getByLabelText('CATEGORY')).toBeInTheDocument();
    expect(screen.getByLabelText('CLOSES AT')).toBeInTheDocument();
    expect(screen.getByText('CREATE PREDICTION')).toBeInTheDocument();
  });

  it('잔액 부족 시 COST 빨간색 + 버튼 disabled', () => {
    render(<CreatePredictionForm balance={100} onSubmit={onSubmit} />);
    // COST 150 BP > balance 100
    const costText = screen.getByText('150 BP');
    expect(costText.className).toContain('glitch-red');

    const submitBtn = screen.getByText('CREATE PREDICTION');
    expect(submitBtn).toBeDisabled();
  });

  it('잔액 충분하면 COST 초록색', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);
    const costText = screen.getByText('150 BP');
    expect(costText.className).toContain('signal-green');
  });

  it('질문 입력 + 마감일 설정 시 버튼 활성화', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);

    const questionInput = screen.getByLabelText('QUESTION');
    const closesAtInput = screen.getByLabelText('CLOSES AT');

    // 처음엔 disabled
    expect(screen.getByText('CREATE PREDICTION')).toBeDisabled();

    // 질문 입력
    fireEvent.change(questionInput, { target: { value: 'Will ETH hit $10k?' } });
    // 아직 마감일 미입력 → disabled
    expect(screen.getByText('CREATE PREDICTION')).toBeDisabled();

    // 마감일 입력
    fireEvent.change(closesAtInput, { target: { value: '2026-12-31T23:59' } });
    // 이제 활성화
    expect(screen.getByText('CREATE PREDICTION')).not.toBeDisabled();
  });

  it('제출 시 onSubmit 호출 (question, category, closesAt)', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText('QUESTION'), {
      target: { value: 'Will ETH hit $10k?' },
    });
    fireEvent.change(screen.getByLabelText('CLOSES AT'), {
      target: { value: '2026-12-31T23:59' },
    });

    fireEvent.click(screen.getByText('CREATE PREDICTION'));

    expect(onSubmit).toHaveBeenCalledWith({
      question: 'Will ETH hit $10k?',
      category: 'crypto', // 기본값
      closesAt: '2026-12-31T23:59',
    });
  });

  it('카테고리 변경 후 제출', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText('QUESTION'), {
      target: { value: 'Next president?' },
    });
    fireEvent.change(screen.getByLabelText('CATEGORY'), {
      target: { value: 'politics' },
    });
    fireEvent.change(screen.getByLabelText('CLOSES AT'), {
      target: { value: '2026-11-05T00:00' },
    });

    fireEvent.click(screen.getByText('CREATE PREDICTION'));

    expect(onSubmit).toHaveBeenCalledWith({
      question: 'Next president?',
      category: 'politics',
      closesAt: '2026-11-05T00:00',
    });
  });

  it('빈 질문 → 제출 불가', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText('CLOSES AT'), {
      target: { value: '2026-12-31T23:59' },
    });

    fireEvent.click(screen.getByText('CREATE PREDICTION'));
    expect(onSubmit).not.toHaveBeenCalled();
  });

  it('공백만 있는 질문 → 제출 불가', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText('QUESTION'), {
      target: { value: '   ' },
    });
    fireEvent.change(screen.getByLabelText('CLOSES AT'), {
      target: { value: '2026-12-31T23:59' },
    });

    expect(screen.getByText('CREATE PREDICTION')).toBeDisabled();
  });

  it('200자 제한 (maxLength)', () => {
    render(<CreatePredictionForm balance={500} onSubmit={onSubmit} />);
    const input = screen.getByLabelText('QUESTION') as HTMLInputElement;
    expect(input.maxLength).toBe(200);
  });

  it('Control 등급 → 120 BP (20% 할인)', () => {
    // balance 1500 → getRank → Control (min 1000)
    render(<CreatePredictionForm balance={1500} onSubmit={onSubmit} />);
    expect(screen.getByText('120 BP')).toBeInTheDocument();
    // 원래 가격 취소선
    expect(screen.getByText('150 BP')).toBeInTheDocument();
  });

  it('Oracle 등급 → 75 BP (50% 할인)', () => {
    // balance 6000 → getRank → Oracle (min 5000)
    render(<CreatePredictionForm balance={6000} onSubmit={onSubmit} />);
    expect(screen.getByText('75 BP')).toBeInTheDocument();
    expect(screen.getByText('150 BP')).toBeInTheDocument();
  });
});
