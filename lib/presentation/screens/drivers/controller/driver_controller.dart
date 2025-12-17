import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/driver_available_ride.dart';
import '../../../../models/driver_active_ride.dart';
import '../../../../services/driver_service.dart';
import '../../../../services/socket_service.dart';
import '../../../../services/socket_service.dart' show SocketAuthProvider;

class DriverController extends ChangeNotifier {
  final DriverService _driverService = DriverService();

  bool _isOnline = false;
  bool _isToggling = false;
  bool _isLoadingRides = false;
  String? _error;
  List<DriverAvailableRide> _available = [];
  List<DriverActiveRide> _active = [];
  Timer? _pollTimer;
  Timer? _locationTimer;
  final SocketService _socketService = SocketService();
  final SocketAuthProvider _socketAuthProvider = SocketAuthProvider();

  bool get isOnline => _isOnline;
  bool get isToggling => _isToggling;
  bool get isLoadingRides => _isLoadingRides;
  String? get error => _error;
  List<DriverAvailableRide> get availableRides => _available;
  List<DriverActiveRide> get activeRides => _active;

  Future<void> toggleAvailability() async {
    if (_isToggling) return;
    _isToggling = true;
    _error = null;
    notifyListeners();

    final action = _isOnline ? 'offline' : 'online';
    final response = await _driverService.toggleAvailability(action);
    if (response.isSuccess && response.data != null) {
      _isOnline = response.data!['is_online'] ?? (_isOnline ? false : true);
    } else {
      _error = response.error;
    }

    _isToggling = false;
    notifyListeners();

    if (_isOnline) {
      await refreshRides();
      _startPolling();
    } else {
      _available = [];
      _active = [];
      _stopPolling();
      _stopLocationUpdates();
      notifyListeners();
    }
  }

  Future<void> refreshRides() async {
    if (!_isOnline) return;
    _isLoadingRides = true;
    _error = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final availableResp = await _driverService.getAvailableRides(
        latitude: position.latitude,
        longitude: position.longitude,
        maxDistanceKm: 15,
      );
      if (availableResp.isSuccess && availableResp.data != null) {
        _available = availableResp.data!;
      } else {
        _error = availableResp.error;
      }

      final activeResp = await _driverService.getActiveRides();
      if (activeResp.isSuccess && activeResp.data != null) {
        _active = activeResp.data!;
      }
      _maybeStartLocationUpdates();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingRides = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRide(String requestId) async {
    final resp = await _driverService.acceptRide(requestId);
    if (resp.isSuccess) {
      // Attempt to extract ride id from response payload
      final rideId = (resp.data?['ride']?['id'])?.toString();
      if (rideId != null) {
        await _connectSocket(rideId);
      }
      await refreshRides();
      return true;
    }
    _error = resp.error;
    notifyListeners();
    return false;
  }

  Future<bool> declineRide(String requestId) async {
    final resp = await _driverService.declineRide(requestId);
    if (resp.isSuccess) {
      await refreshRides();
      return true;
    }
    _error = resp.error;
    notifyListeners();
    return false;
  }

  Future<bool> startRide(String rideId) async {
    final resp = await _driverService.startRide(rideId);
    if (resp.isSuccess) {
      await refreshRides();
      return true;
    }
    _error = resp.error;
    notifyListeners();
    return false;
  }

  Future<bool> completeRide(String rideId) async {
    final resp = await _driverService.completeRide(rideId);
    if (resp.isSuccess) {
      await refreshRides();
      return true;
    }
    _error = resp.error;
    notifyListeners();
    return false;
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      refreshRides();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _maybeStartLocationUpdates() {
    if (_active.isEmpty) {
      _stopLocationUpdates();
      return;
    }
    final rideId = _active.first.id;
    _connectSocket(rideId);
    _locationTimer ??= Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        // Send via REST
        await _driverService.updateDriverLocation(
          rideId: rideId,
          latitude: position.latitude,
          longitude: position.longitude,
          speed: position.speed * 3.6, // m/s to km/h
          bearing: position.heading,
        );
        // Send via WebSocket if connected
        _socketService.sendDriverLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          heading: position.heading,
          speed: position.speed * 3.6,
          rideId: rideId,
        );
      } catch (e) {
        // swallow to keep timer running
        debugPrint('Location update error: $e');
      }
    });
  }

  Future<void> _connectSocket(String rideId) async {
    try {
      final token = await _socketAuthProvider.getToken();
      if (token == null) return;
      await _socketService.connectToRide(rideId, token);
    } catch (e) {
      debugPrint('WS connect error: $e');
    }
  }

  void _stopLocationUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _stopLocationUpdates();
    super.dispose();
  }
}
