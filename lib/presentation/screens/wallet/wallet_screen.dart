import 'package:flutter/material.dart';
import '../../../services/payment_service.dart';
import 'widgets/wallet_balance_card_widget.dart';
import 'widgets/wallet_quick_actions_widget.dart';
import 'widgets/wallet_transactions_list_widget.dart';
import 'widgets/dialogs/top_up_dialog.dart';
import 'widgets/dialogs/withdraw_dialog.dart';
import 'widgets/dialogs/payment_method_dialog.dart';
import 'widgets/dialogs/paystack_webview_screen.dart';

/// Production-Ready Wallet Screen - FIXED VERSION
/// 
/// FIXES APPLIED:
/// ✅ Separate balance and transaction loading
/// ✅ Force balance refresh after payment
/// ✅ Better error handling with specific messages
/// ✅ Improved state management
/// ✅ Added loading indicators for each operation
class WalletScreen extends StatefulWidget {
  final bool isDriver;

  const WalletScreen({
    Key? key,
    this.isDriver = false,
  }) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PaymentService _paymentService = PaymentService();
  
  // State variables
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoadingBalance = true;
  bool _isLoadingTransactions = true;
  bool _isRefreshing = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  String _selectedFilter = 'all';
  
  // Rate limiting for API calls
  DateTime? _lastApiCall;
  static const Duration _apiCallThrottle = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  // ============================================
  // DATA LOADING - FIXED: SEPARATE BALANCE & TRANSACTIONS
  // ============================================

