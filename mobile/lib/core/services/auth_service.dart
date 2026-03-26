import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_client.dart';

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

  /// 계정 삭제 (탈퇴)
  ///
  /// Apple 가이드라인 5.1.1(v) 준수:
  /// 1. Apple에 재인증 → authorization code 획득
  /// 2. 서버에서 Apple 토큰 철회 + Supabase 유저 삭제
  /// 3. 로컬 세션 정리
  Future<void> deleteAccount() async {
    final session = currentSession;
    if (session == null) {
      throw Exception('Not logged in');
    }

    // Apple 재인증으로 authorization code 획득
    // (토큰 철회에 필요 — Apple REST API 요구사항)
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
    );

    final authorizationCode = credential.authorizationCode;

    // 서버 API 호출: Apple 토큰 철회 + Supabase 유저 삭제
    final api = ApiClient();
    final result = await api.deleteAccount(
      accessToken: session.accessToken,
      authorizationCode: authorizationCode,
    );

    if (result['error'] != null) {
      throw Exception(result['error']);
    }

    // 로컬 세션 정리
    await _client.auth.signOut();
  }
}
