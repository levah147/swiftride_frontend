import 'package:flutter/material.dart';

class User {
  final String id;
  final String phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? email;
  final double rating;
  final int totalRides;
  final String? profilePicture;
  final String? profilePictureUrl;
  final bool isDriver;
  final bool isPhoneVerified;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.firstName,
    this.lastName,
    this.email,
    required this.rating,
    this.totalRides = 0,
    this.profilePicture,
    this.profilePictureUrl,
    this.isDriver = false,
    this.isPhoneVerified = false,
    required this.isActive,
    required this.createdAt,
  });

  /// Helper method to safely convert rating to double
  static double _parseRating(dynamic ratingValue) {
    try {
      if (ratingValue == null) return 5.00;
      
      // If it's already a double, return it
      if (ratingValue is double) return ratingValue;
      
      // If it's an int, convert to double
      if (ratingValue is int) return ratingValue.toDouble();
      
      // If it's a string, parse it
      if (ratingValue is String) {
        return double.parse(ratingValue);
      }
      
      // Fallback
      return 5.00;
    } catch (e) {
      debugPrint('Error parsing rating: $e, Value: $ratingValue');
      return 5.00;
    }
  }

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      return User(
        id: json['id'].toString(),
        phoneNumber: json['phone_number'] ?? '',
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        rating: _parseRating(json['rating']),
        totalRides: json['total_rides'] ?? 0,
        profilePicture: json['profile_picture'],
        profilePictureUrl: json['profile_picture_url'],
        isDriver: json['is_driver'] ?? false,
        isPhoneVerified: json['is_phone_verified'] ?? false,
        isActive: json['is_active'] ?? true,
        createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      );
    } catch (e) {
      debugPrint('❌ Error parsing User from JSON: $e');
      debugPrint('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'rating': rating,
      'total_rides': totalRides,
      'profile_picture': profilePicture,
      'profile_picture_url': profilePictureUrl,
      'is_driver': isDriver,
      'is_phone_verified': isPhoneVerified,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get fullName => '${firstName ?? 'User'} ${lastName ?? ''}'.trim();
  
  /// Returns profile picture URL if available, otherwise null
  String? get profileImageUrl => profilePictureUrl ?? profilePicture;
  
  /// Copy constructor for creating modified instances
  User copyWith({
    String? id,
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    double? rating,
    int? totalRides,
    String? profilePicture,
    String? profilePictureUrl,
    bool? isDriver,
    bool? isPhoneVerified,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      totalRides: totalRides ?? this.totalRides,
      profilePicture: profilePicture ?? this.profilePicture,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      isDriver: isDriver ?? this.isDriver,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}