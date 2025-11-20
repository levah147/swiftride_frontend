import 'package:flutter/material.dart';
import '../../../services/wallet_service.dart';
import 'widgets/wallet_balance_card_widget.dart';
import 'widgets/wallet_quick_actions_widget.dart';
import 'widgets/wallet_transactions_list_widget.dart';
import 'widgets/dialogs/top_up_dialog.dart';
import 'widgets/dialogs/withdraw_dialog.dart';

/// Wallet Screen - Main wallet management screen
/// Uses modular widgets for clean, maintainable code
/// Shows: Balance card, quick actions, transaction history
class WalletScreen extends StatefulWidget {
  final bool isDriver; // Determines if withdraw button shows

  const WalletScreen({
    Key? key,
    this.isDriver = false,
  }) : super(key: key);

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  
  double _balance = 0.0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  String _selectedFilter = 'all'; // 'all', 'credit', 'debit'

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  // ============================================
  // DATA LOADING
  // ============================================

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);
    
    await Future.wait([
      _loadBalance(),
      _loadTransactions(),
    ]);
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadBalance() async {
    final response = await _walletService.getBalance();
    
    if (mounted) {
      if (response.isSuccess && response.data != null) {
        setState(() {
          _balance = double.parse(response.data!['balance'].toString());
        });
        debugPrint('💰 Balance: ₦$_balance');
      }
    }
  }

  Future<void> _loadTransactions() async {
    final response = await _walletService.getTransactions(
      transactionType: _selectedFilter == 'all' ? null : _selectedFilter,
    );
    
    if (mounted) {
      if (response.isSuccess && response.data != null) {
        setState(() {
          _transactions = response.data!;
        });
        debugPrint('📜 Loaded ${_transactions.length} transactions');
      } else {
        setState(() {
          _errorMessage = response.error;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadWalletData();
    setState(() => _isRefreshing = false);
  }

  // ============================================
  // ACTIONS
  // ============================================

  void _handleTopUp() {
    showDialog(
      context: context,
      builder: (context) => TopUpDialog(
        onTopUp: _processTopUp,
      ),
    );
  }

  Future<void> _processTopUp(double amount) async {
    final response = await _walletService.topUp(
      amount: amount,
      description: 'Wallet top-up',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      Navigator.of(context).pop(); // Close dialog
      _showSuccessSnackBar('₦${amount.toStringAsFixed(0)} added successfully');
      _loadWalletData(); // Refresh
    } else {
      throw Exception(response.error ?? 'Failed to top up');
    }
  }

  void _handleWithdraw() {
    if (!widget.isDriver) {
      _showErrorSnackBar('Only drivers can withdraw money');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => WithdrawDialog(
        currentBalance: _balance,
        onWithdraw: _processWithdraw,
      ),
    );
  }

  Future<void> _processWithdraw(double amount) async {
    final response = await _walletService.withdraw(
      amount: amount,
      description: 'Withdrawal',
    );

    if (!mounted) return;

    if (response.isSuccess) {
      Navigator.of(context).pop(); // Close dialog
      _showSuccessSnackBar('₦${amount.toStringAsFixed(0)} withdrawn successfully');
      _loadWalletData(); // Refresh
    } else {
      throw Exception(response.error ?? 'Failed to withdraw');
    }
  }

  void _handleFilterChange(String filter) {
    setState(() => _selectedFilter = filter);
    _loadTransactions();
  }

  // ============================================
  // UI HELPERS
  // ============================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
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
          IconButton(
            icon: Icon(Icons.history, color: colorScheme.onSurface),
            onPressed: () {
              // Could navigate to full transaction history
              debugPrint('View full history');
            },
            tooltip: 'Transaction History',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshData,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card Widget
                      WalletBalanceCardWidget(
                        balance: _balance,
                        isLoading: _isRefreshing,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Quick Actions Widget
                      WalletQuickActionsWidget(
                        onTopUp: _handleTopUp,
                        onWithdraw: _handleWithdraw,
                        isDriver: widget.isDriver,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transactions List Widget
                      WalletTransactionsListWidget(
                        transactions: _transactions,
                        selectedFilter: _selectedFilter,
                        onFilterChanged: _handleFilterChange,
                        isLoading: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}