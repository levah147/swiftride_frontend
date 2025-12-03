// ==================== widgets/vehicle_selector_widget.dart ====================
// VEHICLE SELECTOR - Horizontal scrolling vehicle cards

import 'package:flutter/material.dart';
import '../../../../models/vehicle_type.dart';
import '../../ride_booking/widgets/vehicle_card_widget.dart';

class VehicleSelectorWidget extends StatelessWidget {
  final List<VehicleType> vehicles;
  final VehicleType? selectedVehicle;
  final Function(VehicleType) onVehicleSelected;
  final bool isLoading;

  const VehicleSelectorWidget({
    super.key,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleSelected,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (vehicles.isEmpty) {
      return Center(
        child: Text(
          'No vehicles available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          final vehicle = vehicles[index];
          final isSelected = selectedVehicle?.id == vehicle.id;
          
          return Padding(
            padding: EdgeInsets.only(
              right: index < vehicles.length - 1 ? 12 : 0,
            ),
            child: VehicleCardWidget(
              vehicle: vehicle,
              isSelected: isSelected,
              onTap: () => onVehicleSelected(vehicle),
            ),
          );
        },
      ),
    );
  }
}