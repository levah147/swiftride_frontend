import 'package:flutter/material.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../constants/app_dimensions.dart';
import '../../../../../widgets/common/menu_section_widget.dart';
import '../../../../../widgets/common/menu_item_widget.dart';

/// Account actions widget showing logout and delete account options
/// Used by: ALL users (Riders and Drivers)
class AccountActionsWidget extends StatelessWidget {
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final Color textColor;
  final Color? cardColor;
  final bool isDarkMode;

  const AccountActionsWidget({
    Key? key,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.textColor,
    required this.cardColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: MenuSectionWidget(
        backgroundColor: cardColor,
        items: [
          MenuItemWidget(
            icon: Icons.logout,
            title: AppStrings.logout,
            textColor: textColor,
            cardColor: cardColor,
            onTap: () => _showLogoutDialog(context),
          ),
          MenuItemWidget(
            icon: Icons.delete_outline,
            title: AppStrings.deleteAccount,
            isDestructive: true,
            textColor: Colors.red,
            cardColor: cardColor,
            onTap: () => _showDeleteDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          '⚠️ Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'All your data will be permanently deleted:',
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ..._buildDeleteItems(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete Forever',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeleteItems() {
    final items = [
      '• Profile & personal info',
      '• Ride history',
      '• Payment methods',
      '• Saved locations',
      '• All preferences',
    ];

    return items.map((item) => Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        item,
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 13,
        ),
      ),
    )).toList();
  }
}