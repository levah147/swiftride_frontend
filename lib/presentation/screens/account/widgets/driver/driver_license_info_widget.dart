import 'package:flutter/material.dart';
import '../../../../../constants/app_dimensions.dart';

/// Driver license information widget
/// Used by: Approved Drivers ONLY
class DriverLicenseInfoWidget extends StatelessWidget {
  final Map<String, dynamic>? driverData;
  final Color textColor;
  final Color? cardColor;
  final bool isDarkMode;

  const DriverLicenseInfoWidget({
    Key? key,
    required this.driverData,
    required this.textColor,
    required this.cardColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final licenseNumber = driverData?['driver_license_number'] ?? 'DL-12345-67890';
    final expiryDate = driverData?['driver_license_expiry'] ?? '2026-12-31';
    
    // Check if license is expiring soon (within 3 months)
    final isExpiringSoon = _isExpiringSoon(expiryDate);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver License',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInfoItem(
            'License Number',
            licenseNumber,
            Icons.credit_card,
          ),
          
          _buildInfoItem(
            'Expiry Date',
            _formatDate(expiryDate),
            Icons.calendar_today,
            warning: isExpiringSoon,
          ),
          
          if (isExpiringSoon)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your license is expiring soon. Please renew it.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    bool warning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: warning 
              ? Colors.orange 
              : (isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warning
                  ? Colors.orange.withOpacity(0.1)
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: warning 
                  ? Colors.orange 
                  : (isDarkMode ? Colors.white70 : Colors.grey[700]),
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: warning ? Colors.orange : textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          if (warning)
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 20,
            ),
        ],
      ),
    );
  }

  bool _isExpiringSoon(String expiryDateStr) {
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final now = DateTime.now();
      final difference = expiryDate.difference(now).inDays;
      return difference <= 90 && difference >= 0; // Within 3 months
    } catch (e) {
      return false;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }
}