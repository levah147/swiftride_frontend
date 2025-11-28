import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Promotions Service - Handles all promotions/referrals/loyalty API calls
/// 
/// FILE LOCATION: lib/services/promotions_service.dart
/// 
/// Endpoints:
/// - GET /api/promotions/promos/ - List promo codes
/// - POST /api/promotions/promos/validate/ - Validate promo code
/// - GET /api/promotions/referrals/ - List referrals
/// - GET /api/promotions/referrals/my_code/ - Get referral code
/// - GET /api/promotions/loyalty/my_points/ - Get loyalty points
class PromotionsService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // PROMO CODES
  // ============================================

  /// Get all available promo codes
  Future<ApiResponse<List<Map<String, dynamic>>>> getPromoCodes() async {
    try {
      debugPrint('🎁 Fetching promo codes...');

      final response = await _apiClient.get<List<dynamic>>(
        '/promotions/promos/',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final promos = response.data!
            .map((e) => e as Map<String, dynamic>)
            .toList();
        debugPrint('✅ Loaded ${promos.length} promo codes');
        return ApiResponse.success(promos);
      }

      return ApiResponse.error(response.error ?? 'Failed to load promo codes');
    } catch (e) {
      debugPrint('❌ Error getting promo codes: $e');
      return ApiResponse.error('Failed to fetch promo codes: ${e.toString()}');
    }
  }

  /// Validate promo code and calculate discount
  Future<ApiResponse<Map<String, dynamic>>> validatePromoCode({
    required String promoCode,
    required double fareAmount,
  }) async {
    try {
      debugPrint('🔍 Validating promo code: $promoCode for fare: ₦$fareAmount');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/promotions/promos/validate/',
        {
          'promo_code': promoCode,
          'fare_amount': fareAmount.toString(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        debugPrint('✅ Promo valid! Discount: ₦${data['discount_amount']}');
        return ApiResponse.success(data);
      }

      return ApiResponse.error(
        response.data?['error'] ?? response.error ?? 'Invalid promo code',
      );
    } catch (e) {
      debugPrint('❌ Error validating promo: $e');
      return ApiResponse.error('Failed to validate promo: ${e.toString()}');
    }
  }

  // ============================================
  // REFERRALS
  // ============================================

  /// Get user's referral code
  Future<ApiResponse<Map<String, dynamic>>> getMyReferralCode() async {
    try {
      debugPrint('📱 Fetching referral code...');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/promotions/referrals/my_code/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        debugPrint('✅ Referral code: ${data['referral_code']}');
        return ApiResponse.success(data);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load referral code',
      );
    } catch (e) {
      debugPrint('❌ Error getting referral code: $e');
      return ApiResponse.error(
        'Failed to fetch referral code: ${e.toString()}',
      );
    }
  }

  /// Get list of user's referrals
  Future<ApiResponse<List<Map<String, dynamic>>>> getMyReferrals() async {
    try {
      debugPrint('👥 Fetching referrals...');

      final response = await _apiClient.get<List<dynamic>>(
        '/promotions/referrals/',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final referrals = response.data!
            .map((e) => e as Map<String, dynamic>)
            .toList();
        debugPrint('✅ Loaded ${referrals.length} referrals');
        return ApiResponse.success(referrals);
      }

      return ApiResponse.error(response.error ?? 'Failed to load referrals');
    } catch (e) {
      debugPrint('❌ Error getting referrals: $e');
      return ApiResponse.error('Failed to fetch referrals: ${e.toString()}');
    }
  }

  // ============================================
  // LOYALTY POINTS
  // ============================================

  /// Redeem loyalty points for wallet credit
  /// 
  /// Conversion rate: 100 points = ₦10
  /// 
  /// Returns updated wallet balance and points
  Future<ApiResponse<Map<String, dynamic>>> redeemPoints({
    required int points,
  }) async {
    try {
      debugPrint('💰 Redeeming $points loyalty points...');
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/promotions/loyalty/redeem/',
        {'points': points},
        fromJson: (json) => json as Map<String, dynamic>,
      );
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        debugPrint(
          '✅ Points redeemed! Amount: ₦${data['amount']}, '
          'New points: ${data['new_available_points']}'
        );
        return ApiResponse.success(data);
      }
      
      return ApiResponse.error(
        response.error ?? 'Failed to redeem points',
      );
    } catch (e) {
      debugPrint('❌ Error redeeming points: $e');
      return ApiResponse.error('Failed to redeem points: ${e.toString()}');
    }
  }


  /// Get user's loyalty points and tier
  Future<ApiResponse<Map<String, dynamic>>> getMyLoyaltyPoints() async {
    try {
      debugPrint('⭐ Fetching loyalty points...');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/promotions/loyalty/my_points/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        debugPrint(
          '✅ Loyalty: ${data['available_points']} points, '
          'tier: ${data['tier']}',
        );
        return ApiResponse.success(data);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load loyalty points',
      );
    } catch (e) {
      debugPrint('❌ Error getting loyalty points: $e');
      return ApiResponse.error(
        'Failed to fetch loyalty points: ${e.toString()}',
      );
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Format promo discount type
  static String formatDiscountType(String type) {
    switch (type.toLowerCase()) {
      case 'percentage':
        return 'Percentage';
      case 'fixed':
        return 'Fixed Amount';
      default:
        return type;
    }
  }

  /// Format discount display
  static String formatDiscountDisplay(
    String discountType,
    double discountValue,
  ) {
    if (discountType.toLowerCase() == 'percentage') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    } else {
      return '₦${discountValue.toStringAsFixed(0)} OFF';
    }
  }

  /// Get tier color
  static Color getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32); // Bronze
      case 'silver':
        return const Color(0xFFC0C0C0); // Silver
      case 'gold':
        return const Color(0xFFFFD700); // Gold
      case 'platinum':
        return const Color(0xFFE5E4E2); // Platinum
      default:
        return Colors.grey;
    }
  }

  /// Get tier icon
  static String getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return '🥉';
      case 'silver':
        return '🥈';
      case 'gold':
        return '🥇';
      case 'platinum':
        return '💎';
      default:
        return '⭐';
    }
  }

  /// Calculate points needed for next tier
  static Map<String, dynamic> getNextTierInfo(String currentTier, int totalPoints) {
    switch (currentTier.toLowerCase()) {
      case 'bronze':
        return {
          'next_tier': 'Silver',
          'points_needed': 2000 - totalPoints,
          'total_required': 2000,
        };
      case 'silver':
        return {
          'next_tier': 'Gold',
          'points_needed': 5000 - totalPoints,
          'total_required': 5000,
        };
      case 'gold':
        return {
          'next_tier': 'Platinum',
          'points_needed': 10000 - totalPoints,
          'total_required': 10000,
        };
      case 'platinum':
        return {
          'next_tier': 'Platinum (Max)',
          'points_needed': 0,
          'total_required': 10000,
        };
      default:
        return {
          'next_tier': 'Silver',
          'points_needed': 2000,
          'total_required': 2000,
        };
    }
  }

  /// Format referral status
  static String formatReferralStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      case 'rewarded':
        return 'Rewarded';
      default:
        return status;
    }
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'rewarded':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Convert points to money (100 points = ₦10)
  static double pointsToMoney(int points) {
    return points / 10.0;
  }

  /// Convert money to points (₦10 = 100 points)
  static int moneyToPoints(double amount) {
    return (amount * 10).toInt();
  }
}