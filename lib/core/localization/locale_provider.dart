import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_locale';
  Locale _locale = const Locale('bn'); // Default to Bangla for Somiti

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString(_prefKey);
    if (savedCode != null && (savedCode == 'en' || savedCode == 'bn')) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }

  void toggleLocale() {
    if (_locale.languageCode == 'bn') {
      setLocale(const Locale('en'));
    } else {
      setLocale(const Locale('bn'));
    }
  }
}
