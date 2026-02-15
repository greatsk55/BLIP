import { ImageResponse } from 'next/og';
import type { NextRequest } from 'next/server';

export const runtime = 'edge';

const ogText = {
  home: {
    ko: { title: '말하고, 사라지세요.', subtitle: '누구도 엿볼 수 없음 · 계정 불필요 · 흔적 제로' },
    en: { title: 'Talk. Then Vanish.', subtitle: 'Completely Private · No Accounts · No Traces' },
    ja: { title: '話して、消える。', subtitle: '完全プライベート · アカウント不要 · 痕跡なし' },
    zh: { title: '交谈。然后消失。', subtitle: '完全私密 · 无需账号 · 不留痕迹' },
    es: { title: 'Habla. Luego desaparece.', subtitle: 'Totalmente privado · Sin cuentas · Sin rastro' },
    fr: { title: 'Parlez. Puis disparaissez.', subtitle: 'Totalement privé · Sans compte · Sans trace' },
  },
  room: {
    ko: { title: '비공개 채팅에 초대되었습니다', subtitle: '완전 비공개 대화 · 계정 없이 바로 참여' },
    en: { title: "You're invited to a private chat", subtitle: 'Fully private chat · Join instantly, no account needed' },
    ja: { title: 'プライベートチャットに招待されました', subtitle: '完全プライベート · アカウント不要で即参加' },
    zh: { title: '您被邀请加入私密聊天', subtitle: '完全私密对话 · 无需账号即可加入' },
    es: { title: 'Has sido invitado a un chat privado', subtitle: 'Chat totalmente privado · Únete al instante, sin cuenta' },
    fr: { title: 'Vous êtes invité à un chat privé', subtitle: 'Chat totalement privé · Rejoignez instantanément' },
  },
} as const;

const cjkFontFamily: Record<string, string> = {
  ko: 'Noto Sans KR',
  ja: 'Noto Sans JP',
  zh: 'Noto Sans SC',
};

async function loadGoogleFont(family: string, text: string, weight = 700): Promise<ArrayBuffer | null> {
  const url = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(family)}:wght@${weight}&text=${encodeURIComponent(text)}&display=swap`;
  try {
    const css = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
    }).then(res => res.text());

    const fontUrl = css.match(/src:\s*url\(([^)]+)\)/)?.[1];
    if (!fontUrl) return null;

    return fetch(fontUrl).then(res => res.arrayBuffer());
  } catch {
    return null;
  }
}

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const locale = searchParams.get('locale') || 'en';
  const type = (searchParams.get('type') || 'home') as 'home' | 'room';

  const textMap = ogText[type] ?? ogText.home;
  const texts = textMap[locale as keyof typeof textMap] ?? textMap.en;
  const displayText = `${texts.title} ${texts.subtitle} BLIP END-TO-END ENCRYPTED`;

  const fonts: { name: string; data: ArrayBuffer; weight: 400 | 700; style: 'normal' }[] = [];

  // CJK 폰트 로드 (한국어/일본어/중국어)
  const cjkFamily = cjkFontFamily[locale];
  if (cjkFamily) {
    const fontData = await loadGoogleFont(cjkFamily, displayText);
    if (fontData) {
      fonts.push({ name: 'MainFont', data: fontData, weight: 700, style: 'normal' });
    }
  }

  // Latin 폰트 (항상 로드 - CJK 폰트의 fallback)
  const interData = await loadGoogleFont('Inter', displayText);
  if (interData) {
    fonts.push({ name: 'MainFont', data: interData, weight: 700, style: 'normal' });
  }

  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          backgroundColor: '#0A0A0A',
          fontFamily: 'MainFont',
          position: 'relative',
        }}
      >
        {/* 상단 액센트 라인 */}
        <div
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            right: 0,
            height: '4px',
            background: 'linear-gradient(90deg, transparent, #00FF41, transparent)',
            display: 'flex',
          }}
        />

        {/* BLIP 로고 */}
        <div
          style={{
            fontSize: 80,
            fontWeight: 800,
            color: '#00FF41',
            letterSpacing: '0.3em',
            marginBottom: 24,
          }}
        >
          BLIP
        </div>

        {/* 타이틀 */}
        <div
          style={{
            fontSize: 44,
            fontWeight: 700,
            color: '#FFFFFF',
            textAlign: 'center',
            marginBottom: 20,
            maxWidth: 900,
            lineHeight: 1.3,
          }}
        >
          {texts.title}
        </div>

        {/* 서브타이틀 */}
        <div
          style={{
            fontSize: 22,
            color: '#555555',
            textAlign: 'center',
            letterSpacing: '0.05em',
          }}
        >
          {texts.subtitle}
        </div>

        {/* 하단 암호화 표시 */}
        <div
          style={{
            position: 'absolute',
            bottom: 40,
            display: 'flex',
            alignItems: 'center',
            gap: 8,
            fontSize: 14,
            color: '#00FF41',
            opacity: 0.5,
            letterSpacing: '0.15em',
          }}
        >
          END-TO-END ENCRYPTED
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
      ...(fonts.length > 0 ? { fonts } : {}),
    },
  );
}
