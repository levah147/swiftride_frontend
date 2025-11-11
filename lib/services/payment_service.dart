import 'api_client.dart';

class PaymentService {
  final ApiClient _apiClient = ApiClient.instance;

  /// Get wallet details
  Future<ApiResponse<Map<String, dynamic>>> getWallet() async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/payments/wallet/',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Deposit funds to wallet
  Future<ApiResponse<Map<String, dynamic>>> depositFunds({
    required double amount,
    required String paymentMethod, // 'card' or 'bank_transfer'
  }) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/payments/deposit/',
      {
        'amount': amount,
        'payment_method': paymentMethod,
      },
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get transaction history
  Future<ApiResponse<List<Map<String, dynamic>>>> getTransactions({
    String? type, // 'deposit', 'withdrawal', 'ride_payment', 'ride_earning', etc.
    String? status, // 'pending', 'completed', 'failed'
  }) async {
    return await _apiClient.get<List<Map<String, dynamic>>>(
      '/payments/transactions/',
      queryParams: {
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      },
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
      },
    );
  }

  /// Process payment for a completed ride
  Future<ApiResponse<Map<String, dynamic>>> processRidePayment(
      int rideId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/payments/rides/$rideId/pay/',
      {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Get saved payment cards
  Future<ApiResponse<List<Map<String, dynamic>>>> getPaymentCards() async {
    return await _apiClient.get<List<Map<String, dynamic>>>(
      '/payments/cards/',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
      },
    );
  }

  /// Add payment card
  Future<ApiResponse<Map<String, dynamic>>> addPaymentCard({
    required String cardType, // 'visa', 'mastercard', 'verve'
    required String lastFour,
    required int expiryMonth,
    required int expiryYear,
    required String cardToken,
  }) async {
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
  }

  /// Delete payment card
  Future<ApiResponse<Map<String, dynamic>>> deletePaymentCard(int cardId) async {
    return await _apiClient.delete<Map<String, dynamic>>(
      '/payments/cards/$cardId/',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  /// Set card as default
  Future<ApiResponse<Map<String, dynamic>>> setDefaultCard(int cardId) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/payments/cards/$cardId/set-default/',
      {},
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }

  // ==================== Driver Withdrawals ====================

  /// Get withdrawal history (drivers only)
  Future<ApiResponse<List<Map<String, dynamic>>>> getWithdrawals() async {
    return await _apiClient.get<List<Map<String, dynamic>>>(
      '/payments/withdrawals/',
      fromJson: (json) {
        if (json is List) {
          return json.map((e) => e as Map<String, dynamic>).toList();
        }
        return [];
      },
    );
  }

  /// Request withdrawal (drivers only)
  Future<ApiResponse<Map<String, dynamic>>> requestWithdrawal({
    required double amount,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
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
  }

  /// Get withdrawal details
  Future<ApiResponse<Map<String, dynamic>>> getWithdrawalDetails(
      int withdrawalId) async {
    return await _apiClient.get<Map<String, dynamic>>(
      '/payments/withdrawals/$withdrawalId/',
      fromJson: (json) => json as Map<String, dynamic>,
    );
  }
}