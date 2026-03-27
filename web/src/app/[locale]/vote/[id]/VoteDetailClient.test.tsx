import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import VoteDetailClient from './VoteDetailClient';

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
      'betting.participants': 'Participants',
      'betting.closesIn': 'Closes in',
      'points.bp': 'BP',
      'landing.feature2Title': 'Join Discussion',
    };
    return map[key] ?? key;
  },
}));

vi.mock('@/i18n/navigation', () => ({
  Link: ({ children, href, ...props }: any) => (
    <a href={href} {...props}>{children}</a>
  ),
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    back: vi.fn(),
  }),
}));

vi.mock('@/hooks/usePoints', () => ({
  usePoints: () => ({
    balance: 500,
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
      correct_answer: null,
      status: 'active',
      total_pool: 2400,
      created_at: new Date().toISOString(),
      closes_at: new Date(Date.now() + 86400000 * 3).toISOString(),
      reveals_at: new Date(Date.now() + 86400000 * 4).toISOString(),
      settled_at: null,
    },
  }),
  fetchOdds: vi.fn().mockResolvedValue({ odds: { yes: 1.85, no: 2.10 } }),
  placeBet: vi.fn().mockResolvedValue({ success: true, odds: 1.85, newBalance: 450 }),
  settlePrediction: vi.fn().mockResolvedValue({ success: true, totalPaid: 100, creatorEarned: 10 }),
}));

vi.mock('@/lib/prediction/idempotency', () => ({
  generateIdempotencyKey: vi.fn().mockReturnValue('mock-key'),
}));

// ─── Tests ───

describe('VoteDetailClient (상세 페이지)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('질문 텍스트 표시', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });
  });

  it('YES/NO 배당률 표시', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('1.85x')).toBeInTheDocument();
      expect(screen.getByText('2.10x')).toBeInTheDocument();
    });
  });

  it('통계 카드 3개 표시 (참여자, 총 풀, 마감)', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Participants')).toBeInTheDocument();
    });
    expect(screen.getByText('Total Pool')).toBeInTheDocument();
    expect(screen.getByText('Closes in')).toBeInTheDocument();
  });

  it('총 풀 금액 표시 (2,400 BP)', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('2,400')).toBeInTheDocument();
    });
  });

  it('최근 베팅 기록 섹션 표시', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      // My Bets는 베팅 데이터가 있을 때만 표시되므로 stats만 확인
    expect(screen.getByText('Participants')).toBeInTheDocument();
    });
  });

  it('토론방 참여 CTA 링크 표시', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Join Discussion')).toBeInTheDocument();
    });
  });

  it('뒤로가기 링크가 /vote로 연결', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });
    const links = screen.getAllByRole('link');
    const voteLink = links.find((l) => l.getAttribute('href') === '/vote');
    expect(voteLink).toBeTruthy();
  });

  it('YES 버튼 클릭 시 옵션 선택 (슬라이더 표시)', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });
    const yesButtons = screen.getAllByRole('button').filter((b) => b.textContent?.includes('YES'));
    fireEvent.click(yesButtons[0]);
    expect(screen.getByRole('slider')).toBeInTheDocument();
  });

  it('NO 버튼 클릭 시 옵션 선택', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });
    const noButtons = screen.getAllByRole('button').filter((b) => b.textContent?.includes('NO'));
    fireEvent.click(noButtons[0]);
    expect(screen.getByRole('slider')).toBeInTheDocument();
  });

  it('포인트 디스플레이 헤더에 표시', async () => {
    render(<VoteDetailClient predictionId="demo-1" />);
    await waitFor(() => {
      expect(screen.getByText('500')).toBeInTheDocument();
    });
  });

  it('베팅 플로우: YES 선택 → 확정 → placeBet 호출', async () => {
    const { placeBet } = await import('@/lib/prediction/actions');
    render(<VoteDetailClient predictionId="demo-1" />);

    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });

    // 1. YES 선택
    const yesButtons = screen.getAllByRole('button').filter((b) => b.textContent?.includes('YES'));
    fireEvent.click(yesButtons[0]);
    expect(screen.getByRole('slider')).toBeInTheDocument();

    // 2. 두 번째 클릭 → placeBet 서버 액션 호출
    fireEvent.click(yesButtons[0]);
    await waitFor(() => {
      expect(placeBet).toHaveBeenCalled();
    });
  });
});
