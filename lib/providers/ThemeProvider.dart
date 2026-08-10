// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  static const String _themeKey = 'is_dark_mode';

  // Add a flag to prevent multiple rapid changes
  bool _isToggling = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  // Toggle theme - more efficient
  Future<void> toggleTheme() async {
    if (_isToggling) return; // Prevent rapid toggles

    _isToggling = true;
    _isDarkMode = !_isDarkMode;

    // Notify listeners immediately for instant UI update
    notifyListeners();

    // Save preference in background
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      print('Error saving theme: $e');
    } finally {
      _isToggling = false;
    }
  }

  void setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_themeKey, value);
      } catch (e) {
        print('Error saving theme: $e');
      }
    }
  }
}