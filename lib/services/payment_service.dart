import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Payment Service - Comprehensive payment handling
/// 
/// Endpoints matched with Django backend:
/// - GET /api/payments/wallet/ - Get wallet details
/// - GET /api/payments/transactions/ - Get transaction history
/// - POST /api/payments/deposit/initialize/ - Initialize Paystack payment
/// - GET /api/payments/deposit/verify/ - Verify Paystack payment
/// - POST /api/payments/withdrawals/ - Create withdrawal request
/// - GET /api/payments/banks/ - List Nigerian banks
/// - POST /api/payments/banks/validate/ - Validate bank account
/// - POST /api/payments/cards/ - Add payment card
/// - DELETE /api/payments/cards/{id}/ - Delete payment card
/// - POST /api/payments/cards/{id}/set-default/ - Set default card
class PaymentService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // WALLET OPERATIONS
  // ============================================

  /// Get wallet details (balance, status, etc.)
  /// 
  /// Returns:
  /// {
  ///   "id": 1,
  ///   "balance": "5000.00",
  ///   "formatted_balance": "₦5,000.00",
  ///   "is_active": true,
  ///   "is_locked": false,
  ///   "created_at": "2025-11-23T...",
  ///   "updated_at": "2025-11-23T..."
  /// }
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
  /// 
  /// This is an alias endpoint for /payments/wallet/
  /// Returns: { "balance": "5000.00", "formatted": "₦5,000.00" }
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
  // TRANSACTION OPERATIONS
  // ============================================

  /// Get transaction history
  /// 
  /// Query params:
  /// - type: Filter by 'deposit', 'withdrawal', 'ride_payment', 'ride_earning', etc.
  /// - status: Filter by 'completed', 'pending', 'failed'
  /// - page: Page number (default: 1)
  /// 
  /// Returns paginated list of transactions
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
          if (type != null) 'transaction_type': type,
          if (status != null) 'status': status,
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // Handle paginated response
        if (response.data!.containsKey('results')) {
          final results = (response.data!['results'] as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          
          debugPrint('✅ Loaded ${results.length} transactions');
          return ApiResponse.success(results, statusCode: response.statusCode);
        } else if (response.data is List) {
          // Handle direct list response
          final results = (response.data as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          
          return ApiResponse.success(results, statusCode: response.statusCode);
        }
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
  /// 
  /// Creates a Paystack authorization link for payment
  /// 
  /// Returns:
  /// {
  ///   "authorization_url": "https://checkout.paystack.com/...",
  ///   "access_code": "access_code_value",
  ///   "reference": "reference_value"
  /// }
  Future<ApiResponse<Map<String, dynamic>>> initializePaystackPayment({
    required double amount,
    required String paymentMethod, // 'card', 'bank_transfer', 'ussd'
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

  /// Verify Paystack payment (Step 2)
  /// 
  /// Called after user completes payment on Paystack checkout
  /// 
  /// Returns:
  /// {
  ///   "status": true,
  ///   "message": "Payment verified",
  ///   "reference": "reference_value",
  ///   "amount": 100000,  # in kobo
  ///   "balance": "10000.00"  # new wallet balance
  /// }
  Future<ApiResponse<Map<String, dynamic>>> verifyPaystackPayment({
    required String reference,
  }) async {
    try {
      debugPrint('✅ Verifying Paystack payment with reference: $reference');
      
      return await _apiClient.get<Map<String, dynamic>>(
        '/payments/deposit/verify/',
        queryParams: {'reference': reference},
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error verifying payment: $e');
      return ApiResponse.error('Failed to verify payment: ${e.toString()}');
    }
  }

  /// Deposit funds to wallet (Legacy - Direct Deposit)
  /// 
  /// Note: For Paystack payments, use initializePaystackPayment() instead
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
  /// 
  /// Returns list of banks for withdrawal selection
  /// Each bank has: code, name, slug
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
  /// 
  /// Verifies account number exists for given bank
  /// 
  /// Returns:
  /// {
  ///   "account_number": "1234567890",
  ///   "account_name": "John Doe",
  ///   "bank_code": "044",
  ///   "valid": true
  /// }
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
  /// 
  /// Returns list of withdrawal requests with statuses
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
  /// 
  /// Returns single withdrawal with full details
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
  /// 
  /// Creates withdrawal request to bank account
  /// 
  /// Returns:
  /// {
  ///   "id": 1,
  ///   "amount": "5000.00",
  ///   "status": "pending",
  ///   "bank_name": "GTBank",
  ///   "account_number": "1234567890",
  ///   "account_name": "John Doe",
  ///   "created_at": "2025-11-23T..."
  /// }
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
  /// 
  /// Note: For Paystack-integrated withdrawals, use requestWithdrawalPaystack()
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

  /// Quick withdrawal for drivers using preferred bank account (DRIVER-SPECIFIC)
  /// 
  /// Automatically retrieves driver's saved bank account and creates withdrawal
  /// request in one call. This is the simplified driver withdrawal method.
  /// 
  /// Parameters:
  /// - amount: Withdrawal amount (minimum ₦100.00)
  /// 
  /// Requirements:
  /// - User must be authenticated driver
  /// - Driver must have made at least one withdrawal to set preferred bank
  /// 
  /// Returns:
  /// {
  ///   "message": "Withdrawal request created successfully",
  ///   "withdrawal": {
  ///     "id": 1,
  ///     "amount": "5000.00",
  ///     "status": "pending",
  ///     "bank_name": "GTBank",
  ///     "account_number": "1234567890",
  ///     "account_name": "John Doe",
  ///     "created_at": "2025-11-23T..."
  ///   },
  ///   "new_balance": "15000.00"
  /// }
  Future<ApiResponse<Map<String, dynamic>>> withdraw({
    required double amount,
  }) async {
    try {
      debugPrint('🏦 Requesting quick withdrawal: ₦$amount');
      
      return await _apiClient.post<Map<String, dynamic>>(
        '/payments/withdrawals/quick/',
        {
          'amount': amount,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ Error requesting withdrawal: $e');
      return ApiResponse.error('Failed to request withdrawal: ${e.toString()}');
    }
  }

  // ============================================
  // PAYMENT CARD OPERATIONS
  // ============================================

  /// Get saved payment cards
  /// 
  /// Returns list of user's saved payment cards
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
  /// 
  /// Saves a new payment card to user's wallet
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
  /// 
  /// Removes a saved payment card
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
  /// 
  /// Makes this card the default payment method
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
}