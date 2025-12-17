import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Payment Service - FIXED VERSION
/// 
/// FIXES APPLIED:
/// ✅ Changed 'transaction_type' to 'type' in query params (Line 105)
/// ✅ Improved response parsing for paginated data
/// ✅ Better error handling
/// ✅ Added retry logic for critical operations
class PaymentService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // WALLET OPERATIONS
  // ============================================

  /// Get wallet details (balance, status, etc.)
  Future<ApiResponse<Map<String, dynamic>>> getWallet() async {
    try {
      debugPrint('💰 Fetching wallet details...');
      
      return await _apiClient.get<Map<String, dynamic>>(
        '/payments/wallet/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error getting wallet: $e');
      return ApiResponse.error('Failed to fetch wallet: ${e.toString()}');
    }
  }

  /// Get current wallet balance
  Future<ApiResponse<Map<String, dynamic>>> getBalance() async {
    try {
      debugPrint('📊 Fetching wallet balance...');
      
      return await _apiClient.get<Map<String, dynamic>>(
        '/payments/wallet/balance/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error getting balance: $e');
      return ApiResponse.error('Failed to fetch balance: ${e.toString()}');
    }
  }

  // ============================================
  // TRANSACTION OPERATIONS - FIXED
  // ============================================

  /// Get transaction history - FIXED
  /// 
  /// ✅ FIXED: Changed 'transaction_type' to 'type' to match Django backend
  /// 
  /// Query params:
  /// - type: Filter by 'credit', 'debit', 'deposit', 'withdrawal', etc.
  /// - status: Filter by 'completed', 'pending', 'failed'
  /// - page: Page number (default: 1)
  Future<ApiResponse<List<Map<String, dynamic>>>> getTransactions({
    String? type,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      debugPrint('📋 Fetching transactions (page: $page, type: $type)...');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/payments/transactions/',
        queryParams: {
          if (type != null) 'type': type,  // ✅ FIXED: Was 'transaction_type'
          if (status != null) 'status': status,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> results = [];
        
        // ✅ IMPROVED: Handle Django REST Framework pagination
        if (response.data!.containsKey('results')) {
          // Paginated response
          final resultsList = response.data!['results'];
          if (resultsList is List) {
            results = resultsList
                .map((item) => item as Map<String, dynamic>)
                .toList();
            
            debugPrint('✅ Loaded ${results.length} transactions (paginated)');
          }
        } else if (response.data is List) {
          // Direct list response (shouldn't happen with DRF, but handle it)
          results = (response.data as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          
          debugPrint('✅ Loaded ${results.length} transactions (direct list)');
        } else {
          debugPrint('⚠️ Unexpected response format: ${response.data}');
        }
        
        return ApiResponse.success(results, statusCode: response.statusCode);
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
  // DEPOSIT OPERATIONS
  // ============================================

  /// Initialize Paystack payment (Step 1)
  Future<ApiResponse<Map<String, dynamic>>> initializePaystackPayment({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      debugPrint('💳 Initializing Paystack payment: ₦$amount via $paymentMethod');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/deposit/initialize/',
        {
          'amount': amount,
          'payment_method': paymentMethod,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error initializing payment: $e');
      return ApiResponse.error('Failed to initialize payment: ${e.toString()}');
    }
  }

  /// Verify Paystack payment (Step 2) - WITH RETRY LOGIC
  /// 
  /// ✅ IMPROVED: Added retry logic for network issues
  Future<ApiResponse<Map<String, dynamic>>> verifyPaystackPayment({
    required String reference,
    int retries = 3,
  }) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        debugPrint('✅ Verifying payment (attempt $attempt/$retries): $reference');
        
        final response = await _apiClient.get<Map<String, dynamic>>(
          '/payments/deposit/verify/',
          queryParams: {'reference': reference},
          fromJson: (json) => json as Map<String, dynamic>,
        );
        
        // If successful, return immediately
        if (response.isSuccess) {
          debugPrint('✅ Payment verification successful on attempt $attempt');
          return response;
        }
        
        // If not successful and we have retries left, wait and try again
        if (attempt < retries) {
          debugPrint('⚠️ Verification failed, retrying in ${attempt * 2} seconds...');
          await Future.delayed(Duration(seconds: attempt * 2));
        } else {
          // Last attempt failed
          return response;
        }
      } catch (e) {
        debugPrint('❌ Error verifying payment (attempt $attempt): $e');
        
        if (attempt >= retries) {
          return ApiResponse.error('Failed to verify payment after $retries attempts: ${e.toString()}');
        }
        
        // Wait before retry
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    return ApiResponse.error('Failed to verify payment after $retries attempts');
  }

  /// Deposit funds to wallet (Legacy - Direct Deposit)
  Future<ApiResponse<Map<String, dynamic>>> depositFunds({
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      debugPrint('💰 Depositing funds: ₦$amount via $paymentMethod');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/deposit/',
        {
          'amount': amount,
          'payment_method': paymentMethod,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error depositing funds: $e');
      return ApiResponse.error('Failed to deposit funds: ${e.toString()}');
    }
  }

  // ============================================
  // BANK OPERATIONS
  // ============================================

  /// Get list of Nigerian banks
  Future<ApiResponse<List<Map<String, dynamic>>>> getNigerianBanks() async {
    try {
      debugPrint('🏦 Fetching list of Nigerian banks...');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/payments/banks/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> banks = [];
        
        if (response.data!.containsKey('banks')) {
          final banksList = response.data!['banks'] as List;
          banks = banksList.map((e) => e as Map<String, dynamic>).toList();
        } else if (response.data is List) {
          banks = (response.data as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        
        debugPrint('✅ Loaded ${banks.length} banks');
        return ApiResponse.success(banks, statusCode: response.statusCode);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load banks',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error getting banks: $e');
      return ApiResponse.error('Failed to fetch banks: ${e.toString()}');
    }
  }

  /// Validate Nigerian bank account
  Future<ApiResponse<Map<String, dynamic>>> validateBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      debugPrint('🔍 Validating bank account: $accountNumber at $bankCode');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/banks/validate/',
        {
          'account_number': accountNumber,
          'bank_code': bankCode,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error validating account: $e');
      return ApiResponse.error('Failed to validate account: ${e.toString()}');
    }
  }

  // ============================================
  // WITHDRAWAL OPERATIONS (Drivers Only)
  // ============================================

  /// Get withdrawal history (Drivers only)
  Future<ApiResponse<List<Map<String, dynamic>>>> getWithdrawals() async {
    try {
      debugPrint('💳 Fetching withdrawal history...');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/payments/withdrawals/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> withdrawals = [];
        
        if (response.data!.containsKey('results')) {
          final results = response.data!['results'] as List;
          withdrawals = results.map((e) => e as Map<String, dynamic>).toList();
        } else if (response.data is List) {
          withdrawals = (response.data as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        
        return ApiResponse.success(withdrawals, statusCode: response.statusCode);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load withdrawals',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error getting withdrawals: $e');
      return ApiResponse.error('Failed to fetch withdrawals: ${e.toString()}');
    }
  }

  /// Get withdrawal details
  Future<ApiResponse<Map<String, dynamic>>> getWithdrawalDetails(
      int withdrawalId) async {
    try {
      debugPrint('📄 Fetching withdrawal details: $withdrawalId');
      
      return await _apiClient.get<Map<String, dynamic>>(
        '/payments/withdrawals/$withdrawalId/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error getting withdrawal details: $e');
      return ApiResponse.error('Failed to fetch withdrawal: ${e.toString()}');
    }
  }

  /// Request withdrawal with Paystack (Drivers only)
  Future<ApiResponse<Map<String, dynamic>>> requestWithdrawalPaystack({
    required double amount,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      debugPrint('🏦 Requesting withdrawal: ₦$amount to $accountNumber');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/withdrawals/request/',
        {
          'amount': amount,
          'bank_code': bankCode,
          'account_number': accountNumber,
          'account_name': accountName,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error requesting withdrawal: $e');
      return ApiResponse.error('Failed to request withdrawal: ${e.toString()}');
    }
  }

  /// Request withdrawal (Legacy - Direct Bank Transfer)
  Future<ApiResponse<Map<String, dynamic>>> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    try {
      debugPrint('💳 Requesting withdrawal: ₦$amount');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/withdrawals/',
        {
          'amount': amount,
          'bank_name': bankName,
          'account_number': accountNumber,
          'account_name': accountName,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error requesting withdrawal: $e');
      return ApiResponse.error('Failed to request withdrawal: ${e.toString()}');
    }
  }
 
  /// Withdraw funds from wallet (Smart Withdrawal) - FIXED
  /// 
  /// ✅ FIXED: Properly sends bank details to backend
  Future<ApiResponse<Map<String, dynamic>>> withdraw({
    required double amount,
    String? bankName,
    String? accountNumber,
    String? accountName,
  }) async {
    try {
      // If bank details provided, use full withdrawal endpoint
      if (bankName != null && accountNumber != null && accountName != null) {
        debugPrint('🏦 Requesting withdrawal with bank details: ₦$amount to $bankName');
        
        return await _apiClient.post<Map<String, dynamic>>(
          '/payments/withdrawals/request/',
          {
            'amount': amount,
            'bank_name': bankName,
            'account_number': accountNumber,
            'account_name': accountName,
          },
          fromJson: (json) => json as Map<String, dynamic>,
        );
      } else {
        // Otherwise use quick withdrawal with saved bank details
        debugPrint('🏦 Requesting quick withdrawal: ₦$amount (using saved bank details)');
        
        return await _apiClient.post<Map<String, dynamic>>(
          '/payments/withdrawals/quick/',
          {
            'amount': amount,
          },
          fromJson: (json) => json as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('❌ Error requesting withdrawal: $e');
      return ApiResponse.error('Failed to request withdrawal: ${e.toString()}');
    }
  }

  // ============================================
  // PAYMENT CARD OPERATIONS
  // ============================================

  /// Get saved payment cards
  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentCards() async {
    try {
      debugPrint('💳 Fetching payment cards...');
      
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/payments/cards/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        List<Map<String, dynamic>> cards = [];
        
        if (response.data!.containsKey('results')) {
          final results = response.data!['results'] as List;
          cards = results.map((e) => e as Map<String, dynamic>).toList();
        } else if (response.data is List) {
          cards = (response.data as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        
        return ApiResponse.success(cards, statusCode: response.statusCode);
      }

      return ApiResponse.error(
        response.error ?? 'Failed to load cards',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('❌ Error getting payment cards: $e');
      return ApiResponse.error('Failed to fetch cards: ${e.toString()}');
    }
  }

  /// Add payment card
  Future<ApiResponse<Map<String, dynamic>>> addPaymentCard({
    required String cardType,
    required String lastFour,
    required int expiryMonth,
    required int expiryYear,
    required String cardToken,
  }) async {
    try {
      debugPrint('➕ Adding payment card: $cardType ending in $lastFour');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/cards/',
        {
          'card_type': cardType,
          'last_four': lastFour,
          'expiry_month': expiryMonth,
          'expiry_year': expiryYear,
          'card_token': cardToken,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error adding payment card: $e');
      return ApiResponse.error('Failed to add card: ${e.toString()}');
    }
  }

  /// Delete payment card
  Future<ApiResponse<Map<String, dynamic>>> deletePaymentCard(int cardId) async {
    try {
      debugPrint('🗑️ Deleting payment card: $cardId');
      
      return await _apiClient.delete<Map<String, dynamic>>(
        '/payments/cards/$cardId/',
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error deleting payment card: $e');
      return ApiResponse.error('Failed to delete card: ${e.toString()}');
    }
  }

  /// Set card as default
  Future<ApiResponse<Map<String, dynamic>>> setDefaultCard(int cardId) async {
    try {
      debugPrint('⭐ Setting card as default: $cardId');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/cards/$cardId/set-default/',
        {},
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error setting default card: $e');
      return ApiResponse.error('Failed to set default card: ${e.toString()}');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Format amount as Nigerian currency
  static String formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  /// Format transaction type for display
  static String formatTransactionType(String type) {
    switch (type.toLowerCase()) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'ride_payment':
        return 'Ride Payment';
      case 'ride_earning':
        return 'Ride Earning';
      case 'refund':
        return 'Refund';
      case 'commission':
        return 'Commission';
      case 'bonus':
        return 'Bonus';
      default:
        return type;
    }
  }

  /// Check if transaction is a credit (money in)
  static bool isCredit(String type) {
    return type.toLowerCase() == 'deposit' ||
        type.toLowerCase() == 'ride_earning' ||
        type.toLowerCase() == 'refund' ||
        type.toLowerCase() == 'bonus';
  }

  /// Get transaction icon for display
  static String getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'credit':
      case 'deposit':
      case 'ride_earning':
      case 'refund':
      case 'bonus':
        return '↓'; // Money in
      case 'debit':
      case 'withdrawal':
      case 'ride_payment':
      case 'commission':
        return '↑'; // Money out
      default:
        return '•';
    }
  }
}