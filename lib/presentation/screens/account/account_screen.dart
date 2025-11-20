import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swiftride/screens/drivers/become_driver_screen.dart';
import 'package:swiftride/screens/drivers/driver_verification_screen.dart';
import 'package:swiftride/presentation/screens/account/widgets/dialogs/edit_profile_dialog.dart';
import '../../../constants/colors.dart';
import '../../../constants/app_strings.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_service.dart';
import '../../../models/user.dart';
import '../../../theme/providers/theme_provider.dart';

// Import widgets
import 'widgets/shared/profile_header_widget.dart';
import 'widgets/shared/account_actions_widget.dart';
import 'widgets/rider/rider_menu_section_widget.dart';
import 'widgets/rider/become_driver_cta_widget.dart';
import 'widgets/driver/driver_stats_card_widget.dart';
import 'widgets/driver/driver_vehicle_info_widget.dart';
import 'widgets/driver/driver_license_info_widget.dart';
import 'widgets/driver/driver_status_badge_widget.dart';
import 'widgets/dialogs/edit_profile_dialog.dart';  // ✅ NEW

/// Unified Account Screen - adapts based on user role (Rider, Pending Driver, Approved Driver)
/// NOW WITH: Profile editing functionality
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
  String _selectedLanguage = 'English - GB';

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
        debugPrint('📊 Driver Data: $_driverData');
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
  // PROFILE EDITING (✅ NEW)
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
          debugPrint('✅ Profile updated in UI: ${updatedUser.fullName}');
        },
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _handleBecomeDriver() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BecomeDriverScreen(),
      ),
    ).then((_) {
      // Refresh status after returning
      _checkDriverStatus();
    });
  }

  void _handleCompleteVerification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DriverVerificationScreen(),
      ),
    ).then((_) {
      // Refresh status after returning
      _checkDriverStatus();
    });
  }

  void _handleLogout() async {
    try {
      debugPrint('🚪 Logging out...');
      
      // Call backend logout (returns ApiResponse<void>)
      final response = await _authService.logout();
      
      if (response.isSuccess) {
        debugPrint('✅ Logout successful');
      } else {
        debugPrint('⚠️ Logout response: ${response.error}');
      }
      
      // Navigate to auth screen regardless of response
      // (tokens are cleared locally either way)
      if (mounted) {
        widget.onNavigate('logout');
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      // Still navigate even if error (token cleared locally)
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
          
          // Wait a moment for user to see the message
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Navigate to login
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
    
    // Use theme colors from context
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
          // Theme toggle button connected to provider
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              // Toggle theme through provider
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
                    
                    // SHARED: Profile Header (EVERYONE) - ✅ NOW WITH EDIT
                    ProfileHeaderWidget(
                      user: _user,
                      onUploadImage: _pickAndUploadImage,
                      onEditProfile: _handleEditProfile,  // ✅ NEW
                      isUploadingImage: _isUploadingImage,
                      isDarkMode: isDarkMode,
                    ),

                    const SizedBox(height: 24),

                    // ADAPTIVE CONTENT based on driver status
                    if (!_isDriver) ..._buildRiderContent(colorScheme),
                    if (_isDriver && _driverStatus == 'pending') ..._buildPendingDriverContent(),
                    if (_isDriver && _driverStatus == 'approved') ..._buildApprovedDriverContent(colorScheme),

                    const SizedBox(height: 24),

                    // SHARED: Account Actions (EVERYONE)
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

  /// Content for Riders (non-drivers)
  List<Widget> _buildRiderContent(ColorScheme colorScheme) {
    debugPrint('🏍️ Building RIDER content');
    return [
      // Rider menu items
      RiderMenuSectionWidget(
        textColor: colorScheme.onSurface,
        cardColor: colorScheme.surface,
        secondaryText: colorScheme.onSurfaceVariant,
        selectedLanguage: _selectedLanguage,
      ),

      const SizedBox(height: 24),

      // Become Driver CTA
      BecomeDriverCTAWidget(
        onTap: _handleBecomeDriver,
      ),
    ];
  }

  /// Content for Pending Drivers
  List<Widget> _buildPendingDriverContent() {
    debugPrint('⏳ Building PENDING DRIVER content');
    return [
      // Status badge
      DriverStatusBadgeWidget(
        status: _driverStatus!,
        hasIncompleteVerification: _hasIncompleteVerification,
        onCompleteVerification: _hasIncompleteVerification ? _handleCompleteVerification : null,
      ),
    ];
  }

  /// Content for Approved Drivers
  List<Widget> _buildApprovedDriverContent(ColorScheme colorScheme) {
    debugPrint('🚗 Building APPROVED DRIVER content');
    debugPrint('📊 Driver data available: ${_driverData != null}');
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return [
      // Driver stats card
      DriverStatsCardWidget(
        driverData: _driverData,
        isDarkMode: isDarkMode,
      ),

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
    ];
  }
}