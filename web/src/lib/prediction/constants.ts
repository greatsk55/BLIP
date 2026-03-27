// SSOT: 포인트 베팅 시스템 상수

export const RAKE_RATE = 0.1;
export const MIN_ODDS = 1.05;
export const MAX_ODDS = 20.0;
export const MIN_BET = 1;
export const MAX_BET_CAP = 500;
export const MAX_BET_PERCENT = 0.5;
export const CREATION_COST = 150;
export const INITIAL_BALANCE = 100;
export const DAILY_REWARD = 1;
export const DAILY_REWARD_INTERVAL_HOURS = 48;

export interface RankThreshold {
  name: string;
  min: number;
  max: number;
  emoji: string;
  color: string;
}

export const RANK_THRESHOLDS: RankThreshold[] = [
  { name: 'Static', min: 0, max: 4, emoji: '\u{1F480}', color: 'grey' },
  { name: 'Receiver', min: 5, max: 49, emoji: '\u{1F331}', color: 'green' },
  { name: 'Signal', min: 50, max: 199, emoji: '\u{26A1}', color: 'blue' },
  { name: 'Decoder', min: 200, max: 999, emoji: '\u{1F525}', color: 'orange' },
  { name: 'Control', min: 1000, max: 4999, emoji: '\u{1F48E}', color: 'purple' },
  { name: 'Oracle', min: 5000, max: Infinity, emoji: '\u{1F451}', color: 'gold' },
];

export const CREATION_COST_DISCOUNT: Record<string, number> = {
  Control: 0.8,
  Oracle: 0.5,
};
