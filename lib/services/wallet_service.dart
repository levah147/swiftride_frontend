import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Wallet Service - Handles all wallet-related API calls
/// Endpoints:
/// - GET /api/wallet/balance/ - Get current balance
/// - GET /api/wallet/transactions/ - Get transaction history
/// - POST /api/wallet/top-up/ - Add money to wallet
/// - POST /api/wallet/withdraw/ - Withdraw money (drivers only)
class WalletService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // GET WALLET BALANCE
  // ============================================
  
  Future<ApiResponse<Map<String, dynamic>>> getBalance() async {
    try {
      debugPrint('📱 Fetching wallet balance...');
      
      return await _apiClient.get<Map<String, dynamic>>(
        '/wallet/balance/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error getting balance: $e');
      return ApiResponse.error('Failed to fetch balance: ${e.toString()}');
    }
  }

  // ============================================
  // GET TRANSACTION HISTORY
  // ============================================
  
  Future<ApiResponse<List<Map<String, dynamic>>>> getTransactions({
    String? transactionType, // 'credit', 'debit', or null for all
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📋 Fetching transactions (page: $page, type: $transactionType)...');
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      if (transactionType != null) {
        queryParams['transaction_type'] = transactionType;
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/wallet/transactions/',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final results = (response.data!['results'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        
        debugPrint('✅ Loaded ${results.length} transactions');
        return ApiResponse.success(results);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load transactions',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error getting transactions: $e');
      return ApiResponse.error('Failed to fetch transactions: ${e.toString()}');
    }
  }

  // ============================================
  // TOP UP WALLET
  // ============================================
  
  Future<ApiResponse<Map<String, dynamic>>> topUp({
    required double amount,
    String? description,
  }) async {
    try {
      debugPrint('💰 Processing top-up: ₦$amount');
      
      final data = <String, dynamic>{
        'amount': amount,
      };
      if (description != null) {
        data['description'] = description;
      }

      return await _apiClient.post<Map<String, dynamic>>(
        '/wallet/top-up/',
        data,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error during top-up: $e');
      return ApiResponse.error('Failed to complete top-up: ${e.toString()}');
    }
  }

  // ============================================
  // WITHDRAW FROM WALLET (DRIVERS ONLY)
  // ============================================
  
  Future<ApiResponse<Map<String, dynamic>>> withdraw({
    required double amount,
    String? description,
  }) async {
    try {
      debugPrint('💳 Processing withdrawal: ₦$amount');
      
      final data = <String, dynamic>{
        'amount': amount,
      };
      if (description != null) {
        data['description'] = description;
      }

      return await _apiClient.post<Map<String, dynamic>>(
        '/wallet/withdraw/',
        data,
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error during withdrawal: $e');
      return ApiResponse.error('Failed to complete withdrawal: ${e.toString()}');
    }
  }

  // ============================================
  // HELPER: Format Currency
  // ============================================
  
  static String formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  // ============================================
  // HELPER: Format Transaction Type
  // ============================================
  
  static String formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
        return 'Credit';
      case 'debit':
        return 'Debit';
      case 'ride_payment':
        return 'Ride Payment';
      case 'top_up':
        return 'Top Up';
      case 'withdrawal':
        return 'Withdrawal';
      case 'refund':
        return 'Refund';
      default:
        return type;
    }
  }

  // ============================================
  // HELPER: Get Transaction Icon
  // ============================================
  
  static String getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
      case 'top_up':
      case 'refund':
        return '↓'; // Money in
      case 'debit':
      case 'ride_payment':
      case 'withdrawal':
        return '↑'; // Money out
      default:
        return '•';
    }
  }

  // ============================================
  // HELPER: Get Transaction Color
  // ============================================
  
  static bool isCredit(String type) {
    return type.toLowerCase() == 'credit' || 
           type.toLowerCase() == 'top_up' ||
           type.toLowerCase() == 'refund';
  }
}