// ==================== models/vehicle_type.dart ====================
// VEHICLE TYPE MODEL - ✅ FINAL VERSION
// Handles both base_fare and base_price from backend

import 'package:flutter/material.dart';

class VehicleType {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final double baseFare;
  final double pricePerKm;
  final double pricePerMinute;
  final double minimumFare;
  final int maxPassengers;
  final int capacity;
  final double surgeMultiplier;
  final String? estimatedTime;
  final bool available;

  VehicleType({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.baseFare,
    required this.pricePerKm,
    required this.pricePerMinute,
    required this.minimumFare,
    required this.maxPassengers,
    this.capacity = 4,
    this.surgeMultiplier = 1.0,
    this.estimatedTime,
    this.available = true,
  });

  // Calculate estimated fare
  double calculateFare(double distanceKm, {int durationMinutes = 0}) {
    final baseFareAmount = baseFare + (pricePerKm * distanceKm) + (pricePerMinute * durationMinutes);
    final fare = baseFareAmount * surgeMultiplier;
    return fare < minimumFare ? minimumFare : fare;
  }

  // Format price for display
  String formatPrice(double amount) {
    return '₦${amount.toStringAsFixed(0)}';
  }

  // Get formatted prices
  String get formattedBaseFare => formatPrice(baseFare);
  String get formattedMinimumFare => formatPrice(minimumFare);

  // From JSON (Django API response)
  // ✅ FIXED: Now handles both 'base_price' (backend) and 'base_fare' (legacy)
  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: _getIconFromString(json['icon_name'] ?? json['id'] ?? 'car'),
      color: _getColorFromString(json['color'] ?? '#0066FF'),
      // ✅ CHANGED: Check 'base_price' first (backend), then 'base_fare' (fallback)
      baseFare: _parseDouble(json['base_price']) ?? 
                _parseDouble(json['base_fare']) ?? 
                500.0,
      pricePerKm: _parseDouble(json['price_per_km']) ?? 100.0,
      pricePerMinute: _parseDouble(json['price_per_minute']) ?? 10.0,
      minimumFare: _parseDouble(json['minimum_fare']) ?? 800.0,
      maxPassengers: json['max_passengers'] ?? 4,
      capacity: json['capacity'] ?? json['max_passengers'] ?? 4,
      surgeMultiplier: _parseDouble(json['surge_multiplier']) ?? 1.0,
      estimatedTime: json['estimated_time'],
      available: json['available'] ?? true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // To JSON (for API request)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'base_fare': baseFare,
      'price_per_km': pricePerKm,
      'price_per_minute': pricePerMinute,
      'minimum_fare': minimumFare,
      'max_passengers': maxPassengers,
      'capacity': capacity,
      'surge_multiplier': surgeMultiplier,
      'estimated_time': estimatedTime,
      'available': available,
    };
  }

  // Helper to convert string to IconData
  static IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'bike':
      case 'motorcycle':
      case 'two_wheeler':
        return Icons.two_wheeler;
      case 'keke':
      case 'tricycle':
      case 'rickshaw':
      case 'electric_rickshaw':
        return Icons.electric_rickshaw;
      case 'car':
      case 'swift_go':
      case 'directions_car':
        return Icons.directions_car;
      case 'suv':
      case 'van':
      case 'swift_xl':
      case 'airport_shuttle':
        return Icons.airport_shuttle;
      case 'comfort':
      case 'swift_comfort':
      case 'drive_eta':
        return Icons.drive_eta;
      default:
        return Icons.directions_car;
    }
  }

  // Helper to convert hex string to Color
  static Color _getColorFromString(String colorHex) {
    try {
      final hex = colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return const Color(0xFF0066FF); // Default blue
    }
  }

  // Copy with method
  VehicleType copyWith({
    String? id,
    String? name,
    String? description,
    IconData? icon,
    Color? color,
    double? baseFare,
    double? pricePerKm,
    double? pricePerMinute,
    double? minimumFare,
    int? maxPassengers,
    int? capacity,
    double? surgeMultiplier,
    String? estimatedTime,
    bool? available,
  }) {
    return VehicleType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      baseFare: baseFare ?? this.baseFare,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      pricePerMinute: pricePerMinute ?? this.pricePerMinute,
      minimumFare: minimumFare ?? this.minimumFare,
      maxPassengers: maxPassengers ?? this.maxPassengers,
      capacity: capacity ?? this.capacity,
      surgeMultiplier: surgeMultiplier ?? this.surgeMultiplier,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      available: available ?? this.available,
    );
  }

  @override
  String toString() {
    return 'VehicleType(id: $id, name: $name, baseFare: ₦$baseFare, capacity: $capacity)';
  }
}

// ============================================
// FALLBACK VEHICLE TYPES (for offline/testing)
// ============================================

