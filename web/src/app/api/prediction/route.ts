import { NextRequest, NextResponse } from 'next/server';
import { createServerSupabase } from '@/lib/supabase/server';

/**
 * GET /api/prediction?locale=ko&category=tech
 *
 * locale 기반으로 예측 조회.
 * 해당 locale에 데이터가 없으면 'en' fallback.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl;
  const locale = searchParams.get('locale') ?? 'en';
  const category = searchParams.get('category');

  const supabase = createServerSupabase();

  // 1차: 유저 locale로 조회
  let query = supabase
    .from('predictions')
    .select('*')
    .eq('locale', locale)
    .order('created_at', { ascending: false })
    .limit(30);

  if (category && category !== 'all') {
    query = query.eq('category', category);
  }

  const { data, error } = await query;

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  // 2차: 데이터 없으면 'en' fallback
  if ((!data || data.length === 0) && locale !== 'en') {
    let fallbackQuery = supabase
      .from('predictions')
      .select('*')
      .eq('locale', 'en')
      .order('created_at', { ascending: false })
      .limit(30);

    if (category && category !== 'all') {
      fallbackQuery = fallbackQuery.eq('category', category);
    }

    const { data: fallbackData, error: fallbackError } = await fallbackQuery;

    if (fallbackError) {
      return NextResponse.json({ error: fallbackError.message }, { status: 500 });
    }

    return NextResponse.json({ predictions: fallbackData ?? [], fallback: true });
  }

  return NextResponse.json({ predictions: data ?? [] });
}
