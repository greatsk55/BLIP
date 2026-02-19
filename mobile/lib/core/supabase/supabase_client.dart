import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 클라이언트 초기화
/// anon key만 사용 (service_role 절대 금지)
/// 용도: Realtime Broadcast + Presence
Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    throw StateError('SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env');
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );
}

/// Supabase 클라이언트 싱글톤
SupabaseClient get supabase => Supabase.instance.client;
