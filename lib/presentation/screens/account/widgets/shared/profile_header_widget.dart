import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../constants/colors.dart';
import '../../../../../models/user.dart';

/// Profile header widget showing user avatar, name, phone, and basic stats
/// NOW WITH: Edit button + Smart prompt if name is "User"
/// Used by: Riders, Pending Drivers, Approved Drivers
class ProfileHeaderWidget extends StatelessWidget {
  final User? user;
  final VoidCallback onUploadImage;
  final VoidCallback onEditProfile;  // ✅ NEW: Edit profile callback
  final bool isUploadingImage;
  final bool isDarkMode;

  const ProfileHeaderWidget({
    Key? key,
    required this.user,
    required this.onUploadImage,
    required this.onEditProfile,  // ✅ NEW
    required this.isUploadingImage,
    required this.isDarkMode,
  }) : super(key: key);

  /// Check if user has default name
  bool get _hasDefaultName {
    if (user == null) return false;
    
    final firstName = (user!.firstName ?? '').toLowerCase().trim();
    final lastName = (user!.lastName ?? '').toLowerCase().trim();
    
    // Check if name is "User" or empty
    return firstName == 'user' || 
           firstName.isEmpty || 
           (firstName == 'user' && lastName.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Column(
      children: [
        // ✅ NEW: Smart prompt if name is "User"
        if (_hasDefaultName) _buildUpdateNamePrompt(context),
        
        // Main profile card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile Picture
              _buildProfilePicture(),
              
              const SizedBox(height: 16),
              
              // Name with Edit Button
              _buildNameWithEdit(context, textColor),
              
              const SizedBox(height: 8),
              
              // Phone Number
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.phone,
                      size: 16,
                      color: secondaryTextColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user?.phoneNumber ?? '',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // User Stats
              _buildStats(textColor, secondaryTextColor),
            ],
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Update name prompt (shows if name is "User")
  Widget _buildUpdateNamePrompt(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.8),
            Colors.orange.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Update your name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tap the edit icon to set your real name',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEditProfile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ UPDATED: Name with edit button
  Widget _buildNameWithEdit(BuildContext context, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          user?.fullName ?? 'User',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onEditProfile,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.edit,
              size: 18,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        // Avatar with border
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
            backgroundImage: user?.profilePictureUrl != null
                ? CachedNetworkImageProvider(user!.profilePictureUrl!)
                : null,
            child: isUploadingImage
                ? const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 3,
                  )
                : user?.profilePictureUrl == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
                      )
                    : null,
          ),
        ),
        
        // Camera button overlay
        if (!isUploadingImage)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onUploadImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[900]! : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStats(Color textColor, Color? secondaryTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          icon: Icons.star,
          label: 'Rating',
          value: (user?.rating ?? 5.0).toStringAsFixed(1),
          color: Colors.amber,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        Container(
          height: 40,
          width: 1,
          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
        ),
        _buildStatItem(
          icon: Icons.local_taxi,
          label: 'Rides',
          value: '${user?.totalRides ?? 0}',
          color: AppColors.primary,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color textColor,
    required Color? secondaryColor,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }
}