import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kLanguageSettingKey = 'app_language_preference';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('en') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_kLanguageSettingKey);
    if (savedLang != null) {
      state = savedLang;
    }
  }

  Future<void> setLanguage(String langCode) async {
    state = langCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageSettingKey, langCode);
  }
}
