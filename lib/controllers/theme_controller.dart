import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controller for managing theme (dark/light mode)
class ThemeController extends GetxController {
  var isDarkMode = false.obs;
  static const String _themeKey = 'theme_mode';

  @override
  void onInit() {
    super.onInit();
    loadThemeFromPreferences();
  }

  /// Load theme preference from SharedPreferences
  Future<void> loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkMode.value = prefs.getBool(_themeKey) ?? false;
      _updateTheme();
    } catch (e) {
      print('Error loading theme preference: $e');
    }
  }

  /// Toggle between dark and light theme
  Future<void> toggleTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isDarkMode.value = !isDarkMode.value;
      await prefs.setBool(_themeKey, isDarkMode.value);
      _updateTheme();
    } catch (e) {
      print('Error toggling theme: $e');
    }
  }

  /// Update GetX theme
  void _updateTheme() {
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  /// Get current theme mode
  ThemeMode get themeMode {
    return isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
  }
}
