import 'package:flutter/material.dart';
import '../../../../../constants/app_dimensions.dart';

/// Driver vehicle information widget
/// Used by: Approved Drivers ONLY
class DriverVehicleInfoWidget extends StatelessWidget {
  final Map<String, dynamic>? driverData;
  final Color textColor;
  final Color? cardColor;
  final bool isDarkMode;

  const DriverVehicleInfoWidget({
    Key? key,
    required this.driverData,
    required this.textColor,
    required this.cardColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vehicleType = driverData?['vehicle_type'] ?? 'Toyota Camry';
    final vehicleColor = driverData?['vehicle_color'] ?? 'Silver';
    final licensePlate = driverData?['license_plate'] ?? 'ABC-123-XYZ';
    final status = driverData?['status_display'] ?? 'Approved';
    final vehicleYear = driverData?['vehicle_year']?.toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Information',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInfoItem(
            'Vehicle Type',
            vehicleType,
            Icons.directions_car,
          ),
          
          _buildInfoItem(
            'Color',
            vehicleColor,
            Icons.palette,
          ),
          
          if (vehicleYear != null)
            _buildInfoItem(
              'Year',
              vehicleYear,
              Icons.calendar_today,
            ),
          
          _buildInfoItem(
            'License Plate',
            licensePlate.toUpperCase(),
            Icons.credit_card,
          ),
          
          _buildInfoItem(
            'Status',
            status,
            Icons.verified,
            statusColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor?.withOpacity(0.1) ?? 
                     (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: statusColor ?? (isDarkMode ? Colors.white70 : Colors.grey[700]),
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
                Row(
                  children: [
                    if (statusColor != null)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: statusColor ?? textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}