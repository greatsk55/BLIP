import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import VoteResultsClient from './VoteResultsClient';

// ─── Mocks ───

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

vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => {
    const map: Record<string, string> = {
      title: 'Predictions',
      'betting.yes': 'YES',
      'betting.no': 'NO',
      'betting.closed': 'Closed',
      'points.bp': 'BP',
    };
    return map[key] ?? key;
  },
}));

vi.mock('@/i18n/navigation', () => ({
  Link: ({ children, href, ...props }: any) => (
    <a href={href} {...props}>{children}</a>
  ),
}));

vi.mock('@/hooks/usePoints', () => ({
  usePoints: () => ({
    balance: 542,
    rank: { name: 'Signal', min: 50, max: 199, emoji: '⚡', color: 'blue' },
    rankInfo: { name: 'Signal', emoji: '⚡', color: 'blue' },
    loading: false,
    deviceFingerprint: 'mock-fp',
    setBalance: vi.fn(),
    setLoading: vi.fn(),
    refreshBalance: vi.fn(),
  }),
}));

vi.mock('@/lib/prediction/actions', () => ({
  fetchPrediction: vi.fn().mockResolvedValue({
    prediction: {
      id: 'demo-1',
      creator_fingerprint: 'demo',
      question: 'Will Bitcoin break $100k by 2027?',
      category: 'crypto',
      type: 'yes_no',
      options: ['yes', 'no'],
      correct_answer: 'yes',
      status: 'settled',
      total_pool: 2400,
      created_at: new Date().toISOString(),
      closes_at: new Date().toISOString(),
      reveals_at: new Date().toISOString(),
      settled_at: new Date().toISOString(),
    },
  }),
  fetchMyBets: vi.fn().mockResolvedValue({
    bets: [{
      id: 'bet-1',
      prediction_id: 'demo-1',
      device_fingerprint: 'mock-fp',
      option_id: 'yes',
      bet_amount: 50,
      odds_at_bet: '1.8500',
      status: 'won',
      payout: 92,
      created_at: new Date().toISOString(),
      settled_at: new Date().toISOString(),
    }],
  }),
}));

// ─── Tests ───

describe('VoteResultsClient (결과 페이지)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('질문 텍스트 표시', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });
  });

  it('정답 뱃지 표시', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText(/YES/)).toBeInTheDocument();
    });
  });

  it('결과 차트 퍼센트 표시', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText(/60%/)).toBeInTheDocument();
    });
  });

  it('정산 모달 표시 (WIN)', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('WIN')).toBeInTheDocument();
      expect(screen.getByText('🎯')).toBeInTheDocument();
    });
  });

  it('정산 모달: 베팅 금액 50 BP', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('50 BP')).toBeInTheDocument();
    });
  });

  it('정산 모달: 배당률 1.85x', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('1.85x')).toBeInTheDocument();
    });
  });

  it('정산 모달: 순이익 +42 BP', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('+42 BP')).toBeInTheDocument();
    });
  });

  it('정산 모달 OK 닫기', async () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('WIN')).toBeInTheDocument();
    });
    fireEvent.click(screen.getByText('OK'));
    expect(screen.queryByText('WIN')).not.toBeInTheDocument();
  });

  it('/vote로 돌아가기 링크', () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    const links = screen.getAllByRole('link');
    const voteLink = links.find((l) => l.getAttribute('href') === '/vote');
    expect(voteLink).toBeTruthy();
  });

  it('포인트 디스플레이 표시', () => {
    render(<VoteResultsClient predictionId="demo-1" />);
    expect(screen.getByText('542')).toBeInTheDocument();
  });
});
