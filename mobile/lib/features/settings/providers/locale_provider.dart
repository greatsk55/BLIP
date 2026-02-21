import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'blip_locale';

/// 지원 언어 목록 (web과 동일)
const supportedLocales = [
  Locale('en'),
  Locale('ko'),
  Locale('ja'),
  Locale('zh'),
  Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
  Locale('es'),
  Locale('fr'),
  Locale('de'),
];

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(null) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (code != null) {
      final parts = code.split('_');
      state = parts.length > 1
          ? Locale.fromSubtags(languageCode: parts[0], countryCode: parts[1])
          : Locale(parts[0]);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    final key = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    await prefs.setString(_localeKey, key);
  }
}
