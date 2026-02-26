import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseInitialized = false;

/// Supabase 초기화 여부
bool get isSupabaseInitialized => _supabaseInitialized;

/// Supabase 클라이언트 초기화
/// anon key만 사용 (service_role 절대 금지)
/// 용도: Realtime Broadcast + Presence
Future<void> initSupabase() async {
  final url = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
    debugPrint('[BLIP] SUPABASE_URL or SUPABASE_ANON_KEY not set in .env');
    return;
  }

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      eventsPerSecond: 10,
    ),
  );
  _supabaseInitialized = true;
}

/// Supabase 클라이언트 싱글톤
SupabaseClient get supabase => Supabase.instance.client;
