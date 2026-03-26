import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // ─── Theme ───
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: Text(l10n.settingsTheme),
            subtitle: Text(isDark ? l10n.settingsThemeDark : l10n.settingsThemeLight),
            trailing: Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              activeColor: AppColors.signalGreenDark,
            ),
          ),
          const Divider(),

          // ─── Language ───
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_getLanguageName(
              ref.watch(localeProvider) ?? const Locale('en'),
            )),
            onTap: () => _showLanguagePicker(context, ref),
          ),
          const Divider(),

          // ─── About ───
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAbout),
            subtitle: const Text('BLIP v1.0.0'),
          ),

          // ─── Account (iOS only) ───
          if (Platform.isIOS && AuthService.instance.currentSession != null) ...[
            const Divider(height: 32),
            _AccountSection(),
          ],
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.read(localeProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.settingsLanguage,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ...supportedLocales.map((locale) {
              final isSelected = locale.languageCode == (currentLocale?.languageCode ?? 'en') &&
                  locale.countryCode == currentLocale?.countryCode;
              return ListTile(
                title: Text(_getLanguageName(locale)),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(localeProvider.notifier).setLocale(locale);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(Locale locale) {
    final code = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    return switch (code) {
      'en' => 'English',
      'ko' => '한국어',
      'ja' => '日本語',
      'zh' => '中文（简体）',
      'zh_TW' => '中文（繁體）',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      _ => code,
    };
  }
}

/// 계정 관리 섹션 (로그아웃 + 계정 삭제)
class _AccountSection extends StatefulWidget {
  @override
  State<_AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends State<_AccountSection> {
  bool _deleting = false;

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;

    // 1차 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.authDeleteAccount),
        content: Text(l10n.authDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.glitchRed),
            child: Text(l10n.authDeleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    try {
      await AuthService.instance.deleteAccount();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.glitchRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // 로그아웃
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.authSignOut),
          onTap: _signOut,
        ),
        const Divider(),

        // 계정 삭제
        ListTile(
          leading: _deleting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_forever, color: AppColors.glitchRed),
          title: Text(
            l10n.authDeleteAccount,
            style: const TextStyle(color: AppColors.glitchRed),
          ),
          enabled: !_deleting,
          onTap: _deleteAccount,
        ),
      ],
    );
  }
}
