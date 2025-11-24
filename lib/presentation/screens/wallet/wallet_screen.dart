import 'package:flutter/material.dart';
import '../../../services/payment_service.dart';
import 'widgets/wallet_balance_card_widget.dart';
import 'widgets/wallet_quick_actions_widget.dart';
import 'widgets/wallet_transactions_list_widget.dart';
import 'widgets/dialogs/top_up_dialog.dart';
import 'widgets/dialogs/withdraw_dialog.dart';
import 'widgets/dialogs/payment_method_dialog.dart';
import 'widgets/dialogs/paystack_webview_screen.dart';

/// Production-Ready Wallet Screen
/// Features:
/// - Complete Paystack integration with payment flow
/// - Comprehensive error handling
/// - Loading states and user feedback
/// - Proper null safety and validation
/// - Rate limiting for API calls
/// - Transaction history with filtering
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
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isProcessingPayment = false;
  String? _errorMessage;
  String _selectedFilter = 'all';
  
  // Rate limiting for API calls (prevent spam)
  DateTime? _lastApiCall;
  static const Duration _apiCallThrottle = Duration(milliseconds: 1000);

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  // ============================================
  // DATA LOADING WITH ERROR HANDLING
  // ============================================

  Future<void> _loadWalletData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.wait([
        _loadBalance(),
        _loadTransactions(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load wallet data. Please try again.';
        });
        debugPrint('❌ Error loading wallet: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadBalance() async {
    if (!_canMakeApiCall()) return;
    
    try {
      final response = await _paymentService.getBalance();
      
      if (!mounted) return;
      
      if (response.isSuccess && response.data != null) {
        final balanceStr = response.data!['balance']?.toString() ?? '0';
        final balance = double.tryParse(balanceStr) ?? 0.0;
        
        setState(() => _balance = balance);
        debugPrint('✅ Balance loaded: ₦${_balance.toStringAsFixed(2)}');
      } else {
        debugPrint('⚠️ Balance load failed: ${response.error}');
      }
    } catch (e) {
      debugPrint('❌ Error loading balance: $e');
      rethrow;
    }
  }

  Future<void> _loadTransactions() async {
    if (!_canMakeApiCall()) return;
    
    try {
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
      }
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
      rethrow;
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    
    try {
      await _loadWalletData();
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
    
    // Validate amount
    if (amount <= 0) {
      _showErrorSnackBar('Please enter a valid amount');
      return;
    }

    // Dismiss the dialog
    Navigator.of(context).pop();
    
    // Show payment method selection
    showDialog(
      context: context,
      builder: (context) => PaymentMethodDialog(
        amount: amount,
        onMethodSelected: (method) {
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
    if (!mounted || _isProcessingPayment) return;
    
    setState(() => _isProcessingPayment = true);
    _showLoadingDialog('Initializing payment...');
    
    try {
      final response = await _paymentService.initializePaystackPayment(
        amount: amount,
        paymentMethod: paymentMethod,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        final authUrl = data['authorization_url']?.toString();
        final reference = data['reference']?.toString();
        
        if (authUrl == null || reference == null) {
          _showErrorSnackBar('Invalid payment response. Please try again.');
          setState(() => _isProcessingPayment = false);
          return;
        }
        
        debugPrint('✅ Payment initialized: $reference');
        
        // Navigate to Paystack webview
        final result = await Navigator.push<Map<String, dynamic>>(
          context,
          MaterialPageRoute(
            builder: (context) => PaystackWebviewScreen(
              authorizationUrl: authUrl,
              reference: reference,
            ),
          ),
        );
        
        if (result?['success'] == true && mounted) {
          await _verifyPayment(result!['reference'] as String);
        } else if (mounted) {
          setState(() => _isProcessingPayment = false);
          _showErrorSnackBar('Payment was cancelled or failed.');
        }
      } else {
        _showErrorSnackBar(
          response.error ?? 'Failed to initialize payment. Please try again.',
        );
        setState(() => _isProcessingPayment = false);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Payment initialization error: $e');
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Payment error: ${e.toString()}');
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  Future<void> _verifyPayment(String reference) async {
    if (!mounted) return;
    
    _showLoadingDialog('Verifying payment...');
    
    try {
      final response = await _paymentService.verifyPaystackPayment(
        reference: reference,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (response.isSuccess && response.data != null) {
        debugPrint('✅ Payment verified: $reference');
        _showSuccessSnackBar('✅ Payment successful! Wallet updated.');
        
        // Reload wallet data
        await _loadWalletData();
        
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
        Navigator.pop(context); // Close loading dialog
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

  Future<void> _processWithdrawal(double amount) async {
    if (!mounted) return;
    
    if (amount <= 0 || amount > _balance) {
      _showErrorSnackBar('Please enter a valid withdrawal amount');
      return;
    }

    Navigator.of(context).pop(); // Close dialog
    setState(() => _isProcessingPayment = true);
    _showLoadingDialog('Processing withdrawal...');
    
    try {
      final response = await _paymentService.withdraw(
        amount: amount,
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (response.isSuccess) {
        debugPrint('✅ Withdrawal processed: ₦$amount');
        _showSuccessSnackBar('✅ Withdrawal requested successfully!');
        await _loadWalletData();
        setState(() => _isProcessingPayment = false);
      } else {
        _showErrorSnackBar(
          response.error ?? 'Withdrawal failed. Please try again.',
        );
        setState(() => _isProcessingPayment = false);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('❌ Withdrawal error: $e');
        Navigator.pop(context); // Close loading dialog
        _showErrorSnackBar('Withdrawal error: ${e.toString()}');
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
    });
    
    _loadTransactions();
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
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
      body: _isLoading
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
                      // Error Banner
                      if (_errorMessage != null)
                        _buildErrorBanner(_errorMessage!, colorScheme),

                      // Balance Card
                      WalletBalanceCardWidget(
                        balance: _balance,
                        isLoading: _isRefreshing,
                      ),

                      const SizedBox(height: 20),

                      // Quick Actions
                      WalletQuickActionsWidget(
                        onTopUp: _isProcessingPayment ? null : _handleTopUp,
                        onWithdraw: _isProcessingPayment ? null : _handleWithdraw,
                        isDriver: widget.isDriver,
                      ),

                      const SizedBox(height: 24),

                      // Transactions
                      WalletTransactionsListWidget(
                        transactions: _transactions,
                        selectedFilter: _selectedFilter,
                        onFilterChanged: _isProcessingPayment
                            ? null
                            : _handleFilterChange,
                        isLoading: false,
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
      actions: [
        if (!_isProcessingPayment)
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.onSurface),
            onPressed: () => debugPrint('📊 View full transaction history'),
            tooltip: 'Transaction History',
          ),
      ],
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