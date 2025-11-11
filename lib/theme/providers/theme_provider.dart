// ==================== theme_provider.dart ====================
// Theme State Management with System Theme Support
// Automatically detects system theme on app start

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'theme_service.dart';

enum ThemeMode {
  light,
  dark,
  system, // Follows device setting
}

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  
  ThemeMode _themeMode = ThemeMode.system;
  Brightness _systemBrightness = Brightness.light;

  ThemeProvider() {
    _loadTheme();
    _detectSystemBrightness();
  }

  // ============================================
  // GETTERS
  // ============================================

  ThemeMode get themeMode => _themeMode;
  
  /// Returns the actual brightness being used
  Brightness get currentBrightness {
    if (_themeMode == ThemeMode.system) {
      return _systemBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  bool get isDarkMode => currentBrightness == Brightness.dark;
  bool get isLightMode => currentBrightness == Brightness.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> _loadTheme() async {
    try {
      _themeMode = await _themeService.getThemeMode();
      debugPrint('🎨 Loaded theme: $_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading theme: $e');
      _themeMode = ThemeMode.system; // Fallback to system
    }
  }

  void _detectSystemBrightness() {
    // Get system brightness from Flutter
    final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    _systemBrightness = brightness;
    debugPrint('📱 System brightness: $brightness');
  }

  // ============================================
  // THEME SWITCHING
  // ============================================

  /// Set theme to light mode
  Future<void> setLightMode() async {
    if (_themeMode == ThemeMode.light) return;
    
    debugPrint('☀️ Switching to light mode');
    _themeMode = ThemeMode.light;
    await _themeService.saveThemeMode(ThemeMode.light);
    notifyListeners();
  }

  /// Set theme to dark mode
  Future<void> setDarkMode() async {
    if (_themeMode == ThemeMode.dark) return;
    
    debugPrint('🌙 Switching to dark mode');
    _themeMode = ThemeMode.dark;
    await _themeService.saveThemeMode(ThemeMode.dark);
    notifyListeners();
  }

  /// Set theme to follow system
  Future<void> setSystemMode() async {
    if (_themeMode == ThemeMode.system) return;
    
    debugPrint('🔄 Switching to system mode');
    _themeMode = ThemeMode.system;
    await _themeService.saveThemeMode(ThemeMode.system);
    _detectSystemBrightness();
    notifyListeners();
  }

  /// Toggle between light and dark (keeps system mode if active)
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.system) {
      // If in system mode, switch to opposite of current system brightness
      if (_systemBrightness == Brightness.dark) {
        await setLightMode();
      } else {
        await setDarkMode();
      }
    } else if (_themeMode == ThemeMode.light) {
      await setDarkMode();
    } else {
      await setLightMode();
    }
  }

  // ============================================
  // SYSTEM BRIGHTNESS UPDATES
  // ============================================

  /// Call this when system brightness changes
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness == brightness) return;
    
    debugPrint('🔄 System brightness changed: $brightness');
    _systemBrightness = brightness;
    
    // Only notify if we're in system mode
    if (_themeMode == ThemeMode.system) {
      notifyListeners();
    }
  }
}