import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import RankBadge from './RankBadge';

vi.mock('framer-motion', () => ({
  motion: {
    span: ({ children, ...props }: any) => <span {...props}>{children}</span>,
  },
}));

describe('RankBadge', () => {
  it('Static 등급 -> 💀 이모지 + "Static" 텍스트', () => {
    render(<RankBadge rank="Static" />);
    expect(screen.getByText('💀')).toBeInTheDocument();
    expect(screen.getByText('Static')).toBeInTheDocument();
  });

  it('Oracle 등급 -> 👑 이모지 + "Oracle" 텍스트', () => {
    render(<RankBadge rank="Oracle" />);
    expect(screen.getByText('👑')).toBeInTheDocument();
    expect(screen.getByText('Oracle')).toBeInTheDocument();
  });

  it('색상: Oracle -> gold 클래스', () => {
    const { container } = render(<RankBadge rank="Oracle" />);
    const badge = container.firstElementChild;
    expect(badge?.className).toContain('gold');
  });

  it('색상: Static -> grey 클래스', () => {
    const { container } = render(<RankBadge rank="Static" />);
    const badge = container.firstElementChild;
    expect(badge?.className).toContain('grey');
  });

  it('Decoder 등급 -> 🔥 이모지 + "Decoder" 텍스트', () => {
    render(<RankBadge rank="Decoder" />);
    expect(screen.getByText('🔥')).toBeInTheDocument();
    expect(screen.getByText('Decoder')).toBeInTheDocument();
  });
});
