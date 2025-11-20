import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'theme/providers/theme_provider.dart' as theme_provider;

void main() async {
  // Ensure Flutter bindings are initialized
  material.WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([ 
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  material.runApp(
    // Wrap app with ChangeNotifierProvider for theme management
    ChangeNotifierProvider(
      create: (_) => theme_provider.ThemeProvider(),
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
    
    // Update system UI when theme changes
    _updateSystemUI(themeProvider.isDarkMode);

    return material.MaterialApp(
      title: 'SwiftRide',
      debugShowCheckedModeBanner: false,
      
      // Set initial route
      initialRoute: AppRoutes.splash,
      
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
        statusBarIconBrightness: isDark ? material.Brightness.light : material.Brightness.dark,
        statusBarBrightness: isDark ? material.Brightness.dark : material.Brightness.light,
        systemNavigationBarColor: isDark 
            ? const material.Color(0xFF0A0A0A) 
            : const material.Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: isDark ? material.Brightness.light : material.Brightness.dark,
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
  material.State<_SystemBrightnessListener> createState() => _SystemBrightnessListenerState();
}

class _SystemBrightnessListenerState extends material.State<_SystemBrightnessListener> with material.WidgetsBindingObserver {
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
    final brightness = material.WidgetsBinding.instance.platformDispatcher.platformBrightness;
    material.debugPrint('📱 System brightness changed to: $brightness');
    
    // Update theme provider
    final themeProvider = Provider.of<theme_provider.ThemeProvider>(context, listen: false);
    themeProvider.updateSystemBrightness(brightness);
  }

  @override
  material.Widget build(material.BuildContext context) {
    return widget.child;
  }
}