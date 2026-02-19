import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
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
              ref.watch(localeProvider)?.languageCode ?? 'en',
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
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final current = ref.read(localeProvider)?.languageCode;

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
              final code = locale.languageCode;
              final isSelected = code == (current ?? 'en');
              return ListTile(
                title: Text(_getLanguageName(code)),
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

  String _getLanguageName(String code) {
    return switch (code) {
      'en' => 'English',
      'ko' => '한국어',
      'ja' => '日本語',
      'zh' => '中文',
      'es' => 'Español',
      'fr' => 'Français',
      _ => code,
    };
  }
}
