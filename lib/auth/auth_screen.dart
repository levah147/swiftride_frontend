import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../constants/app_dimensions.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import 'otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedCountryCode = '+234';
  String _selectedCountryFlag = '🇳🇬';
  String _selectedCountryIso = 'NG';
  bool _isLoading = false;
  bool _isPhoneFocused = false;

  // Rate limiting
  DateTime? _windowStartTime;
  int _otpRequestCount = 0;
  static const int _maxOtpRequestsPerHour = 5;
  static const Duration _rateLimitWindow = Duration(minutes: 15);
  static const Duration _requestCooldown = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Delay system UI update until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateSystemUI();
      }
    });
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _updateSystemUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  // ============================================
  // RATE LIMITING
  // ============================================

  bool _canRequestOtp() {
    final now = DateTime.now();

    if (_windowStartTime == null) {
      _windowStartTime = now;
      _otpRequestCount = 1;
      return true;
    }

    final timeSinceWindowStart = now.difference(_windowStartTime!);

    if (timeSinceWindowStart > _rateLimitWindow) {
      _windowStartTime = now;
      _otpRequestCount = 1;
      return true;
    }

    if (_otpRequestCount >= _maxOtpRequestsPerHour) {
      final remainingTime = _rateLimitWindow - timeSinceWindowStart;
      final remainingMinutes = remainingTime.inMinutes + 1;
      _showError(
        'Too many requests. Please try again in $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}.',
      );
      return false;
    }

    final timeSinceLastRequest = now.difference(_windowStartTime!);
    if (timeSinceLastRequest.inSeconds < _requestCooldown.inSeconds) {
      final secondsToWait =
          _requestCooldown.inSeconds - timeSinceLastRequest.inSeconds;
      _showError(
          'Please wait $secondsToWait seconds before requesting another OTP.');
      return false;
    }

    _otpRequestCount++;
    return true;
  }

  // ============================================
  // PHONE VALIDATION
  // ============================================

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    final digits = _sanitizePhoneNumber(value);

    if (_selectedCountryIso == 'NG') {
      if (digits.length != 10) {
        return 'Nigerian numbers must be 10 digits';
      }

      const validPrefixes = {
        '701', '702', '703', '704', '705', '706', '707', '708', '709',
        '802', '803', '804', '805', '806', '807', '808', '809',
        '810', '811', '812', '813', '814', '815', '816', '817', '818', '819',
        '901', '902', '903', '904', '905', '906', '907',
        '908', '909', '911', '912', '913', '915', '917',
      };

      final prefix = digits.substring(0, 3);
      if (!validPrefixes.contains(prefix)) {
        return 'Invalid Nigerian mobile prefix';
      }

      return null;
    } else {
      if (digits.length < 8) {
        return 'Phone number too short';
      }
      if (digits.length > 15) {
        return 'Phone number too long';
      }
      return null;
    }
  }

  String _sanitizePhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    if (_selectedCountryIso == 'NG') {
      if (cleaned.startsWith('234')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.startsWith('0')) {
        cleaned = cleaned.substring(1);
      }
    }

    return cleaned;
  }

  // ============================================
  // SEND OTP
  // ============================================

  Future<void> _sendOtp() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_canRequestOtp()) {
      return;
    }

    final sanitized = _sanitizePhoneNumber(_phoneController.text.trim());
    final phoneNumber = '$_selectedCountryCode$sanitized';

    setState(() => _isLoading = true);

    try {
      final response = await _authService
          .sendOtp(phoneNumber)
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.isSuccess) {
        debugPrint('✅ OTP sent to $phoneNumber');
        _showSuccess(response.data?['message'] ?? 'OTP sent successfully');

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      } else {
        final errorMessage =
            response.error ?? 'Failed to send OTP. Please try again.';
        _showError(errorMessage);
        debugPrint('❌ OTP send failed: $errorMessage');
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Request timed out. Please check your internet connection.');
      debugPrint('❌ OTP request timeout');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Network error. Please check your connection and try again.');
      debugPrint('❌ OTP send error: $e');
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  void _showError(String message) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onError),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================
  // COUNTRY PICKER
  // ============================================

  void _showCountryPickerDialog() {
    final colorScheme = Theme.of(context).colorScheme;

    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        textStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurface,
        ),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          hintText: 'Start typing to search',
          hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() {
          _selectedCountryCode = '+${country.phoneCode}';
          _selectedCountryFlag = country.flagEmoji;
          _selectedCountryIso = country.countryCode;
          _phoneController.clear();
        });
      },
    );
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ============================================
          // BACKGROUND GRADIENT
          // ============================================
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withOpacity(0.05),
                  colorScheme.primary.withOpacity(0.02),
                  colorScheme.tertiary.withOpacity(0.03),
                ],
              ),
            ),
          ),

          // ============================================
          // FLOATING CIRCLES (DESIGN ELEMENTS)
          // ============================================
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.15),
                    colorScheme.primary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.tertiary.withOpacity(0.1),
                    colorScheme.tertiary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // ============================================
          // MAIN CONTENT
          // ============================================
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * 0.06),

                        // ============================================
                        // ANIMATED LOGO
                        // ============================================
                        Center(
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1)
                                .animate(
                              CurvedAnimation(
                                parent: _animationController,
                                curve: const Interval(0, 0.7,
                                    curve: Curves.elasticOut),
                              ),
                            ),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.7),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        colorScheme.primary.withOpacity(0.4),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_car_rounded,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.06),

                        // ============================================
                        // TITLE
                        // ============================================
                        Text(
                          'Welcome to SwiftRide',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.8,
                            height: 1.2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ============================================
                        // SUBTITLE
                        // ============================================
                        Text(
                          'Your reliable ride, just a tap away',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: size.height * 0.08),

                        // ============================================
                        // FORM CARD
                        // ============================================
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: isDark
                                ? colorScheme.surface.withOpacity(0.8)
                                : Colors.white.withOpacity(0.95),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ============================================
                                  // PHONE LABEL
                                  // ============================================
                                  Text(
                                    'Phone Number',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                      letterSpacing: 0.5,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ============================================
                                  // PHONE INPUT FIELD
                                  // ============================================
                                  TextFormField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    validator: _validatePhoneNumber,
                                    onChanged: (_) {
                                      _formKey.currentState?.validate();
                                    },
                                    onTap: () {
                                      setState(() => _isPhoneFocused = true);
                                    },
                                    onFieldSubmitted: (_) {
                                      setState(() => _isPhoneFocused = false);
                                    },
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '812 345 6789',
                                      hintStyle: TextStyle(
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.4),
                                        fontSize: 16,
                                      ),
                                      filled: true,
                                      fillColor: _isPhoneFocused
                                          ? colorScheme.primary.withOpacity(0.05)
                                          : colorScheme.surfaceVariant
                                              .withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: colorScheme.outline
                                              .withOpacity(0.2),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: colorScheme.primary,
                                          width: 2.5,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: colorScheme.error,
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: colorScheme.error,
                                          width: 2.5,
                                        ),
                                      ),
                                      prefixIcon: InkWell(
                                        onTap: _showCountryPickerDialog,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _selectedCountryFlag,
                                                style: const TextStyle(
                                                    fontSize: 28),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _selectedCountryCode,
                                                style: TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      colorScheme.onSurface,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(
                                                Icons.arrow_drop_down_rounded,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                size: 24,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 18,
                                        horizontal: 16,
                                      ),
                                      errorMaxLines: 2,
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // ============================================
                                  // CONTINUE BUTTON
                                  // ============================================
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          colorScheme.primary,
                                          colorScheme.primary.withOpacity(0.85),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withOpacity(0.3),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _isLoading ? null : _sendOtp,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: SizedBox(
                                          height: 56,
                                          child: Center(
                                            child: _isLoading
                                                ? SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                      valueColor:
                                                          const AlwaysStoppedAnimation<
                                                              Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Continue',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.white,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          width: 12),
                                                      const Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: size.height * 0.06),

                        // ============================================
                        // OR DIVIDER
                        // ============================================
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.outline.withOpacity(0.3),
                                      colorScheme.outline.withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'Or continue with',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      colorScheme.outline.withOpacity(0),
                                      colorScheme.outline.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ============================================
                        // SOCIAL BUTTONS
                        // ============================================
                        Row(
                          children: [
                            Expanded(
                              child: _buildSocialButton(
                                icon: Icons.g_mobiledata,
                                label: 'Google',
                                onPressed: () =>
                                    _showError('Google Sign-In coming soon'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSocialButton(
                                icon: Icons.facebook,
                                label: 'Facebook',
                                onPressed: () =>
                                    _showError('Facebook Sign-In coming soon'),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: size.height * 0.05),

                        // ============================================
                        // TERMS & PRIVACY
                        // ============================================
                        Text.rich(
                          TextSpan(
                            text: 'By signing up, you agree to our ',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.6,
                            ),
                            children: [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: size.height * 0.04),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SOCIAL BUTTON WIDGET
  // ============================================

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
          color: colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorScheme.onSurface,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}