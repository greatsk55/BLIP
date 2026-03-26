import { describe, it, expect } from 'vitest';
import { getRank, getRankBadge } from './rank';

describe('getRank', () => {
  it('0~4 → Static', () => {
    expect(getRank(0).name).toBe('Static');
    expect(getRank(4).name).toBe('Static');
  });

  it('5~49 → Receiver', () => {
    expect(getRank(5).name).toBe('Receiver');
    expect(getRank(49).name).toBe('Receiver');
  });

  it('50~199 → Signal', () => {
    expect(getRank(50).name).toBe('Signal');
    expect(getRank(199).name).toBe('Signal');
  });

  it('200~999 → Decoder', () => {
    expect(getRank(200).name).toBe('Decoder');
    expect(getRank(999).name).toBe('Decoder');
  });

  it('1000~4999 → Control', () => {
    expect(getRank(1000).name).toBe('Control');
    expect(getRank(4999).name).toBe('Control');
  });

  it('5000+ → Oracle', () => {
    expect(getRank(5000).name).toBe('Oracle');
    expect(getRank(999999).name).toBe('Oracle');
  });

  it('음수 → Static', () => {
    expect(getRank(-1).name).toBe('Static');
    expect(getRank(-100).name).toBe('Static');
  });
});

describe('getRankBadge', () => {
  it('emoji + color 반환', () => {
    const badge = getRankBadge(50);
    expect(badge.emoji).toBe('\u{26A1}');
    expect(badge.color).toBe('blue');
  });

  it('Static badge', () => {
    const badge = getRankBadge(0);
    expect(badge.emoji).toBe('\u{1F480}');
    expect(badge.color).toBe('grey');
  });
});
