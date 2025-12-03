import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ ADDED
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/providers/theme_provider.dart' as theme_provider;
// ✅ NEW: Import LanguageService
import 'services/language_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  material.WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ NEW: Initialize language service and load saved language
  final languageService = LanguageService();
  await languageService.initialize();
  material.debugPrint(
      '✅ Language service initialized: ${languageService.getCurrentLanguage().name}');

  material.runApp(
    // Wrap app with MultiProvider for both theme and language management
    MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(
          create: (_) => theme_provider.ThemeProvider(),
        ),
        // ✅ NEW: Language provider
        ChangeNotifierProvider.value(
          value: languageService,
        ),
      ],
      child: const SwiftRideApp(),
    ),
  );
}

class SwiftRideApp extends material.StatelessWidget {
  const SwiftRideApp({super.key});

  @override
  material.Widget build(material.BuildContext context) {
    // Listen to theme changes
    final themeProvider = Provider.of<theme_provider.ThemeProvider>(context);

    // ✅ NEW: Listen to language changes
    final languageService = Provider.of<LanguageService>(context);

    // Update system UI when theme changes
    _updateSystemUI(themeProvider.isDarkMode);

    return material.MaterialApp(
      title: 'SwiftRide',
      debugShowCheckedModeBanner: false,

      // Set initial route
      initialRoute: AppRoutes.splash,

      // ✅ FIXED: Only Flutter-supported locales for MaterialApp
      locale: languageService.currentLocale,
      supportedLocales: const [
        material.Locale('en', 'US'), // ✅ Only standard locales
      ],

      // ✅ FIXED: Localization delegates for Material and Cupertino widgets
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      // ✅ FIXED: Handle unsupported locales (ha_NG, yo_NG, ig_NG, pcm_NG) gracefully
      localeResolutionCallback: (locale, supportedLocales) {
        // If the selected locale is supported, use it
        if (supportedLocales.contains(locale)) {
          return locale;
        }

        // For unsupported locales, try to find a match by language code
        // Example: ha_NG not supported, but we have ha_NG in supportedLocales
        // This handles the case where device asks for an exact match
        for (var supported in supportedLocales) {
          if (supported.languageCode == locale?.languageCode) {
            return supported;
          }
        }

        // Default to English if nothing matches
        return const material.Locale('en', 'US');
      },

      // Theme configuration - switches between light and dark
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _getThemeMode(themeProvider),

      // Routes
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      onUnknownRoute: AppRoutes.onUnknownRoute,

      // Builder to listen to system brightness changes
      builder: (context, child) {
        return material.MediaQuery(
          // Listen for system brightness changes
          data: material.MediaQuery.of(context),
          child: _SystemBrightnessListener(
            child: child!,
          ),
        );
      },
    );
  }

  // Convert our ThemeMode to Flutter's ThemeMode
  material.ThemeMode _getThemeMode(theme_provider.ThemeProvider provider) {
    switch (provider.themeMode) {
      case theme_provider.ThemeMode.light:
        return material.ThemeMode.light;
      case theme_provider.ThemeMode.dark:
        return material.ThemeMode.dark;
      case theme_provider.ThemeMode.system:
        return material.ThemeMode.system;
    }
  }

  // Update system UI overlay colors based on theme
  void _updateSystemUI(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: material.Colors.transparent,
        statusBarIconBrightness:
            isDark ? material.Brightness.light : material.Brightness.dark,
        statusBarBrightness:
            isDark ? material.Brightness.dark : material.Brightness.light,
        systemNavigationBarColor: isDark
            ? const material.Color(0xFF0A0A0A)
            : const material.Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness:
            isDark ? material.Brightness.light : material.Brightness.dark,
      ),
    );
  }
}

// ============================================
// SYSTEM BRIGHTNESS LISTENER
// ============================================

class _SystemBrightnessListener extends material.StatefulWidget {
  final material.Widget child;

  const _SystemBrightnessListener({required this.child});

  @override
  material.State<_SystemBrightnessListener> createState() =>
      _SystemBrightnessListenerState();
}

class _SystemBrightnessListenerState extends material
    .State<_SystemBrightnessListener> with material.WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    material.WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    material.WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // System theme changed (user changed phone's dark mode setting)
    final brightness =
        material.WidgetsBinding.instance.platformDispatcher.platformBrightness;
    material.debugPrint('📱 System brightness changed to: $brightness');

    // Update theme provider
    final themeProvider =
        Provider.of<theme_provider.ThemeProvider>(context, listen: false);
    themeProvider.updateSystemBrightness(brightness);
  }

  @override
  material.Widget build(material.BuildContext context) {
    return widget.child;
  }
}
