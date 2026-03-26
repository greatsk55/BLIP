import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import PointsDisplay from './PointsDisplay';

vi.mock('framer-motion', () => ({
  motion: {
    div: ({ children, ...props }: any) => <div {...props}>{children}</div>,
    span: ({ children, ...props }: any) => <span {...props}>{children}</span>,
  },
}));

describe('PointsDisplay', () => {
  it('잔액 표시: 1250 -> "1,250 BP"', () => {
    render(<PointsDisplay balance={1250} />);
    expect(screen.getByText('1,250')).toBeInTheDocument();
    expect(screen.getByText('BP')).toBeInTheDocument();
  });

  it('등급 뱃지 렌더링', () => {
    render(<PointsDisplay balance={5000} />);
    expect(screen.getByText('👑')).toBeInTheDocument();
    expect(screen.getByText('Oracle')).toBeInTheDocument();
  });

  it('0 BP -> 💀 Static 뱃지', () => {
    render(<PointsDisplay balance={0} />);
    expect(screen.getByText('💀')).toBeInTheDocument();
    expect(screen.getByText('Static')).toBeInTheDocument();
    expect(screen.getByText('0')).toBeInTheDocument();
  });

  it('큰 숫자 포맷: 1000000 -> "1,000,000"', () => {
    render(<PointsDisplay balance={1000000} />);
    expect(screen.getByText('1,000,000')).toBeInTheDocument();
  });
});
