import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';

/// 로그인 화면 (iOS 전용 — Apple Sign In)
/// - 유저 데이터 저장 없음, 세션만 유지
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService.instance.signInWithApple();
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.voidBlackDark : AppColors.voidBlackLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── BLIP 로고 ──
              Text(
                'BLIP',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? AppColors.signalGreenDark
                      : AppColors.signalGreenLight,
                  letterSpacing: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.heroTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: isDark
                      ? AppColors.ghostGreyDark
                      : AppColors.ghostGreyLight,
                  letterSpacing: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // ── Apple Sign In ──
              if (_loading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _signInWithApple,
                    icon: Icon(
                      Icons.apple,
                      size: 24,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    label: Text(
                      l10n.authSignInApple,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.black,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: AppColors.glitchRed,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const Spacer(flex: 1),

              // ── 하단 안내 ──
              Text(
                l10n.authPrivacyNote,
                style: TextStyle(
                  fontSize: 11,
                  color: (isDark
                          ? AppColors.ghostGreyDark
                          : AppColors.ghostGreyLight)
                      .withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
