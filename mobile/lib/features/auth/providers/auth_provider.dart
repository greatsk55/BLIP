import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/auth_service.dart';

/// Supabase Auth 상태를 Riverpod으로 노출
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthService.instance.authStateChanges;
});

/// 로그인 상태 (간단 bool)
final isLoggedInProvider = Provider<bool>((ref) {
  // 스트림 값이 있고, 세션이 존재하면 로그인 상태
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
    data: (state) => state.session != null,
  ) ?? AuthService.instance.currentSession != null;
});
