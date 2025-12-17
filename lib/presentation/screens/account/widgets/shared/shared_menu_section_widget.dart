// ==================== shared_menu_section_widget.dart ====================
// FILE LOCATION: lib/presentation/screens/account/widgets/shared/shared_menu_section_widget.dart
//
// Shared menu section showing options available to ALL users
// Used by: Riders, Pending Drivers, AND Approved Drivers
//
// Features:
// - Financial: Wallet, Promotions
// - Activity: My Rides/Trips (smart label)
// - Support: Help, Language, About
//
// Benefits:
// - Consistent feature access across all user types
// - Drivers can manage wallet and get support
// - Pending drivers have features while waiting
// - Clean, organized sections

import 'package:flutter/material.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../constants/app_dimensions.dart';
import '../common/menu_section_widget.dart';
import '../common/menu_item_widget.dart';
import '../../../wallet/wallet_screen.dart';
import '../../../support/support_home_screen.dart';

/// Shared menu section - available to ALL user types
/// This ensures drivers can access wallet, support, and other essential features
class SharedMenuSectionWidget extends StatelessWidget {
  final Color textColor;
  final Color? cardColor;
  final Color? secondaryText;
  final String selectedLanguage;
  final bool isDriver; // Used to determine "My Rides" vs "My Trips"

  const SharedMenuSectionWidget({
    Key? key,
    required this.textColor,
    required this.cardColor,
    required this.secondaryText,
    required this.isDriver,
    this.selectedLanguage = 'English',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ============================================
        // FINANCIAL SECTION
        // ============================================
        _buildSectionHeader(context, 'Financial'),
        
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
          ),
          child: MenuSectionWidget(
            backgroundColor: cardColor,
            items: [
              // Wallet & Payment
              MenuItemWidget(
                icon: Icons.account_balance_wallet,
                title: 'Wallet & Payment',
                subtitle: 'Manage your balance',
                textColor: textColor,
                cardColor: cardColor,
                subtitleColor: secondaryText,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WalletScreen(
                        isDriver: isDriver,
                      ),
                    ),
                  );
                },
              ),
              
              // Promotions & Rewards
              MenuItemWidget(
                icon: Icons.card_giftcard,
                title: 'Promotions & Rewards',
                subtitle: 'Promos, referrals, loyalty',
                textColor: textColor,
                cardColor: cardColor,
                subtitleColor: secondaryText,
                onTap: () {
                  Navigator.pushNamed(context, '/promotions');
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ============================================
        // ACTIVITY SECTION
        // ============================================
        _buildSectionHeader(context, 'Activity'),
        
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
          ),
          child: MenuSectionWidget(
            backgroundColor: cardColor,
            items: [
              // My Rides / My Trips (smart label)
              MenuItemWidget(
                icon: isDriver ? Icons.local_taxi : Icons.history,
                title: isDriver ? 'My Trips' : 'My Rides',
                subtitle: isDriver 
                    ? 'View your driver trips'
                    : 'View your ride history',
                textColor: textColor,
                cardColor: cardColor,
                subtitleColor: secondaryText,
                onTap: () {
                  // Navigate to rides tab (tab index 1)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isDriver
                            ? 'Check the Rides tab for your trip history'
                            : 'Check the Rides tab for your ride history',
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ============================================
        // SUPPORT & SETTINGS SECTION
        // ============================================
        _buildSectionHeader(context, 'Support & Settings'),
        
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingLarge,
          ),
          child: MenuSectionWidget(
            backgroundColor: cardColor,
            items: [
              // Support & Help
              MenuItemWidget(
                icon: Icons.support_agent,
                title: 'Support & Help',
                subtitle: 'Get assistance',
                textColor: textColor,
                cardColor: cardColor,
                subtitleColor: secondaryText,
                onTap: () {
                  Navigator.pushNamed(context, '/support');
                },
              ),
              
              // Language
              MenuItemWidget(
                icon: Icons.language,
                title: 'Language',
                subtitle: selectedLanguage,
                textColor: textColor,
                cardColor: cardColor,
                subtitleColor: secondaryText,
                onTap: () {
                  Navigator.pushNamed(context, '/settings/language');
                },
              ),
              
              // About
              MenuItemWidget(
                icon: Icons.info_outline,
                title: 'About SwiftRide',
                subtitle: 'App information',
                textColor: textColor,
                cardColor: cardColor,
                subtitleColor: secondaryText,
                onTap: () {
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build section header with title
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingLarge + 4,
        0,
        AppDimensions.paddingLarge,
        12,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              color: secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: secondaryText?.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  /// Show about dialog
  void _showAboutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'About SwiftRide',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SwiftRide',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: secondaryText),
            ),
            const SizedBox(height: 16),
            Text(
              'Your reliable ride-hailing service',
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2024 SwiftRide. All rights reserved.',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}