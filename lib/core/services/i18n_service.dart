import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/ui_translations.dart';
import '../utils/app_config.dart';

class I18nService {
  static final langNotifier = ValueNotifier<String>('en');

  static const _rtlLangs = ['he', 'fa'];
  static const supportedLangs = ['en', 'he', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'fa', 'tr'];

  static String get currentLang => langNotifier.value;
  static bool get isRtl => _rtlLangs.contains(currentLang);
  static bool isRtlLang(String lang) => _rtlLangs.contains(lang);

  static String t(String key, [Map<String, dynamic>? params]) {
    final langMap = uiTranslations[currentLang] ?? uiTranslations['en']!;
    String value = langMap[key] ?? uiTranslations['en']![key] ?? key;
    if (params != null) {
      params.forEach((k, v) => value = value.replaceAll('{$k}', v.toString()));
    }
    return value;
  }

  static Future<void> setLang(String lang) async {
    if (!uiTranslations.containsKey(lang)) return;
    langNotifier.value = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.uiLanguageKey, lang);
  }

  static Future<void> detectLang() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Previously saved preference wins
    final saved = prefs.getString(AppConfig.uiLanguageKey);
    if (saved != null && uiTranslations.containsKey(saved)) {
      langNotifier.value = saved;
      return;
    }

    // 2. Fall back to device system language
    final deviceLang = _deviceLanguageCode();
    if (uiTranslations.containsKey(deviceLang)) {
      langNotifier.value = deviceLang;
    }
    // 3. Otherwise keeps default 'en'
  }

  static String _deviceLanguageCode() {
    try {
      // Works on all platforms including web
      return WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
    } catch (_) {
      return 'en';
    }
  }
}
