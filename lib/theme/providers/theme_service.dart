// ==================== theme_service.dart ====================
// Persist and retrieve theme preference using SharedPreferences

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'theme_provider.dart';

class ThemeService {
  static const String _themeKey = 'app_theme_mode';

  /// Get saved theme mode
  Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeKey);
      
      if (themeModeString == null) {
        debugPrint('🎨 No saved theme, defaulting to system');
        return ThemeMode.system;
      }

      return _stringToThemeMode(themeModeString);
    } catch (e) {
      debugPrint('❌ Error reading theme: $e');
      return ThemeMode.system;
    }
  }

  /// Save theme mode
  Future<void> saveThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeToString(mode));
      debugPrint('✅ Theme saved: $mode');
    } catch (e) {
      debugPrint('❌ Error saving theme: $e');
    }
  }

  /// Clear theme preference (revert to system)
  Future<void> clearThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_themeKey);
      debugPrint('🗑️ Theme preference cleared');
    } catch (e) {
      debugPrint('❌ Error clearing theme: $e');
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String modeString) {
    switch (modeString.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        debugPrint('⚠️ Unknown theme mode: $modeString, defaulting to system');
        return ThemeMode.system;
    }
  }
}