class VehicleTypes {
  // Default vehicle types (matches Django backend vehicle types)
  static List<VehicleType> getDefaultVehicles() {
    return [
      VehicleType(
        id: 'car',
        name: 'SwiftGo',
        description: 'Affordable everyday rides',
        icon: Icons.directions_car,
        color: const Color(0xFF0066FF), // Electric Blue
        baseFare: 500,
        pricePerKm: 100,
        pricePerMinute: 10,
        minimumFare: 800,
        maxPassengers: 4,
        capacity: 4,
        surgeMultiplier: 1.0,
        estimatedTime: '5 min',
      ),
      VehicleType(
        id: 'comfort',
        name: 'SwiftComfort',
        description: 'Newer cars with top-rated drivers',
        icon: Icons.drive_eta,
        color: const Color(0xFF10B981), // Premium Green
        baseFare: 700,
        pricePerKm: 130,
        pricePerMinute: 12,
        minimumFare: 1000,
        maxPassengers: 4,
        capacity: 4,
        surgeMultiplier: 1.0,
        estimatedTime: '6 min',
      ),
      VehicleType(
        id: 'xl',
        name: 'SwiftXL',
        description: 'Extra space for groups',
        icon: Icons.airport_shuttle,
        color: const Color(0xFF7C3AED), // Premium Purple
        baseFare: 1000,
        pricePerKm: 150,
        pricePerMinute: 15,
        minimumFare: 1500,
        maxPassengers: 6,
        capacity: 6,
        surgeMultiplier: 1.0,
        estimatedTime: '8 min',
      ),
    ];
  }

  // Makurdi vehicles (includes bike/keke)
  static List<VehicleType> makurdiVehicles() {
    return [
      VehicleType(
        id: 'bike',
        name: 'Bike',
        description: 'Fast & affordable',
        icon: Icons.two_wheeler,
        color: const Color(0xFFFF6B35), // Vibrant Orange
        baseFare: 200,
        pricePerKm: 50,
        pricePerMinute: 5,
        minimumFare: 300,
        maxPassengers: 1,
        capacity: 1,
        surgeMultiplier: 1.0,
        estimatedTime: '3 min',
      ),
      VehicleType(
        id: 'keke',
        name: 'Keke',
        description: 'Comfortable tricycle',
        icon: Icons.electric_rickshaw,
        color: const Color(0xFFFFC107), // Bright Yellow
        baseFare: 300,
        pricePerKm: 70,
        pricePerMinute: 7,
        minimumFare: 400,
        maxPassengers: 3,
        capacity: 3,
        surgeMultiplier: 1.0,
        estimatedTime: '5 min',
      ),
      ...getDefaultVehicles(),
    ];
  }

  // Lagos/Abuja vehicles (no bikes/keke - banned by law)
  static List<VehicleType> restrictedCityVehicles() {
    return [
      VehicleType(
        id: 'car',
        name: 'SwiftGo',
        description: 'Affordable everyday rides',
        icon: Icons.directions_car,
        color: const Color(0xFF0066FF),
        baseFare: 800,
        pricePerKm: 150,
        pricePerMinute: 12,
        minimumFare: 1200,
        maxPassengers: 4,
        capacity: 4,
        surgeMultiplier: 1.0,
        estimatedTime: '8 min',
      ),
      VehicleType(
        id: 'comfort',
        name: 'SwiftComfort',
        description: 'Newer cars with top-rated drivers',
        icon: Icons.drive_eta,
        color: const Color(0xFF10B981),
        baseFare: 1000,
        pricePerKm: 180,
        pricePerMinute: 15,
        minimumFare: 1500,
        maxPassengers: 4,
        capacity: 4,
        surgeMultiplier: 1.0,
        estimatedTime: '10 min',
      ),
      VehicleType(
        id: 'xl',
        name: 'SwiftXL',
        description: 'Extra space for groups',
        icon: Icons.airport_shuttle,
        color: const Color(0xFF7C3AED),
        baseFare: 1500,
        pricePerKm: 200,
        pricePerMinute: 18,
        minimumFare: 2000,
        maxPassengers: 6,
        capacity: 6,
        surgeMultiplier: 1.0,
        estimatedTime: '12 min',
      ),
    ];
  }

  // Get vehicles based on city (fallback for offline)
  static List<VehicleType> getVehiclesForCity(String? city) {
    if (city == null) return getDefaultVehicles();
    
    // Cities where bikes/keke are restricted
    final restrictedCities = ['lagos', 'abuja', 'fct'];
    
    final cityLower = city.toLowerCase();
    
    if (restrictedCities.any((c) => cityLower.contains(c))) {
      return restrictedCityVehicles();
    }
    
    // Makurdi and other cities: all vehicles available
    return makurdiVehicles();
  }

  // Get a specific vehicle type by ID
  static VehicleType? getVehicleById(String id, {String? city}) {
    final vehicles = getVehiclesForCity(city);
    try {
      return vehicles.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
  }
}