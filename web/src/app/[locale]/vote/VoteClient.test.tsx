import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import VoteClient from './VoteClient';

// ─── Mocks ───

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    button: ({ children, whileHover, whileTap, ...props }: any) => (
      <button {...props}>{children}</button>
    ),
    span: ({ children, ...props }: any) => <span {...props}>{children}</span>,
    form: ({ children, ...props }: any) => <form {...props}>{children}</form>,
  },
  AnimatePresence: ({ children }: any) => <>{children}</>,
}));

vi.mock('next-intl', () => ({
  useTranslations: () => (key: string) => {
    const map: Record<string, string> = {
      title: 'Predictions',
      'categories.all': 'All',
      'categories.politics': 'Politics',
      'categories.sports': 'Sports',
      'categories.tech': 'Tech',
      'categories.economy': 'Economy',
      'categories.entertainment': 'Entertainment',
      'categories.society': 'Society',
      'categories.gaming': 'Gaming',
      'categories.other': 'Other',
      'betting.yes': 'YES',
      'betting.no': 'NO',
      'points.bp': 'BP',
      'landing.feature2Title': 'Discuss',
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
  fetchPredictions: vi.fn().mockResolvedValue({
    predictions: [
      {
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
      {
        id: 'demo-2',
        creator_fingerprint: 'demo',
        question: 'Next World Cup winner from Europe?',
        category: 'sports',
        type: 'yes_no',
        options: ['yes', 'no'],
        correct_answer: null,
        status: 'active',
        total_pool: 1800,
        created_at: new Date().toISOString(),
        closes_at: new Date(Date.now() + 86400000 * 7).toISOString(),
        reveals_at: new Date(Date.now() + 86400000 * 8).toISOString(),
        settled_at: null,
      },
      {
        id: 'demo-3',
        creator_fingerprint: 'demo',
        question: 'Will AI pass the Turing test by 2028?',
        category: 'tech',
        type: 'yes_no',
        options: ['yes', 'no'],
        correct_answer: null,
        status: 'active',
        total_pool: 3200,
        created_at: new Date().toISOString(),
        closes_at: new Date(Date.now() + 86400000 * 14).toISOString(),
        reveals_at: new Date(Date.now() + 86400000 * 15).toISOString(),
        settled_at: null,
      },
    ],
  }),
  fetchOdds: vi.fn().mockResolvedValue({ odds: { yes: 1.85, no: 2.10 } }),
  createPrediction: vi.fn().mockResolvedValue({ success: true, predictionId: 'new-1' }),
  fetchMyBets: vi.fn().mockResolvedValue({ bets: [] }),
  fetchMyPredictions: vi.fn().mockResolvedValue({ predictions: [] }),
}));

// ─── Tests ───

describe('VoteClient (리스트 페이지)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('페이지 제목 "Predictions" 표시', () => {
    render(<VoteClient locale="en" />);
    expect(screen.getByText('Predictions')).toBeInTheDocument();
  });

  it('카테고리 필터 버튼 전부 표시', () => {
    render(<VoteClient locale="en" />);
    // "All"은 탭 + 카테고리 두 곳에 존재
    expect(screen.getAllByText('All').length).toBeGreaterThanOrEqual(1);
    expect(screen.getByText('Sports')).toBeInTheDocument();
    expect(screen.getByText('Tech')).toBeInTheDocument();
    expect(screen.getByText('Economy')).toBeInTheDocument();
  });

  it('예측 카드 3개 표시', async () => {
    render(<VoteClient locale="en" />);
    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });
    expect(screen.getByText('Next World Cup winner from Europe?')).toBeInTheDocument();
    expect(screen.getByText('Will AI pass the Turing test by 2028?')).toBeInTheDocument();
  });

  it('카테고리 클릭 시 서버 호출 (필터링)', async () => {
    const { fetchPredictions } = await import('@/lib/prediction/actions');
    render(<VoteClient locale="en" />);

    await waitFor(() => {
      expect(screen.getByText('Will Bitcoin break $100k by 2027?')).toBeInTheDocument();
    });

    // sports 필터 클릭 → fetchPredictions가 locale + 'sports'로 재호출됨
    fireEvent.click(screen.getByText('Sports'));
    await waitFor(() => {
      expect(fetchPredictions).toHaveBeenCalledWith('en', 'sports');
    });
  });

  it('포인트 디스플레이 표시 (500 BP)', () => {
    render(<VoteClient locale="en" />);
    expect(screen.getByText('500')).toBeInTheDocument();
    expect(screen.getByText('BP')).toBeInTheDocument();
  });

  it('+ 버튼으로 생성 폼 모달 열기', async () => {
    render(<VoteClient locale="en" />);

    expect(screen.queryByText('CREATE PREDICTION')).not.toBeInTheDocument();

    const fabButtons = screen.getAllByRole('button');
    const fabButton = fabButtons.find(
      (btn) => btn.querySelector('svg') && btn.className.includes('fixed')
    );
    expect(fabButton).toBeTruthy();
    fireEvent.click(fabButton!);

    expect(screen.getByText('CREATE PREDICTION')).toBeInTheDocument();
  });

  it('배당률 YES/NO 표시', async () => {
    render(<VoteClient locale="en" />);
    await waitFor(() => {
      const yesOdds = screen.getAllByText('1.85x');
      expect(yesOdds.length).toBeGreaterThan(0);
    });
  });

  it('카드 링크가 /vote/{id}로 연결', async () => {
    render(<VoteClient locale="en" />);
    await waitFor(() => {
      const links = screen.getAllByRole('link');
      const voteLinks = links.filter((l) => l.getAttribute('href')?.includes('/vote/'));
      expect(voteLinks.length).toBe(3);
      expect(voteLinks[0].getAttribute('href')).toBe('/vote/demo-1');
    });
  });
});
