import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  // Initialize with ThemeMode.dark to make it the default
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}