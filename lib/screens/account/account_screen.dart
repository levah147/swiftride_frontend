// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:swiftride/screens/drivers/become_driver_screen.dart';
// import 'package:swiftride/screens/drivers/driver_verification_screen.dart';
// import 'package:swiftride/services/driver_service.dart';
// import '../../constants/colors.dart';
// import '../../constants/app_strings.dart';
// import '../../constants/app_dimensions.dart';
// import '../../services/auth_service.dart';
// import '../../models/user.dart';
// import '../../widgets/common/menu_item_widget.dart';
// import '../../widgets/common/menu_section_widget.dart';
// import '../../widgets/dialogs/logout_dialog.dart';
// import '../../widgets/dialogs/delete_account_dialog.dart';

// class AccountScreen extends StatefulWidget {
//   final Function(String, {Map<String, dynamic>? data}) onNavigate;
 
//   const AccountScreen({
//     super.key,
//     required this.onNavigate,
//   });

//   @override
//   State<AccountScreen> createState() => _AccountScreenState();
// }

// class _AccountScreenState extends State<AccountScreen> {
//   final AuthService _authService = AuthService();
//   final DriverService _driverService = DriverService();
//   final ImagePicker _imagePicker = ImagePicker();
  
//   User? _user;
//   bool _isLoading = true;
//   bool _isDarkMode = true;
//   bool _isUploadingImage = false;
//   bool _isDriver = false;
//   String? _driverStatus;
//   bool _hasIncompleteVerification = false;
//   String _selectedLanguage = 'English - GB';

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//     _checkDriverStatus();
//   }

//   Future<void> _loadUserProfile() async {
//     if (!mounted) return;
    
//     try {
//       setState(() => _isLoading = true);
      
//       final response = await _authService.getCurrentUser();
      
//       if (!mounted) return;
      
//       if (response.isSuccess && response.data != null) {
//         setState(() {
//           _user = response.data;
//           _isLoading = false;
//         });
//         debugPrint('✅ User loaded: ${_user?.fullName}');
//       } else {
//         setState(() => _isLoading = false);
//         _showErrorSnackBar(response.error ?? 'Failed to load profile');
//         debugPrint('❌ Error loading profile: ${response.error}');
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       _showErrorSnackBar('Error: $e');
//       debugPrint('❌ Exception loading profile: $e');
//     }
//   }

//   Future<void> _checkDriverStatus() async {
//     try {
//       final response = await _driverService.getDriverStatus();
      
//       if (!mounted) return;
      
//       if (response.isSuccess && response.data != null) {
//         final data = response.data as Map<String, dynamic>;
        
//         if (data.containsKey('is_driver') && data['is_driver'] == false) {
//           setState(() {
//             _isDriver = false;
//             _driverStatus = null;
//             _hasIncompleteVerification = false;
//           });
//           debugPrint('ℹ️ User is not a driver yet');
//           return;
//         }
        
//         if (data.containsKey('status')) {
//           setState(() {
//             _isDriver = true;
//             _driverStatus = data['status'];
//           });
//           debugPrint('✅ Driver Status: $_driverStatus');
          
//           // If driver is pending, check if verification is complete
//           if (_driverStatus == 'pending') {
//             _checkVerificationCompletion();
//           }
//         } else {
//           setState(() => _isDriver = false);
//         }
//       } else {
//         setState(() => _isDriver = false);
//         debugPrint('ℹ️ User is not a driver yet (API response not successful)');
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isDriver = false);
//       }
//       debugPrint('ℹ️ User is not a driver: $e');
//     }
//   }

//   Future<void> _checkVerificationCompletion() async {
//     try {
//       final response = await _driverService.getDocumentsStatus();
      
//       if (!mounted) return;
      
//       if (response.isSuccess && response.data != null) {
//         final data = response.data as Map<String, dynamic>;
//         final totalDocs = data['total_documents'] ?? 0;
//         final verifiedDocs = data['verified_documents'] ?? 0;
//         final totalImages = data['total_vehicle_images'] ?? 0;
        
//         // Required: 3 documents (license, registration, insurance) + 2 images (vehicle, driver)
//         // OR accept if user has uploaded something
//         final allDocumentsUploaded = totalDocs >= 3 && totalImages >= 2;
        
