// ==================== widgets/vehicle_card_widget.dart ====================
// VEHICLE CARD - Individual vehicle selection card

import 'package:flutter/material.dart';
import '../../../../models/vehicle_type.dart';

class VehicleCardWidget extends StatelessWidget {
  final VehicleType vehicle;
  final bool isSelected;
  final VoidCallback onTap;

  const VehicleCardWidget({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Vehicle icon/image
            Row(
              children: [
                Icon(
                  _getVehicleIcon(vehicle.name),
                  size: 32,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                const Spacer(),
                if (vehicle.capacity > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${vehicle.capacity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Vehicle name
            Text(
              vehicle.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Price info
            Row(
              children: [
                if (vehicle.surgeMultiplier > 1.0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '${vehicle.surgeMultiplier}x',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  '₦${vehicle.baseFare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('bike') || lowerName.contains('motor')) {
      return Icons.two_wheeler;
    } else if (lowerName.contains('xl') || lowerName.contains('suv')) {
      return Icons.airport_shuttle;
    } else if (lowerName.contains('comfort')) {
      return Icons.drive_eta;
    } else if (lowerName.contains('premium')) {
      return Icons.airport_shuttle;
    }
    return Icons.directions_car;
  }
}