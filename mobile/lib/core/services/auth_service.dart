import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Auth 래퍼 (SSOT) — iOS 전용 Apple Sign In
/// - 세션 기반: 로그인 상태만 유지, 유저 데이터 저장/관리 없음
/// - BLIP 철학: 최소한의 인증, 최대한의 프라이버시
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// 현재 로그인된 유저 (null이면 미로그인)
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  /// 로그인 상태 스트림
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with Apple (native iOS)
  Future<AuthResponse> signInWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
      ],
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign In failed: no identity token');
    }

    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
    );
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// 계정 삭제 (탈퇴) — Supabase에서는 Admin API 필요
  /// 클라이언트에서는 로그아웃만 수행
  Future<void> deleteAccount() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[BLIP] Account deletion failed: $e');
    }
  }
}
