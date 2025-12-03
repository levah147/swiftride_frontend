// ==================== widgets/driver_card_widget.dart ====================
// DRIVER CARD - Driver information display

import 'package:flutter/material.dart';
import '../../../../models/ride.dart';

class DriverCardWidget extends StatelessWidget {
  final Driver driver;
  final int? eta;
  final VoidCallback? onCallTap;
  final VoidCallback? onMessageTap;

  const DriverCardWidget({
    super.key,
    required this.driver,
    this.eta,
    this.onCallTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface, // ✅
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08), // ✅
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Driver photo
              CircleAvatar(
                radius: 30,
                backgroundImage: driver.profileImage != null
                    ? NetworkImage(driver.profileImage!)
                    : null,
                child: driver.profileImage == null
                    ? Text(
                        driver.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

              // Driver info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface, // ✅
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 4),
                        Text(
                          driver.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                             color: colorScheme.onSurfaceVariant, // ✅
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          driver.vehicleModel,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ETA badge
              if (eta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primary, // ✅
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$eta min',
                    style:  TextStyle(
                      color: colorScheme.onPrimary, // ✅
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Vehicle plate
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant, // ✅
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.directions_car, size: 18, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  driver.licensePlate,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface, // ✅
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onMessageTap,
                  icon: const Icon(Icons.message_outlined, size: 18),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onCallTap,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: colorScheme.primary, // ✅
                    foregroundColor: colorScheme.onPrimary, // ✅
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
