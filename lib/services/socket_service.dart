// ==================== services/socket_service.dart ====================
// WEBSOCKET SERVICE - Real-time ride updates
// Connects to Django Channels backend for live driver location and ride status

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/api_config.dart';
import 'api_client.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  WebSocketChannel? _channel;
  String? _currentRideId;
  bool _isConnected = false;

  // Stream controllers for real-time updates
  final _driverLocationController =
      StreamController<DriverLocationUpdate>.broadcast();
  final _rideStatusController = StreamController<RideStatusUpdate>.broadcast();
  final _driverMatchController =
      StreamController<DriverMatchUpdate>.broadcast();
  final _chatMessageController = StreamController<ChatMessage>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  // Public streams
  Stream<DriverLocationUpdate> get driverLocationStream =>
      _driverLocationController.stream;
  Stream<RideStatusUpdate> get rideStatusStream => _rideStatusController.stream;
  Stream<DriverMatchUpdate> get driverMatchStream =>
      _driverMatchController.stream;
  Stream<ChatMessage> get chatMessageStream => _chatMessageController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  
  // ✅ ADDED: Connection status as string stream for compatibility
  Stream<String> get connectionStatusStream => _connectionStateController.stream
      .map((isConnected) => isConnected ? 'connected' : 'disconnected');

  bool get isConnected => _isConnected;
  String? get currentRideId => _currentRideId;

  // ============================================
  // CONNECTION MANAGEMENT
  // ============================================

  /// Connect to ride WebSocket
  /// Backend endpoint: ws://your-backend/ws/ride/<ride_id>/
  Future<void> connectToRide(String rideId, String authToken) async {
    try {
      debugPrint('🔌 Connecting to ride WebSocket: $rideId');

      // Disconnect existing connection
      await disconnect();

      _currentRideId = rideId;

      // Build WebSocket URL
      final wsUrl = _buildWebSocketUrl(rideId, authToken);

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
        cancelOnError: false,
      );

      _isConnected = true;
      _connectionStateController.add(true);

      debugPrint('✅ WebSocket connected to ride: $rideId');

      // Send initial authentication/connection message
      _sendMessage({
        'type': 'connection',
        'ride_id': rideId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ WebSocket connection error: $e');
      _isConnected = false;
      _connectionStateController.add(false);
      rethrow;
    }
  }

  /// Build WebSocket URL based on environment
  String _buildWebSocketUrl(String rideId, String authToken) {
    // Use configured WebSocket base (already includes `/ws`)
    final base = ApiConfig.wsUrl; // e.g. wss://swiftride.../ws
    return '$base/ride/$rideId/?token=$authToken';
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    if (_channel != null) {
      debugPrint('🔌 Disconnecting WebSocket');

      await _channel!.sink.close();
      _channel = null;
      _currentRideId = null;
      _isConnected = false;
      _connectionStateController.add(false);

      debugPrint('✅ WebSocket disconnected');
    }
  }

  // ============================================
  // MESSAGE HANDLING
  // ============================================

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      debugPrint('📨 WebSocket message received: $type');

      switch (type) {
        case 'driver_location':
          _handleDriverLocation(data);
          break;

        case 'ride_status':
          _handleRideStatus(data);
          break;

        case 'driver_matched':
          _handleDriverMatched(data);
          break;

        case 'chat_message':
          _handleChatMessage(data);
          break;

        case 'driver_arrived':
          _handleDriverArrived(data);
          break;

        case 'ride_started':
          _handleRideStarted(data);
          break;

        case 'ride_completed':
          _handleRideCompleted(data);
          break;

        case 'error':
          debugPrint('❌ WebSocket error: ${data['message']}');
          break;

        default:
          debugPrint('⚠️ Unknown message type: $type');
      }
    } catch (e) {
      debugPrint('❌ Error handling WebSocket message: $e');
    }
  }

  void _handleDriverLocation(Map<String, dynamic> data) {
    final update = DriverLocationUpdate.fromJson(data);
    _driverLocationController.add(update);
  }

  void _handleRideStatus(Map<String, dynamic> data) {
    final update = RideStatusUpdate.fromJson(data);
    _rideStatusController.add(update);
  }

  void _handleDriverMatched(Map<String, dynamic> data) {
    final update = DriverMatchUpdate.fromJson(data);
    _driverMatchController.add(update);
  }

  void _handleChatMessage(Map<String, dynamic> data) {
    final message = ChatMessage.fromJson(data);
    _chatMessageController.add(message);
  }

  void _handleDriverArrived(Map<String, dynamic> data) {
    _rideStatusController.add(
      RideStatusUpdate(
        status: 'driver_arrived',
        timestamp: DateTime.now(),
        message: 'Your driver has arrived',
      ),
    );
  }

  void _handleRideStarted(Map<String, dynamic> data) {
    _rideStatusController.add(
      RideStatusUpdate(
        status: 'in_progress',
        timestamp: DateTime.now(),
        message: 'Ride started',
      ),
    );
  }

  void _handleRideCompleted(Map<String, dynamic> data) {
    _rideStatusController.add(
      RideStatusUpdate(
        status: 'completed',
        timestamp: DateTime.now(),
        message: 'Ride completed',
        data: data,
      ),
    );
  }

  void _handleError(dynamic error) {
    debugPrint('❌ WebSocket error: $error');
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void _handleDisconnection() {
    debugPrint('🔌 WebSocket disconnected');
    _isConnected = false;
    _connectionStateController.add(false);
  }

  // ============================================
  // SENDING MESSAGES
  // ============================================

  /// Send message through WebSocket
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null || !_isConnected) {
      debugPrint('⚠️ Cannot send message: not connected');
      return;
    }

    try {
      _channel!.sink.add(jsonEncode(message));
      debugPrint('📤 WebSocket message sent: ${message['type']}');
    } catch (e) {
      debugPrint('❌ Error sending WebSocket message: $e');
    }
  }

  /// Send chat message to driver
  void sendChatMessage(String message) {
    _sendMessage({
      'type': 'chat_message',
      'message': message,
      'sender': 'rider',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Request current driver location
  void requestDriverLocation() {
    _sendMessage({
      'type': 'request_driver_location',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Cancel ride through WebSocket
  void cancelRide(String reason) {
    _sendMessage({
      'type': 'cancel_ride',
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send driver location update (for driver side)
  void sendDriverLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    String? rideId,
  }) {
    _sendMessage({
      'type': 'driver_location',
      'latitude': latitude,
      'longitude': longitude,
      if (heading != null) 'heading': heading,
      if (speed != null) 'speed': speed,
      if (rideId != null) 'ride_id': rideId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // ============================================
  // CLEANUP
  // ============================================

  /// Dispose all resources
  Future<void> dispose() async {
    await disconnect();
    await _driverLocationController.close();
    await _rideStatusController.close();
    await _driverMatchController.close();
    await _chatMessageController.close();
    await _connectionStateController.close();
  }
}

/// Helper to fetch token for sockets
class SocketAuthProvider {
  final ApiClient _apiClient = ApiClient.instance;

  Future<String?> getToken() => _apiClient.getAccessToken();
}

// ============================================
// UPDATE MODELS
// ============================================

/// Driver location update from WebSocket
class DriverLocationUpdate {
  final String driverId;
  final LatLng location;
  final double? heading; // Direction in degrees
  final double? speed; // Speed in km/h
  final DateTime timestamp;

  DriverLocationUpdate({
    required this.driverId,
    required this.location,
    this.heading,
    this.speed,
    required this.timestamp,
  });

  factory DriverLocationUpdate.fromJson(Map<String, dynamic> json) {
    return DriverLocationUpdate(
      driverId: json['driver_id'] ?? '',
      location: LatLng(
        json['latitude'] ?? 0.0,
        json['longitude'] ?? 0.0,
      ),
      heading: json['heading']?.toDouble(),
      speed: json['speed']?.toDouble(),
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Ride status update from WebSocket
class RideStatusUpdate {
  final String status;
  final DateTime timestamp;
  final String? message;
  final Map<String, dynamic>? data;

  RideStatusUpdate({
    required this.status,
    required this.timestamp,
    this.message,
    this.data,
  });

  factory RideStatusUpdate.fromJson(Map<String, dynamic> json) {
    return RideStatusUpdate(
      status: json['status'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      message: json['message'],
      data: json['data'],
    );
  }
}

/// Driver match notification from WebSocket
class DriverMatchUpdate {
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double driverRating;
  final String vehicleType;
  final String vehicleModel;
  final String vehicleColor;
  final String licensePlate;
  final double rating;
  final int eta; // ETA in minutes
  final LatLng? driverLocation;

  DriverMatchUpdate({
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.driverRating,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.licensePlate,
    required this.rating,
    required this.eta,
    this.driverLocation,
  });

  factory DriverMatchUpdate.fromJson(Map<String, dynamic> json) {
    return DriverMatchUpdate(
      driverId: json['driver_id'] ?? '',
      driverName: json['driver_name'] ?? '',
      driverPhone: json['driver_phone'] ?? '',
      driverRating: (json['driver_rating'] ?? 5.0).toDouble(),
      vehicleType: json['vehicle_type'] ?? '',
      vehicleModel: json['vehicle_model'] ?? '',
      vehicleColor: json['vehicle_color'] ?? '',
      licensePlate: json['license_plate'] ?? '',
      rating: (json['rating'] ?? 5.0).toDouble(),
      eta: json['eta'] ?? 0,
      driverLocation:
          json['driver_latitude'] != null && json['driver_longitude'] != null
              ? LatLng(json['driver_latitude'], json['driver_longitude'])
              : null,
    );
  }
}

/// Chat message from WebSocket
class ChatMessage {
  final String sender; // 'rider' or 'driver'
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      sender: json['sender'] ?? '',
      message: json['message'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  bool get isFromDriver => sender == 'driver';
  bool get isFromRider => sender == 'rider';
}