// ==================== account_screen.dart ====================
// FILE LOCATION: lib/presentation/screens/account/account_screen.dart
//
// Unified Account Screen - adapts based on user role
// NOW WITH: Shared menu for ALL users (riders, pending drivers, approved drivers)
//
// User Flows:
// - RIDERS: Profile + Shared Menu + Become Driver CTA + Actions
// - PENDING DRIVERS: Profile + Status Badge + Shared Menu + Actions
// - APPROVED DRIVERS: Profile + Stats + Vehicle + License + Shared Menu + Actions
//
// Changes from previous version:
// ✅ All users can access wallet, promotions, support, language
// ✅ Drivers can now manage finances and get help
// ✅ Pending drivers have features while waiting
// ✅ Removed unnecessary placeholders (Expense, Communication, Calendars)
// ✅ Smart label: "My Rides" for riders, "My Trips" for drivers

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swiftride/presentation/screens/drivers/verification/become_driver_screen.dart';
import 'package:swiftride/presentation/screens/drivers/verification/driver_verification_screen.dart'; 
import '../../../constants/colors.dart';
import '../../../constants/app_strings.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_service.dart';
import '../../../services/language_service.dart';
import '../../../models/user.dart';
import '../../../theme/providers/theme_provider.dart';

// Import widgets
import 'widgets/shared/profile_header_widget.dart';
import 'widgets/shared/account_actions_widget.dart';
import 'widgets/shared/shared_menu_section_widget.dart'; // ✅ NEW: Shared menu
import 'widgets/rider/become_driver_cta_widget.dart';

import 'widgets/driver/driver_vehicle_info_widget.dart';
import 'widgets/driver/driver_license_info_widget.dart';
import 'widgets/driver/driver_status_badge_widget.dart';
import 'widgets/dialogs/edit_profile_dialog.dart';

