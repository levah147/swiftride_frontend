import 'package:flutter/material.dart';
import '../../../../services/payment_service.dart';
import 'wallet_transactions_list_widget.dart';

/// Transaction History Screen
/// Shows complete transaction history with filtering
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    
    try {
      final transactionType = _selectedFilter == 'all' ? null : _selectedFilter;
      final response = await _paymentService.getTransactions(
        type: transactionType,
        pageSize: 100, // Show more transactions
      );
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          _transactions = response.data ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
          'Transaction History',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: WalletTransactionsListWidget(
            transactions: _transactions,
            selectedFilter: _selectedFilter,
            onFilterChanged: (filter) {
              setState(() => _selectedFilter = filter);
              _loadTransactions();
            },
            isLoading: _isLoading,
          ),
        ),
      ),
    );
  }
}