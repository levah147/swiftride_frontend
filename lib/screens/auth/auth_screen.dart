// ==================== auth_screen.dart ====================
// THEME-AWARE AUTH SCREEN
// Automatically adapts to light/dark mode

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../../constants/app_dimensions.dart';
import '../../services/auth_service.dart';
import 'otp_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedCountryCode = '+234';
  String _selectedCountryFlag = '🇳🇬';
  String _selectedCountryIso = 'NG';
  bool _isLoading = false;

  // Rate limiting
  DateTime? _lastOtpRequest;
  int _otpRequestCount = 0;
  static const int _maxOtpRequestsPerHour = 5;
  static const Duration _rateLimitWindow = Duration(minutes: 15);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================
  // RATE LIMITING
  // ============================================

  bool _canRequestOtp() {
    if (_lastOtpRequest == null) return true;

    final timeSinceLastRequest = DateTime.now().difference(_lastOtpRequest!);

    // Reset counter after rate limit window
    if (timeSinceLastRequest > _rateLimitWindow) {
      _otpRequestCount = 0;
      return true;
    }

    // Check if exceeded max requests
    if (_otpRequestCount >= _maxOtpRequestsPerHour) {
      final remainingTime = _rateLimitWindow - timeSinceLastRequest;
      final minutes = remainingTime.inMinutes;
      _showError('Too many requests. Please try again in $minutes minutes.');
      return false;
    }

    // Require minimum 30 seconds between requests
    if (timeSinceLastRequest.inSeconds < 30) {
      _showError('Please wait 30 seconds before requesting another OTP.');
      return false;
    }

    return true;
  }

  // ============================================
  // PHONE VALIDATION
  // ============================================

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove spaces, dashes, parentheses, etc.
    String digits = value.replaceAll(RegExp(r'[^0-9+]'), '');

    // Normalize Nigerian numbers
    if (_selectedCountryIso == 'NG') {
      // Handle +234 or 234
      if (digits.startsWith('+234')) {
        digits = digits.substring(4);
      } else if (digits.startsWith('234')) {
        digits = digits.substring(3);
      } else if (digits.startsWith('0')) {
        digits = digits.substring(1);
      }

      // Now we should have 10 digits left
      if (digits.length != 10) {
        return 'Please enter a valid 10-digit Nigerian number';
      }

      // Valid prefixes in Nigeria
      final validPrefixes = [
        '701', '703', '704', '705', '706', '707', '708', '709',
        '802', '803', '804', '805', '806', '807', '808', '809',
        '810', '811', '812', '813', '814', '815', '816', '817',
        '818', '819', '909', '908', '901', '902', '903', '904',
        '905', '906', '907', '915', '913', '912', '911', '917',
      ];

      final prefix = digits.substring(0, 3);

      if (!validPrefixes.contains(prefix)) {
        return 'Please enter a valid Nigerian mobile number';
      }
    } else {
      // For other countries, just basic check
      if (digits.length < 8) {
        return 'Please enter a valid phone number';
      }
    }

    return null;
  }

  String _sanitizePhoneNumber(String input) {
    // Remove all non-digit characters
    String digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Remove leading 0
    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    // Remove country code if included
    String countryDigits = _selectedCountryCode.replaceAll('+', '');
    if (digits.startsWith(countryDigits)) {
      digits = digits.substring(countryDigits.length);
    }

    return digits;
  }

  // ============================================
  // SEND OTP
  // ============================================

  Future<void> _sendOtp() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check rate limiting
    if (!_canRequestOtp()) {
      return;
    }

    final sanitized = _sanitizePhoneNumber(_phoneController.text.trim());
    final phoneNumber = '$_selectedCountryCode$sanitized';

    setState(() => _isLoading = true);

    try {
      final response = await _authService.sendOtp(phoneNumber);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.isSuccess) {
        // Update rate limiting
        _lastOtpRequest = DateTime.now();
        _otpRequestCount++;

        _showSuccess(response.data?['message'] ?? 'OTP sent successfully');

        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber: phoneNumber,
            ),
          ),
        );
      } else {
        _showError(response.error ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Network error. Please check your connection and try again.');
      debugPrint('OTP send error: $e');
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  void _showError(String message) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    
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
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    
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
  // COUNTRY PICKER
  // ============================================

  void _showCountryPickerDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
          top: Radius.circular(24),
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),

                // ============================================
                // LOGO & TITLE
                // ============================================
                Center(
                  child: Container(
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
                ),

                const SizedBox(height: 32),

                Text(
                  'Welcome to SwiftRide',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Enter your phone number to get started',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 48),

                // ============================================
                // PHONE NUMBER FORM
                // ============================================
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '812 345 6789',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? colorScheme.surfaceVariant
                              : colorScheme.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 1,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: colorScheme.error,
                              width: 2,
                            ),
                          ),
                          prefixIcon: InkWell(
                            onTap: _showCountryPickerDialog,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountryFlag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedCountryCode,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ============================================
                      // CONTINUE BUTTON
                      // ============================================
                      SizedBox(
                        height: AppDimensions.buttonHeightLarge,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ============================================
                      // DIVIDER
                      // ============================================
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: colorScheme.outline,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or continue with',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: colorScheme.outline,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ============================================
                      // SOCIAL BUTTONS
                      // ============================================
                      _buildSocialButton(
                        icon: Icons.g_mobiledata,
                        text: 'Continue with Google',
                        onPressed: () => _showError('Google Sign-In coming soon'),
                      ),

                      const SizedBox(height: 12),

                      _buildSocialButton(
                        icon: Icons.facebook,
                        text: 'Continue with Facebook',
                        onPressed: () => _showError('Facebook Sign-In coming soon'),
                      ),

                      const SizedBox(height: 32),

                      // ============================================
                      // TERMS & PRIVACY
                      // ============================================
                      Text.rich(
                        TextSpan(
                          text: 'By signing up, you agree to our ',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // SOCIAL BUTTON WIDGET
  // ============================================

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: AppDimensions.buttonHeightMedium,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: colorScheme.outline,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
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