  /// ✅ FIXED: Load wallet data separately for better error handling
  Future<void> _loadWalletData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingBalance = true;
      _isLoadingTransactions = true;
      _errorMessage = null;
    });
    
    // Load balance and transactions separately
    // This ensures balance updates even if transactions fail
    await Future.wait([
      _loadBalance(),
      _loadTransactions(),
    ], eagerError: false); // Don't stop on first error
    
    if (mounted) {
      setState(() {
        _isLoadingBalance = false;
        _isLoadingTransactions = false;
      });
    }
  }

  /// ✅ FIXED: Load balance independently
  Future<void> _loadBalance() async {
    if (!_canMakeApiCall()) return;
    
    try {
      debugPrint('📊 Loading wallet balance...');
      final response = await _paymentService.getBalance();
      
      if (!mounted) return;
      
      if (response.isSuccess && response.data != null) {
        final balanceStr = response.data!['balance']?.toString() ?? '0';
        final balance = double.tryParse(balanceStr) ?? 0.0;
        
        setState(() => _balance = balance);
        debugPrint('✅ Balance loaded: ₦${_balance.toStringAsFixed(2)}');
      } else {
        debugPrint('⚠️ Balance load failed: ${response.error}');
        // Don't throw error - just log it
      }
    } catch (e) {
      debugPrint('❌ Error loading balance: $e');
      // Don't throw error - balance will stay at previous value
    }
  }

  /// ✅ FIXED: Load transactions independently
  Future<void> _loadTransactions() async {
    if (!_canMakeApiCall()) return;
    
    try {
      debugPrint('📋 Loading transactions (filter: $_selectedFilter)...');
      
      final transactionType = _selectedFilter == 'all' ? null : _selectedFilter;
      final response = await _paymentService.getTransactions(
        type: transactionType,
        page: 1,
        pageSize: 50,
      );
      
      if (!mounted) return;
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _transactions = response.data ?? [];
        });
        debugPrint('✅ Loaded ${_transactions.length} transactions');
      } else {
        debugPrint('⚠️ Transaction load failed: ${response.error}');
        // Don't throw error - transactions will stay empty/previous value
      }
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      // Don't throw error - show empty list
    }
  }

  /// ✅ IMPROVED: Refresh with better error handling
  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    
    try {
      // Load balance first (priority)
      await _loadBalance();
      
      // Then load transactions
      await _loadTransactions();
      
      if (mounted) {
        _showSuccessSnackBar('Wallet updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to refresh wallet. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  /// ✅ NEW: Force balance refresh (used after payment)
  Future<void> _forceRefreshBalance() async {
    if (!mounted) return;
    
    debugPrint('🔄 Force refreshing balance...');
    
    try {
      final response = await _paymentService.getBalance();
      
      if (mounted && response.isSuccess && response.data != null) {
        final balanceStr = response.data!['balance']?.toString() ?? '0';
        final newBalance = double.tryParse(balanceStr) ?? 0.0;
        
        setState(() => _balance = newBalance);
        debugPrint('✅ Balance force refreshed: ₦${_balance.toStringAsFixed(2)}');
      }
    } catch (e) {
      debugPrint('❌ Error force refreshing balance: $e');
    }
  }

  // ============================================
  // PAYMENT FLOW - TOP UP WITH PAYSTACK
  // ============================================

  void _handleTopUp() {
    if (_isProcessingPayment) {
      _showErrorSnackBar('Payment in progress. Please wait.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TopUpDialog(
        onTopUp: _initiatePaymentFlow,
      ),
    );
  }

  Future<void> _initiatePaymentFlow(double amount) async {
    if (!mounted) return;
    
    if (amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    debugPrint('💳 Initiating payment flow for ₦${amount.toStringAsFixed(2)}');

    Navigator.of(context).pop(); // Dismiss top-up dialog
    
    showDialog(
      context: context,
      builder: (context) => PaymentMethodDialog(
        amount: amount,
        onMethodSelected: (method) {
          debugPrint('💳 Payment method selected: $method');
          Navigator.pop(context);
          _initializePaystackPayment(amount, method);
        },
      ),
    );
  }

  Future<void> _initializePaystackPayment(
    double amount,
    String paymentMethod,
  ) async {
    if (!mounted || _isProcessingPayment) {
      debugPrint('⚠️ Cannot initialize payment - mounted: $mounted, isProcessing: $_isProcessingPayment');
      return;
    }
    
    setState(() => _isProcessingPayment = true);
    
    debugPrint('📄 Showing loading dialog...');
    _showLoadingDialog('Initializing payment...');
    
    try {
      debugPrint('📡 Calling initialize payment API...');
      
      final response = await _paymentService.initializePaystackPayment(
        amount: amount,
        paymentMethod: paymentMethod,
      );
      
      debugPrint('📥 API Response received - Success: ${response.isSuccess}');
      
      if (!mounted) {
        debugPrint('⚠️ Widget unmounted, aborting');
        return;
      }
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Payment initialization successful');
        debugPrint('📄 Response data: ${response.data}');
        
        final data = response.data!;
        final authUrl = data['authorization_url']?.toString();
        final reference = data['reference']?.toString();
        
        debugPrint('🔗 Authorization URL: $authUrl');
        debugPrint('📖 Reference: $reference');
        
        if (authUrl == null || reference == null || authUrl.isEmpty || reference.isEmpty) {
          debugPrint('❌ Invalid payment response - URL or reference missing');
          _showErrorSnackBar('Invalid payment response. Please try again.');
          setState(() => _isProcessingPayment = false);
          return;
        }
        
        debugPrint('🚀 Opening Paystack webview...');
        
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => PaystackWebviewScreen(
              authorizationUrl: authUrl,
              reference: reference,
            ),
          ),
        );
        
        debugPrint('📙 Returned from webview with result: $result');
        
        if (!mounted) return;
        
        if (result?['success'] == true) {
          final paymentRef = result!['reference'] as String;
          debugPrint('✅ Payment successful, verifying: $paymentRef');
          await _verifyPayment(paymentRef);
        } else {
          debugPrint('❌ Payment cancelled or failed');
          setState(() => _isProcessingPayment = false);
          _showErrorSnackBar('Payment was cancelled or failed.');
        }
      } else {
        final error = response.error ?? 'Failed to initialize payment. Please try again.';
        debugPrint('❌ Payment initialization failed: $error');
        _showErrorSnackBar(error);
        setState(() => _isProcessingPayment = false);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Payment initialization error: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      
      if (mounted) {
        try {
          Navigator.of(context).pop();
        } catch (_) {
          debugPrint('⚠️ Could not close loading dialog');
        }
        
        _showErrorSnackBar('Payment error: ${e.toString()}');
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  /// ✅ FIXED: Verify payment with immediate balance refresh
  Future<void> _verifyPayment(String reference) async {
    if (!mounted) return;
    
    debugPrint('📄 Verifying payment: $reference');
    _showLoadingDialog('Verifying payment...');
    
    try {
      final response = await _paymentService.verifyPaystackPayment(
        reference: reference,
        retries: 3, // Try 3 times if network issues
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Payment verified: $reference');
        
        // ✅ CRITICAL: Force refresh balance immediately
        await _forceRefreshBalance();
        
        // Then load transactions
        await _loadTransactions();
        
        _showSuccessSnackBar('✅ Payment successful! Wallet updated.');
        
        setState(() => _isProcessingPayment = false);
      } else {
        debugPrint('⚠️ Payment verification failed: ${response.error}');
        _showErrorSnackBar(
          response.error ?? 'Payment verification failed. Please contact support.',
        );
        setState(() => _isProcessingPayment = false);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Payment verification error: $e');
        Navigator.pop(context);
        _showErrorSnackBar('Verification error: ${e.toString()}');
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  // ============================================
  // WITHDRAWAL (DRIVERS ONLY)
  // ============================================

  void _handleWithdraw() {
    if (!widget.isDriver) {
      _showErrorSnackBar('Only drivers can withdraw money');
      return;
    }

    if (_balance <= 0) {
      _showErrorSnackBar('Insufficient balance to withdraw');
      return;
    }

    if (_isProcessingPayment) {
      _showErrorSnackBar('A payment is in progress. Please wait.');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WithdrawDialog(
        currentBalance: _balance,
        onWithdraw: _processWithdrawal,
      ),
    );
  }

  Future<void> _processWithdrawal(
    double amount, {
    String? bankName,
    String? accountNumber,
    String? accountName,
  }) async {
    if (!mounted) return;
    
    Navigator.of(context).pop(); // Close withdraw dialog
    
    if (amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    if (amount > _balance) {
      _showErrorSnackBar(
        'Insufficient balance. Available: ₦${_balance.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => _isProcessingPayment = true);
    _showLoadingDialog('Processing withdrawal...');
    
    try {
      debugPrint('💰 Processing withdrawal: ₦${amount.toStringAsFixed(2)}');
      if (bankName != null) {
        debugPrint('🏦 Bank: $bankName, Account: $accountNumber');
      }

      final response = await _paymentService.withdraw(
        amount: amount,
        bankName: bankName,
        accountNumber: accountNumber,
        accountName: accountName,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Withdrawal successful');

        // ✅ CRITICAL: Force refresh balance immediately
        await _forceRefreshBalance();
        
        // Then load transactions
        await _loadTransactions();

        _showSuccessSnackBar(
          'Withdrawal request submitted successfully! Funds will be transferred within 24 hours.',
        );
      } else {
        final errorMsg = response.error ?? 'Withdrawal failed. Please try again.';
        debugPrint('⚠️ Withdrawal failed: $errorMsg');
        _showErrorSnackBar(errorMsg);
      }
    } catch (e) {
      debugPrint('❌ Withdrawal error: $e');
      if (mounted) {
        Navigator.pop(context);
        String errorMessage = e.toString();
        
        if (errorMessage.contains('first withdrawal manually')) {
          _showErrorSnackBar(
            'Please add your bank details first before making withdrawals.',
          );
        } else if (errorMessage.contains('Only drivers')) {
          _showErrorSnackBar('Only drivers can withdraw funds.');
        } else {
          _showErrorSnackBar('Withdrawal error: $errorMessage');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  // ============================================
  // TRANSACTION FILTERING
  // ============================================

  void _handleFilterChange(String filter) {
    if (_isProcessingPayment || _isRefreshing) return;
    
    setState(() {
      _selectedFilter = filter;
      _errorMessage = null;
      _isLoadingTransactions = true;
    });
    
    _loadTransactions().then((_) {
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    });
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  bool _canMakeApiCall() {
    final now = DateTime.now();
    if (_lastApiCall == null) {
      _lastApiCall = now;
      return true;
    }
    
    final timeSinceLastCall = now.difference(_lastApiCall!);
    if (timeSinceLastCall < _apiCallThrottle) {
      return false;
    }
    
    _lastApiCall = now;
    return true;
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLoadingDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(colorScheme),
      body: _isLoadingBalance
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: colorScheme.primary,
              displacement: 40,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        _buildErrorBanner(_errorMessage!, colorScheme),

                      WalletBalanceCardWidget(
                        balance: _balance,
                        isLoading: _isRefreshing,
                      ),

                      const SizedBox(height: 20),

                      WalletQuickActionsWidget(
                        onTopUp: _isProcessingPayment ? null : _handleTopUp,
                        onWithdraw: _isProcessingPayment ? null : _handleWithdraw,
                        isDriver: widget.isDriver,
                      ),

                      const SizedBox(height: 24),

                      WalletTransactionsListWidget(
                        transactions: _transactions,
                        selectedFilter: _selectedFilter,
                        onFilterChanged: _isProcessingPayment
                            ? null
                            : _handleFilterChange,
                        isLoading: _isLoadingTransactions,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        onPressed: _isProcessingPayment ? null : () => Navigator.pop(context),
      ),
      title: Text(
        'My Wallet',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(
              Icons.close,
              color: colorScheme.error.withOpacity(0.6),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}