// ==================== rides_screen.dart ====================
import 'package:flutter/material.dart';
import '../../../constants/app_strings.dart';
import '../../../constants/app_dimensions.dart';
import '../../../services/ride_service.dart';
import '../../../models/ride.dart';
import 'widgets/rides_tab_bar.dart';
import 'widgets/rides_empty_state.dart';
import 'widgets/rides_error_state.dart';
import 'widgets/rides_list.dart';

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          _upcomingRides = _filterUpcomingRides(allRides.rides);
          _pastRides = _filterPastRides(allRides.rides);
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

  List<Ride> _filterUpcomingRides(List<Ride> rides) {
    return rides.where((ride) =>
        ride.status == RideStatus.pending ||
        ride.status == RideStatus.driverAssigned ||
        ride.status == RideStatus.driverArriving ||
        ride.status == RideStatus.inProgress).toList();
  }

  List<Ride> _filterPastRides(List<Ride> rides) {
    return rides.where((ride) =>
        ride.status == RideStatus.completed ||
        ride.status == RideStatus.cancelled).toList();
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
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.rides,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: RidesTabBar(controller: _tabController),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
        ),
      );
    }

    if (_error != null) {
      return RidesErrorState(
        error: _error ?? AppStrings.unknownError,
        onRetry: _loadRides,
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildUpcomingTab(),
        _buildPastTab(),
      ],
    );
  }

  Widget _buildUpcomingTab() {
    if (_upcomingRides.isEmpty) {
      return RidesEmptyState(
        icon: Icons.calendar_today,
        title: AppStrings.noUpcomingRides,
        subtitle: 'Whatever is on your schedule, a Scheduled Ride can get you there on time.',
        buttonText: AppStrings.scheduleARide,
        onPressed: () => widget.onNavigate('schedule_ride'),
      );
    }

    return RidesList(
      rides: _upcomingRides,
      isUpcoming: true,
      onRefresh: _loadRides,
    );
  }

  Widget _buildPastTab() {
    if (_pastRides.isEmpty) {
      return RidesEmptyState(
        icon: Icons.history,
        title: AppStrings.noPastRides,
        subtitle: 'Your completed rides will appear here.',
      );
    }

    return RidesList(
      rides: _pastRides,
      isUpcoming: false,
      onRefresh: _loadRides,
    );
  }
}