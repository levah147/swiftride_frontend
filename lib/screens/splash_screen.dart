// ==================== splash_screen.dart ====================
// Production-ready Splash Screen with Theme Support
// Automatically adapts to light/dark mode

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final AuthService _authService = AuthService();
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      debugPrint('🚀 ============================================');
      debugPrint('🚀 SwiftRide App Initialization Started');
      debugPrint('🚀 ============================================');

      await Future.wait([
        _checkAuthStatus(),
        Future.delayed(const Duration(milliseconds: 2500)),
      ]);

      if (!mounted) {
        debugPrint('⚠️ Widget unmounted during initialization');
        return;
      }

      debugPrint('✅ Initialization Complete');
      debugPrint('📊 Auth Status: ${_isLoggedIn ? "Logged In" : "Not Logged In"}');
      
      _navigateToNextScreen();
      
    } catch (e) {
      debugPrint('❌ Critical initialization error: $e');
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted && !_hasNavigated) {
        _isLoggedIn = false;
        _navigateToNextScreen();
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      debugPrint('🔐 Checking authentication status...');
      
      final hasToken = await _authService.isLoggedIn();
      debugPrint('📱 Local token exists: $hasToken');

      if (!hasToken) {
        _isLoggedIn = false;
        _isCheckingAuth = false;
        debugPrint('❌ No token found. User needs to login');
        return;
      }

      debugPrint('🔄 Verifying token with backend...');
      
      final response = await _authService.getCurrentUser().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏱️ Auth verification timeout');
          return ApiResponse.error('Connection timeout');
        },
      );

      if (response.isSuccess && response.data != null) {
        _isLoggedIn = true;
        debugPrint('✅ Token verified successfully');
        debugPrint('👤 User: ${response.data!.fullName}');
        debugPrint('📧 Phone: ${response.data!.phoneNumber}');
      } else {
        _isLoggedIn = false;
        debugPrint('❌ Token verification failed: ${response.error}');
        
        await _authService.logout();
        debugPrint('🗑️ Invalid token cleared');
      }

    } catch (e) {
      debugPrint('❌ Auth check error: $e');
      _isLoggedIn = false;
      
      try {
        await _authService.logout();
      } catch (logoutError) {
        debugPrint('⚠️ Error clearing token: $logoutError');
      }
    } finally {
      _isCheckingAuth = false;
    }
  }

  void _navigateToNextScreen() {
    if (!mounted || _hasNavigated) {
      debugPrint('⚠️ Navigation skipped: mounted=$mounted, hasNavigated=$_hasNavigated');
      return;
    }

    _hasNavigated = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) {
        debugPrint('⚠️ Widget unmounted during navigation delay');
        return;
      }

      final destination = _isLoggedIn ? AppRoutes.home : AppRoutes.auth;
      debugPrint('🧭 Navigating to: $destination');
      debugPrint('🚀 ============================================\n');

      Navigator.of(context).pushReplacementNamed(destination);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    // Update system UI based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        // ✅ FIXED: Use scaffoldBackgroundColor instead of colorScheme.background
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    // Theme-aware gradient colors
    final gradientColors = isDark
        ? [
            const Color(0xFF0A0A0A),
            const Color(0xFF1A1A2E),
            const Color(0xFF0A0A0A),
          ]
        : [
            const Color(0xFFFAFAFA),
            const Color(0xFFE6F0FF),
            const Color(0xFFFAFAFA),
          ];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxH = constraints.maxHeight;
              final maxW = constraints.maxWidth;

              final logoSize = maxH * 0.10;
              final titleFontSize = maxH * 0.065;
              final animationHeight = maxH * 0.30;
              final textFontSize = maxH * 0.022;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // BRAND LOGO & NAME
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.primary, colorScheme.tertiary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: logoSize * 0.5,
                          ),
                        ),
                        
                        SizedBox(height: maxH * 0.03),
                        
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [colorScheme.primary, colorScheme.tertiary],
                          ).createShader(
                            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                          ),
                          child: Text(
                            'SwiftRide',
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -2,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: maxH * 0.05),

                  // ANIMATION
                  _buildAnimation(maxW, animationHeight, colorScheme.primary),

                  const Spacer(flex: 1),

                  // BOTTOM TEXT & LOADING
                  SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Your ride, your way',
                          style: TextStyle(
                            fontSize: textFontSize,
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        SizedBox(height: maxH * 0.025),
                        
                        if (_isCheckingAuth)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAnimation(double maxW, double animationHeight, Color primaryColor) {
    return FutureBuilder<bool>(
      future: _checkAssetExists('assets/animations/car_animation.json'),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return Lottie.asset(
            'assets/animations/car_animation.json',
            width: maxW * 0.8,
            height: animationHeight,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackAnimation(animationHeight, primaryColor);
            },
          );
        }
        
        return _buildFallbackAnimation(animationHeight, primaryColor);
      },
    );
  }

  Widget _buildFallbackAnimation(double height, Color color) {
    return SizedBox(
      height: height,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(seconds: 2),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset((value * 100) - 50, 0),
              child: Icon(
                Icons.directions_car_rounded,
                size: 80,
                color: color.withOpacity(0.8),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _checkAssetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      debugPrint('⚠️ Asset not found: $path');
      return false;
    }
  }
}