//         setState(() {
//           _hasIncompleteVerification = !allDocumentsUploaded;
//         });
        
//         if (!allDocumentsUploaded) {
//           debugPrint('⚠️ Incomplete verification: $totalDocs docs, $totalImages images');
          
//           // Auto-redirect to verification screen
//           Future.delayed(const Duration(milliseconds: 500), () {
//             if (mounted && _hasIncompleteVerification) {
//               _redirectToVerification();
//             }
//           });
//         } else {
//           debugPrint('✅ Verification complete: waiting for admin approval');
//         }
//       }
//     } catch (e) {
//       debugPrint('❌ Error checking verification completion: $e');
//     }
//   }

//   void _redirectToVerification() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.grey[900],
//         title: const Text(
//           'Complete Your Verification',
//           style: TextStyle(color: Colors.white),
//         ),
//         content: const Text(
//           'You have an incomplete driver verification. Please complete uploading all required documents to proceed.',
//           style: TextStyle(color: Colors.grey),
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (context) => const DriverVerificationScreen(),
//                 ),
//               ).then((_) {
//                 _checkDriverStatus();
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.primary,
//             ),
//             child: const Text('Complete Verification'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _pickAndUploadImage() async {
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//       );

//       if (pickedFile != null && mounted) {
//         setState(() => _isUploadingImage = true);
//         debugPrint('📤 Uploading image: ${pickedFile.name}');

//         final response = await _authService.updateProfilePicture(pickedFile.path);

//         if (!mounted) return;

//         if (response.isSuccess && response.data != null) {
//           setState(() {
//             _user = response.data;
//             _isUploadingImage = false;
//           });
//           _showSuccessSnackBar('Profile picture updated successfully');
//           debugPrint('✅ Image uploaded successfully');
//         } else {
//           setState(() => _isUploadingImage = false);
//           _showErrorSnackBar(response.error ?? 'Failed to upload image');
//           debugPrint('❌ Upload error: ${response.error}');
//         }
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isUploadingImage = false);
//       _showErrorSnackBar('Error picking image: $e');
//       debugPrint('❌ Image picker error: $e');
//     }
//   }

//   void _handleLogout() {
//     showDialog(
//       context: context,
//       builder: (_) => LogoutDialog(
//         onConfirm: () async {
//           Navigator.pop(context);
//           await _authService.logout();
//           if (mounted) widget.onNavigate('logout');
//         },
//       ),
//     );
//   }

//   void _handleDeleteAccount() {
//     showDialog(
//       context: context,
//       builder: (_) => DeleteAccountDialog(
//         onConfirm: () async {
//           Navigator.pop(context);
//           setState(() => _isLoading = true);
          
//           final response = await _authService.deleteAccount();
          
//           if (!mounted) return;
          
//           if (response.isSuccess) {
//             await _authService.logout();
//             widget.onNavigate('logout');
//           } else {
//             setState(() => _isLoading = false);
//             _showErrorSnackBar(response.error ?? 'Failed to delete account');
//           }
//         },
//       ),
//     );
//   }

//   void _toggleTheme() {
//     setState(() => _isDarkMode = !_isDarkMode);
//   }

//   void _handleBecomeDriver() {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => const BecomeDriverScreen(),
//       ),
//     ).then((_) {
//       _checkDriverStatus();
//     });
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSuccessSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bgColor = _isDarkMode ? Colors.black : Colors.grey[50];
//     final textColor = _isDarkMode ? Colors.white : Colors.black;
//     final cardColor = _isDarkMode ? Colors.grey[900] : Colors.white;
//     final secondaryText = _isDarkMode ? Colors.grey[400] : Colors.grey[600];

