'use client';

interface TransferProgressProps {
  progress: number; // 0~1
  onCancel?: () => void;
}

export default function TransferProgress({ progress, onCancel }: TransferProgressProps) {
  const percent = Math.round(progress * 100);
  const radius = 20;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - progress);

  return (
    <div className="absolute inset-0 flex items-center justify-center bg-void-black/60">
      <button
        onClick={onCancel}
        className="relative w-14 h-14 flex items-center justify-center"
        aria-label={`${percent}% - Cancel transfer`}
      >
        <svg className="w-14 h-14 -rotate-90" viewBox="0 0 48 48">
          <circle
            cx="24"
            cy="24"
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className="text-ink/10"
          />
          <circle
            cx="24"
            cy="24"
            r={radius}
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeDasharray={circumference}
            strokeDashoffset={offset}
            strokeLinecap="round"
            className="text-signal-green transition-[stroke-dashoffset] duration-200"
          />
        </svg>
        <span className="absolute font-mono text-xs text-ink/70">
          {percent}%
        </span>
      </button>
    </div>
  );
}
