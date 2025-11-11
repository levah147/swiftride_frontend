// ==================== rides_screen.dart ====================
import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/app_strings.dart';
import '../../constants/app_dimensions.dart';
import '../../services/ride_service.dart';
import '../../models/ride.dart';
import '../../widgets/ride_cards/upcoming_ride_card.dart';
import '../../widgets/ride_cards/past_ride_card.dart';

class RidesScreen extends StatefulWidget {
  final Function(String, {Map<String, dynamic>? data}) onNavigate;

  const RidesScreen({ 
    super.key,
    required this.onNavigate,
  });

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final RideService _rideService = RideService();

  List<Ride> _upcomingRides = [];
  List<Ride> _pastRides = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRides();
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final ridesResponse = await _rideService.getRideHistory();

      if (ridesResponse.data != null) {
        final allRides = ridesResponse.data!;

        setState(() {
          _upcomingRides = allRides.where((ride) => 
              ride.status == RideStatus.pending ||
              ride.status == RideStatus.driverAssigned ||
              ride.status == RideStatus.driverArriving ||
              ride.status == RideStatus.inProgress).toList();

          _pastRides = allRides.where((ride) =>
              ride.status == RideStatus.completed ||
              ride.status == RideStatus.cancelled).toList();

          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          AppStrings.rides,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: AppStrings.upcomingRides),
            Tab(text: AppStrings.pastRides),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_error != null) return _buildErrorState();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildUpcomingTab(),
        _buildPastTab(),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 64),
          const SizedBox(height: 16),
          Text(
            AppStrings.failedToLoadRides,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? AppStrings.unknownError,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRides,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.calendar_today,
        title: AppStrings.noUpcomingRides,
        subtitle:
            'Whatever is on your schedule, a Scheduled Ride can get you there on time.',
        buttonText: AppStrings.scheduleARide,
        onPressed: () => widget.onNavigate('schedule_ride'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        itemCount: _upcomingRides.length,
        itemBuilder: (_, index) =>
            UpcomingRideCard(ride: _upcomingRides[index]),
      ),
    );
  }

  Widget _buildPastTab() {
    if (_pastRides.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: AppStrings.noPastRides,
        subtitle: 'Your completed rides will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRides,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimensions.paddingLarge),
        itemCount: _pastRides.length,
        itemBuilder: (_, index) => PastRideCard(ride: _pastRides[index]),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(60),
          ),
          child: Icon(icon, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
          ),
        ),
        if (buttonText != null && onPressed != null) ...[
          const SizedBox(height: 24),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLarge),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(vertical: AppDimensions.paddingLarge),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}