//     return Scaffold(
//       backgroundColor: bgColor,
//       appBar: AppBar(
//         backgroundColor: bgColor,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               AppStrings.account,
//               style: TextStyle(
//                 color: textColor,
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             IconButton(
//               icon: Icon(
//                 _isDarkMode ? Icons.light_mode : Icons.dark_mode,
//                 color: textColor,
//               ),
//               onPressed: _toggleTheme,
//             ),
//           ],
//         ),
//       ),
//       body: _isLoading
//           ? const Center(
//               child: CircularProgressIndicator(color: AppColors.primary),
//             )
//           : RefreshIndicator(
//               onRefresh: _loadUserProfile,
//               color: AppColors.primary,
//               child: SingleChildScrollView(
//                 physics: const AlwaysScrollableScrollPhysics(),
//                 child: Column(
//                   children: [
//                     _buildProfileSection(bgColor, textColor, cardColor, secondaryText),
//                     const SizedBox(height: 24),
//                     _buildMainMenu(textColor, cardColor),
//                     const SizedBox(height: 20),
//                     _buildSavedPlacesSection(textColor, cardColor),
//                     const SizedBox(height: 20),
//                     _buildRideMenu(textColor, cardColor),
//                     const SizedBox(height: 20),
//                     _buildPreferencesSection(textColor, cardColor, secondaryText),
//                     const SizedBox(height: 20),
//                     _buildBecomeDriverCTA(textColor),
//                     const SizedBox(height: 30),
//                     _buildLogoutSection(textColor, cardColor),
//                     const SizedBox(height: 100),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   Widget _buildProfileSection(Color? bgColor, Color? textColor, Color? cardColor, Color? secondaryText) {
//     return Container(
//       color: bgColor,
//       padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//       child: Column(
//         children: [
//           Stack(
//             children: [
//               Container(
//                 width: 100,
//                 height: 100,
//                 decoration: BoxDecoration(
//                   color: cardColor,
//                   borderRadius: BorderRadius.circular(50),
//                   border: Border.all(
//                     color: AppColors.primary,
//                     width: 3,
//                   ),
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.primary.withOpacity(0.3),
//                       blurRadius: 20,
//                       spreadRadius: 2,
//                     ),
//                   ],
//                 ),
//                 child: _user?.profilePictureUrl != null && _user!.profilePictureUrl!.isNotEmpty
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(50),
//                         child: Image.network(
//                           _user!.profilePictureUrl!,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Icon(Icons.person, color: textColor, size: 50);
//                           },
//                           loadingBuilder: (context, child, loadingProgress) {
//                             if (loadingProgress == null) return child;
//                             return Center(
//                               child: CircularProgressIndicator(
//                                 value: loadingProgress.expectedTotalBytes != null
//                                     ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
//                                     : null,
//                               ),
//                             );
//                           },
//                         ),
//                       )
//                     : Icon(Icons.person, color: textColor, size: 50),
//               ),
//               Positioned(
//                 bottom: 0,
//                 right: 0,
//                 child: GestureDetector(
//                   onTap: _isUploadingImage ? null : _pickAndUploadImage,
//                   child: Container(
//                     width: 36,
//                     height: 36,
//                     decoration: BoxDecoration(
//                       color: AppColors.primary,
//                       borderRadius: BorderRadius.circular(18),
//                       border: Border.all(color: bgColor as Color, width: 3),
//                     ),
//                     child: _isUploadingImage
//                         ? const Padding(
//                             padding: EdgeInsets.all(6),
//                             child: CircularProgressIndicator(
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               strokeWidth: 2,
//                             ),
//                           )
//                         : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             _user?.fullName ?? 'User',
//             style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _user?.phoneNumber ?? 'No phone',
//             style: TextStyle(color: secondaryText, fontSize: 14),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Icon(Icons.star, color: AppColors.primary, size: 18),
//                 const SizedBox(width: 6),
//                 Text(
//                   '${_user?.rating.toStringAsFixed(2) ?? '0.0'} • ${_user?.totalRides ?? 0} rides',
//                   style: const TextStyle(
//                     color: AppColors.primary,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMainMenu(Color textColor, Color? cardColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//       child: MenuSectionWidget(
//         backgroundColor: cardColor,
//         items: [
//           MenuItemWidget(
//             icon: Icons.person_outline,
//             title: AppStrings.personalInfo,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.family_restroom,
//             title: AppStrings.familyProfile,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.security,
//             title: AppStrings.safety,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.lock_outline,
//             title: AppStrings.loginAndSecurity,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.privacy_tip_outlined,
//             title: AppStrings.privacy,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSavedPlacesSection(Color textColor, Color? cardColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             AppStrings.savedPlaces,
//             style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           MenuSectionWidget(
//             backgroundColor: cardColor,
//             items: [
//               MenuItemWidget(
//                 icon: Icons.home_outlined,
//                 title: AppStrings.enterHomeLocation,
//                 textColor: textColor,
//                 cardColor: cardColor,
//               ),
//               MenuItemWidget(
//                 icon: Icons.work_outline,
//                 title: AppStrings.enterWorkLocation,
//                 textColor: textColor,
//                 cardColor: cardColor,
//               ),
//               MenuItemWidget(
//                 icon: Icons.add,
//                 title: 'Add a place',
//                 textColor: textColor,
//                 cardColor: cardColor,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRideMenu(Color textColor, Color? cardColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//       child: MenuSectionWidget(
//         backgroundColor: cardColor,
//         items: [
//           MenuItemWidget(
//             icon: Icons.payment,
//             title: AppStrings.payment,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.local_offer_outlined,
//             title: AppStrings.promotions,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.history,
//             title: AppStrings.myRides,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.receipt_long,
//             title: AppStrings.expenseYourRides,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.support_agent,
//             title: AppStrings.support,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.info_outline,
//             title: AppStrings.about,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPreferencesSection(Color textColor, Color? cardColor, Color? secondaryText) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//       child: MenuSectionWidget(
//         backgroundColor: cardColor,
//         items: [
//           MenuItemWidget(
//             icon: Icons.language,
//             title: AppStrings.language,
//             subtitle: _selectedLanguage,
//             textColor: textColor,
//             cardColor: cardColor,
//             subtitleColor: secondaryText,
//           ),
//           MenuItemWidget(
//             icon: Icons.notifications_outlined,
//             title: AppStrings.communicationPreferences,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//           MenuItemWidget(
//             icon: Icons.calendar_today,
//             title: AppStrings.calendars,
//             textColor: textColor,
//             cardColor: cardColor,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBecomeDriverCTA(Color textColor) {
//     if (_isDriver) {
//       if (_hasIncompleteVerification) {
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//           padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.orange.withOpacity(0.8), Colors.orange.withOpacity(0.6)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.orange.withOpacity(0.4),
//                 blurRadius: 15,
//                 spreadRadius: 2,
//               ),
//             ],
//           ),
//           child: const Row(
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Complete Verification',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     SizedBox(height: 4),
//                     Text(
//                       'Upload remaining documents',
//                       style: TextStyle(color: Colors.white70, fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//               Icon(Icons.warning, color: Colors.white, size: 32),
//             ],
//           ),
//         );
//       }

//       return Container(
//         margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//         padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.6)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.green.withOpacity(0.4),
//               blurRadius: 15,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     'Driver Account',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Status: ${_driverStatus?.toUpperCase() ?? 'PENDING'}',
//                     style: const TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(Icons.check_circle, color: Colors.white, size: 32),
//           ],
//         ),
//       );
//     }

//     return GestureDetector(
//       onTap: _handleBecomeDriver,
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//         padding: const EdgeInsets.all(AppDimensions.paddingLarge),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               AppColors.primary,
//               AppColors.primary.withOpacity(0.8),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.primary.withOpacity(0.4),
//               blurRadius: 15,
//               spreadRadius: 2,
//             ),
//           ],
//         ),
//         child: const Row(
//           children: [
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     AppStrings.becomeADriver,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     AppStrings.earnMoneyOnSchedule,
//                     style: TextStyle(color: Colors.white70, fontSize: 14),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.arrow_forward, color: Colors.white),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLogoutSection(Color textColor, Color? cardColor) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
//       child: MenuSectionWidget(
//         backgroundColor: cardColor,
//         items: [
//           MenuItemWidget(
//             icon: Icons.logout,
//             title: AppStrings.logout,
//             textColor: textColor,
//             cardColor: cardColor,
//             onTap: _handleLogout,
//           ),
//           MenuItemWidget(
//             icon: Icons.delete_outline,
//             title: AppStrings.deleteAccount,
//             isDestructive: true,
//             textColor: Colors.red,
//             cardColor: cardColor,
//             onTap: _handleDeleteAccount,
//           ),
//         ],
//       ),
//     );
//   }
// }