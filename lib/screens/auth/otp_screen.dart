// ==================== otp_screen.dart ====================
// THEME-AWARE OTP VERIFICATION SCREEN
// Automatically adapts to light/dark mode

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swiftride/screens/main/main_navigation_screen.dart';
import '../../services/auth_service.dart';

class OTPScreen extends StatefulWidget {
  final String phoneNumber;

  const OTPScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  final AuthService _authService = AuthService();

  bool _isVerifying = false;
  bool _canResend = false;
  int _resendTimer = 60;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================
  // TIMER
  // ============================================

  void _startResendTimer() async {
    setState(() => _canResend = false);
    for (int i = 60; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendTimer = i);
    }
    setState(() => _canResend = true);
  }

  // ============================================
  // OTP INPUT HANDLING
  // ============================================

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    bool filled = _controllers.every((c) => c.text.isNotEmpty);
    if (filled) {
      FocusScope.of(context).unfocus();
      _verifyOTP();
    }
  }

  // ============================================
  // VERIFY OTP
  // ============================================

  Future<void> _verifyOTP() async {
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _showError('Please enter complete OTP');
      return;
    }
    
    setState(() => _isVerifying = true);
    
    try {
      final res = await _authService.verifyOtp(widget.phoneNumber, otp);
      
      if (!mounted) return;
      
      setState(() => _isVerifying = false);
      
      if (res.isSuccess) {
        _showSuccess('Welcome to SwiftRide!');
        
        // Navigate to home
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;
        
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (_) => false,
        );
      } else {
        _showError(res.error ?? 'Invalid OTP');
        for (var c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _showError('Network error. Please try again.');
      debugPrint('OTP verify error: $e');
    }
  }

  // ============================================
  // RESEND OTP
  // ============================================

  Future<void> _resendOTP() async {
    if (!_canResend) return;
    
    setState(() {
      _resendTimer = 60;
    });
    _startResendTimer();
    
    try {
      final res = await _authService.sendOtp(widget.phoneNumber);
      
      if (!mounted) return;
      
      if (res.isSuccess) {
        _showSuccess(res.data?['message'] ?? 'New OTP sent successfully');
      } else {
        _showError(res.error ?? 'Failed to resend OTP');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Network error. Please try again.');
      debugPrint('OTP resend error: $e');
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  void _showError(String msg) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(color: colorScheme.onError),
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF10B981), // Success green
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Update system UI based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: FadeTransition(
        opacity: _fadeController,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ============================================
                // BACK BUTTON
                // ============================================
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),

                // ============================================
                // LOGO
                // ============================================
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                
                const SizedBox(height: 16),

                // ============================================
                // TITLE
                // ============================================
                Text(
                  "SwiftRide",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.0,
                  ),
                ),

                const SizedBox(height: 8),
                
                Text(
                  "Enter the 6-digit code sent to\n${widget.phoneNumber}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                // ============================================
                // OTP INPUT BOXES
                // ============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 45,
                      height: 55,
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceVariant
                            : colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _focusNodes[index].hasFocus
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: _focusNodes[index].hasFocus ? 2 : 1,
                        ),
                        boxShadow: _focusNodes[index].hasFocus
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (val) => _onCodeChanged(val, index),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 40),

                // ============================================
                // VERIFYING STATE
                // ============================================
                if (_isVerifying)
                  Column(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Verifying...",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 40),

                // ============================================
                // RESEND BUTTON / TIMER
                // ============================================
                _canResend
                    ? TextButton(
                        onPressed: _resendOTP,
                        child: Text(
                          "Resend code",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : Text(
                        "Resend code in $_resendTimer s",
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}