/// Unified Account Screen - adapts based on user role
/// NOW WITH: Complete feature access for all user types
class AccountScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;

  const AccountScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final DriverService _driverService = DriverService();
  final ImagePicker _imagePicker = ImagePicker();

  // State variables
  User? _user;
  bool _isLoading = true;
  bool _isUploadingImage = false;
  bool _isDriver = false;
  String? _driverStatus;
  bool _hasIncompleteVerification = false;
  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkDriverStatus();
  }

  // ============================================
  // DATA LOADING
  // ============================================

  Future<void> _loadUserProfile() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      final response = await _authService.getCurrentUser();

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _user = response.data;
          _isLoading = false;
        });
        debugPrint('✅ User loaded: ${_user?.fullName}');
      } else {
        setState(() => _isLoading = false);
        _showErrorSnackBar(response.error ?? 'Failed to load profile');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _checkDriverStatus() async {
    try {
      final response = await _driverService.getDriverStatus();

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Check if user is a driver
        if (data.containsKey('is_driver') && data['is_driver'] == false) {
          setState(() {
            _isDriver = false;
            _driverStatus = null;
            _hasIncompleteVerification = false;
          });
          debugPrint('ℹ️ User is not a driver yet');
          return;
        }

        // Check for status INSIDE the 'driver' object
        if (data.containsKey('driver') && data['driver'] != null) {
          final driverData = data['driver'] as Map<String, dynamic>;
          
          if (driverData.containsKey('status')) {
            final status = driverData['status'] as String;
            
            setState(() {
              _isDriver = true;
              _driverStatus = status;
            });
            
            debugPrint('✅ Driver Status: $_driverStatus');

            // If pending, check verification
            if (_driverStatus == 'pending') {
              _checkVerificationCompletion();
            }

            // If approved, load full driver data
            if (_driverStatus == 'approved') {
              _loadDriverProfile();
            }
            return;
          }
        }
        
        // If we get here, treat as non-driver
        setState(() {
          _isDriver = false;
          _driverStatus = null;
          _hasIncompleteVerification = false;
        });
      } else {
        setState(() => _isDriver = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDriver = false);
      }
      debugPrint('ℹ️ User is not a driver: $e');
    }
  }

  Future<void> _checkVerificationCompletion() async {
    try {
      final response = await _driverService.getDocumentsStatus();

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final totalDocs = data['total_documents'] ?? 0;
        final totalImages = data['total_vehicle_images'] ?? 0;

        // Required: 3 documents + 2 images
        final allDocumentsUploaded = totalDocs >= 3 && totalImages >= 2;

        setState(() {
          _hasIncompleteVerification = !allDocumentsUploaded;
        });

        if (!allDocumentsUploaded) {
          debugPrint('⚠️ Incomplete verification: $totalDocs docs, $totalImages images');
        } else {
          debugPrint('✅ Verification complete: waiting for admin approval');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking verification: $e');
    }
  }

  Future<void> _loadDriverProfile() async {
    try {
      final response = await _driverService.getDriverProfile();

      if (!mounted) return;

      if (response.isSuccess && response.data != null) {
        setState(() {
          _driverData = response.data as Map<String, dynamic>;
        });
        debugPrint('✅ Driver profile loaded');
      }
    } catch (e) {
      debugPrint('❌ Error loading driver profile: $e');
    }
  }

  // ============================================
  // IMAGE UPLOAD
  // ============================================

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        setState(() => _isUploadingImage = true);

        final response = await _authService.updateProfilePicture(pickedFile.path);

        if (!mounted) return;

        if (response.isSuccess && response.data != null) {
          setState(() {
            _user = response.data;
            _isUploadingImage = false;
          });
          _showSuccessSnackBar('Profile picture updated successfully');
        } else {
          setState(() => _isUploadingImage = false);
          _showErrorSnackBar(response.error ?? 'Failed to upload image');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  // ============================================
  // PROFILE EDITING
  // ============================================

  void _handleEditProfile() {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        currentUser: _user!,
        onProfileUpdated: (updatedUser) {
          setState(() {
            _user = updatedUser;
          });
        },
      ),
    );
  }

  // ============================================
  // NAVIGATION HANDLERS
  // ============================================

  void _handleBecomeDriver() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BecomeDriverScreen()),
    );
  }

  void _handleCompleteVerification() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DriverVerificationScreen(),
      ),
    );
  }

  // ============================================
  // ACCOUNT ACTIONS
  // ============================================

  void _handleLogout() async {
    try {
      debugPrint('🚪 Logging out...');
      
      final response = await _authService.logout();
      
      if (response.isSuccess) {
        debugPrint('✅ Logout successful');
      } else {
        debugPrint('⚠️ Logout response: ${response.error}');
      }
      
      // Navigate to auth screen regardless of response
      if (mounted) {
        widget.onNavigate('logout');
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      if (mounted) {
        widget.onNavigate('logout');
      }
    }
  }

  void _handleDeleteAccount() async {
    try {
      debugPrint('🗑️ Deleting account...');
      
      final response = await _authService.deleteAccount();
      
      if (mounted) {
        if (response.isSuccess) {
          debugPrint('✅ Account deleted successfully');
          _showSuccessSnackBar('Account deleted successfully');
          
          await Future.delayed(const Duration(milliseconds: 500));
          widget.onNavigate('logout');
        } else {
          debugPrint('❌ Delete account failed: ${response.error}');
          _showErrorSnackBar(response.error ?? 'Failed to delete account');
        }
      }
    } catch (e) {
      debugPrint('❌ Delete account error: $e');
      if (mounted) {
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  // ============================================
  // UI HELPERS
  // ============================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    // Get theme from provider
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Get language service
    final languageService = Provider.of<LanguageService>(context);
    final currentLanguage = languageService.getCurrentLanguage().name;
    
    // Use theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.account,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: isDarkMode ? 'Light Mode' : 'Dark Mode',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                await _loadUserProfile();
                await _checkDriverStatus();
              },
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    
                    // ========================================
                    // PROFILE HEADER (ALL USERS)
                    // ========================================
                    ProfileHeaderWidget(
                      user: _user,
                      onUploadImage: _pickAndUploadImage,
                      onEditProfile: _handleEditProfile,
                      isUploadingImage: _isUploadingImage,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 24),

                    // ========================================
                    // DRIVER-SPECIFIC CONTENT
                    // ========================================
                    
                    // Pending Driver: Status Badge
                    if (_isDriver && _driverStatus == 'pending')
                      ..._buildPendingDriverContent(),
                    
                    // Approved Driver: Stats + Vehicle + License
                    if (_isDriver && _driverStatus == 'approved')
                      ..._buildApprovedDriverContent(colorScheme, isDarkMode),

                    // ========================================
                    // SHARED MENU (ALL USERS) ✅ NEW!
                    // ========================================
                    SharedMenuSectionWidget(
                      textColor: colorScheme.onSurface,
                      cardColor: colorScheme.surface,
                      secondaryText: colorScheme.onSurfaceVariant,
                      selectedLanguage: currentLanguage,
                      isDriver: _isDriver, // Smart "My Rides" vs "My Trips"
                    ),

                    const SizedBox(height: 24),

                    // ========================================
                    // BECOME DRIVER CTA (RIDERS ONLY)
                    // ========================================
                    if (!_isDriver)
                      BecomeDriverCTAWidget(
                        onTap: _handleBecomeDriver,
                      ),

                    const SizedBox(height: 24),

                    // ========================================
                    // ACCOUNT ACTIONS (ALL USERS)
                    // ========================================
                    AccountActionsWidget(
                      onLogout: _handleLogout,
                      onDeleteAccount: _handleDeleteAccount,
                      textColor: colorScheme.onSurface,
                      cardColor: colorScheme.surface,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================
  // CONTENT BUILDERS
  // ============================================

  /// Content for Pending Drivers
  List<Widget> _buildPendingDriverContent() {
    debugPrint('⏳ Building PENDING DRIVER content');
    return [
      // Status badge
      DriverStatusBadgeWidget(
        status: _driverStatus!,
        hasIncompleteVerification: _hasIncompleteVerification,
        onCompleteVerification: _hasIncompleteVerification 
            ? _handleCompleteVerification 
            : null,
      ),
      const SizedBox(height: 24),
    ];
  }

  /// Content for Approved Drivers
  List<Widget> _buildApprovedDriverContent(
    ColorScheme colorScheme,
    bool isDarkMode,
  ) {
    debugPrint('🚗 Building APPROVED DRIVER content');
    
    return [


      const SizedBox(height: 24),

      // Vehicle information
      DriverVehicleInfoWidget(
        driverData: _driverData,
        textColor: colorScheme.onSurface,
        cardColor: colorScheme.surface,
        isDarkMode: isDarkMode,
      ),

      const SizedBox(height: 24),

      // License information
      DriverLicenseInfoWidget(
        driverData: _driverData,
        textColor: colorScheme.onSurface,
        cardColor: colorScheme.surface,
        isDarkMode: isDarkMode,
      ),

      const SizedBox(height: 24),
    ];
  }
}