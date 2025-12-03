import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:swiftride/routes/app_routes.dart';
import 'package:swiftride/routes/route_arguments.dart';
import '../../../../../constants/app_dimensions.dart';
import '../../../../../models/vehicle_type.dart';
import 'driver_matching_screen.dart';

class RideOptionsScreen extends StatefulWidget {
  final String from;
  final String to;
  final bool isScheduled;
  final String? city;

  const RideOptionsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.isScheduled,
    this.city,
  });

  @override
  State<RideOptionsScreen> createState() => _RideOptionsScreenState();
}

class _RideOptionsScreenState extends State<RideOptionsScreen> {
  int _selectedIndex = 0;
  late List<VehicleType> _availableVehicles;
  double _estimatedDistance = 5.2;
  bool _isLoadingFare = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableVehicles();
    _calculateFares();
  }

  void _loadAvailableVehicles() {
    final city = widget.city ?? 'Makurdi';
    setState(() {
      _availableVehicles = VehicleTypes.getVehiclesForCity(city);
    });
  }

  Future<void> _calculateFares() async {
    setState(() => _isLoadingFare = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoadingFare = false);
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 Get theme colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose a ride',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildRouteSummary(colorScheme),
          const SizedBox(height: 16),
          _buildTripInfo(colorScheme),
          const SizedBox(height: 24),
          Expanded(
            child: _buildVehicleList(colorScheme),
          ),
          _buildBookButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildRouteSummary(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingLarge),
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: colorScheme.onSurfaceVariant,
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.from,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.to,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          if (widget.isScheduled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    color: colorScheme.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Scheduled',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripInfo(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      child: Row(
        children: [
          _buildInfoChip(
            icon: Icons.straighten,
            label: '${_estimatedDistance.toStringAsFixed(1)} km',
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.access_time,
            label: '${(_estimatedDistance * 3).toInt()} min',
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(ColorScheme colorScheme) {
    if (_isLoadingFare) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
      itemCount: _availableVehicles.length,
      itemBuilder: (context, index) {
        final vehicle = _availableVehicles[index];
        final isSelected = _selectedIndex == index;
        final fare = vehicle.calculateFare(_estimatedDistance);
        
        return GestureDetector(
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? vehicle.color.withOpacity(0.1) 
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? vehicle.color : colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: vehicle.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    vehicle.icon,
                    color: vehicle.color,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vehicle.name,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: vehicle.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'SELECTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${vehicle.description} • ${vehicle.estimatedTime}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      vehicle.formatPrice(fare),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: vehicle.color,
                        size: 20,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookButton(ColorScheme colorScheme) {
    final selectedVehicle = _availableVehicles[_selectedIndex];
    final fare = selectedVehicle.calculateFare(_estimatedDistance);
    
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLarge),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cash',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: AppDimensions.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.driverMatching,
                    arguments: DriverMatchingArguments(
                      rideId: 'ride-${DateTime.now().millisecondsSinceEpoch}',
                      from: LatLng(0, 0),
                      to: widget.to,
                      rideType: {
                        'id': selectedVehicle.id,
                        'name': selectedVehicle.name,
                        'price': selectedVehicle.formatPrice(fare),
                        'icon': selectedVehicle.icon,
                        'color': selectedVehicle.color,
                      },
                      isScheduled: widget.isScheduled,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedVehicle.color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.isScheduled 
                          ? 'Schedule ${selectedVehicle.name}' 
                          : 'Book ${selectedVehicle.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${selectedVehicle.formatPrice(fare)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}