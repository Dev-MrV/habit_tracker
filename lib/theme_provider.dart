import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_constants.dart';

class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false; // Default until loaded
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(AppConstants.keyTheme) ?? false;
  }

  Future<void> toggleTheme() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyTheme, state);
  }

  Future<void> setDark(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyTheme, state);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() => ThemeNotifier());