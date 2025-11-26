import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language Service - Manages app language and localization
/// 
/// FILE LOCATION: lib/services/language_service.dart
/// 
/// Features:
/// - Multiple language support
/// - Persistent language selection
/// - Easy to add translations
/// - Singleton pattern for global access
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _languageKey = 'selected_language';
  Locale _currentLocale = const Locale('en', 'US'); // Default to English

  Locale get currentLocale => _currentLocale;
  String get currentLanguageCode => _currentLocale.languageCode;

  // Supported languages
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      countryCode: 'US',
      flag: '🇺🇸',
    ),
    AppLanguage(
      code: 'ha',
      name: 'Hausa',
      nativeName: 'Hausa',
      countryCode: 'NG',
      flag: '🇳🇬',
    ),
    AppLanguage(
      code: 'yo',
      name: 'Yoruba',
      nativeName: 'Yorùbá',
      countryCode: 'NG',
      flag: '🇳🇬',
    ),
    AppLanguage(
      code: 'ig',
      name: 'Igbo',
      nativeName: 'Igbo',
      countryCode: 'NG',
      flag: '🇳🇬',
    ),
    AppLanguage(
      code: 'pcm',
      name: 'Nigerian Pidgin',
      nativeName: 'Naija',
      countryCode: 'NG',
      flag: '🇳🇬',
    ),
  ];

  /// Initialize language service and load saved language
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);

      if (savedLanguageCode != null) {
        final language = supportedLanguages.firstWhere(
          (lang) => lang.code == savedLanguageCode,
          orElse: () => supportedLanguages[0],
        );
        _currentLocale = Locale(language.code, language.countryCode);
        notifyListeners();
        debugPrint('✅ Loaded saved language: ${language.name}');
      } else {
        debugPrint('ℹ️ No saved language, using default: English');
      }
    } catch (e) {
      debugPrint('❌ Error loading language: $e');
    }
  }

  /// Change app language
  Future<bool> changeLanguage(String languageCode) async {
    try {
      final language = supportedLanguages.firstWhere(
        (lang) => lang.code == languageCode,
        orElse: () => supportedLanguages[0],
      );

      _currentLocale = Locale(language.code, language.countryCode);
      
      // Save to persistent storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      notifyListeners();
      debugPrint('✅ Language changed to: ${language.name}');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error changing language: $e');
      return false;
    }
  }

  /// Get current language details
  AppLanguage getCurrentLanguage() {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == _currentLocale.languageCode,
      orElse: () => supportedLanguages[0],
    );
  }

  /// Check if a language is currently selected
  bool isLanguageSelected(String languageCode) {
    return _currentLocale.languageCode == languageCode;
  }

  /// Get localized string (placeholder for future translations)
  String translate(String key) {
    // TODO: Implement actual translation logic
    // For now, return the key as-is
    // In the future, load from translation files based on currentLocale
    return key;
  }

  /// Clear saved language preference
  Future<void> clearLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      _currentLocale = const Locale('en', 'US');
      notifyListeners();
      debugPrint('✅ Language preference cleared');
    } catch (e) {
      debugPrint('❌ Error clearing language: $e');
    }
  }
}

/// Language model
class AppLanguage {
  final String code;           // ISO 639-1 language code (e.g., 'en', 'ha')
  final String name;           // English name
  final String nativeName;     // Native name (e.g., 'Yorùbá')
  final String countryCode;    // ISO 3166-1 country code (e.g., 'US', 'NG')
  final String flag;           // Flag emoji

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.countryCode,
    required this.flag,
  });

  Locale get locale => Locale(code, countryCode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppLanguage && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

/// Extension for easy translation access
extension TranslationExtension on String {
  String tr() {
    return LanguageService().translate(this);
  }
}