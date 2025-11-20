import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/wallet_service.dart';
import '../../../../constants/colors.dart';

/// Wallet Transactions List Widget - Displays transaction history with filters
/// Shows all transactions with credit/debit filtering
class WalletTransactionsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final bool isLoading;

  const WalletTransactionsListWidget({
    Key? key,
    required this.transactions,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips
        _buildFilterChips(colorScheme),
        
        const SizedBox(height: 16),
        
        // Transactions Header
        if (transactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${transactions.length} total',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        
        // Loading State
        if (isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          )
        
        // Empty State
        else if (transactions.isEmpty)
          _buildEmptyState(colorScheme)
        
        // Transactions List
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionItem(
                transactions[index],
                colorScheme,
                isDark,
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return Row(
      children: [
        _buildFilterChip('All', 'all', colorScheme),
        const SizedBox(width: 8),
        _buildFilterChip('Credit', 'credit', colorScheme),
        const SizedBox(width: 8),
        _buildFilterChip('Debit', 'debit', colorScheme),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onFilterChanged(value),
      backgroundColor: colorScheme.surfaceVariant,
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 14,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : colorScheme.outline,
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> transaction,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    final type = transaction['transaction_type'] as String;
    final amount = double.parse(transaction['amount'].toString());
    final description = transaction['description'] as String? ?? 'Transaction';
    final timestamp = DateTime.parse(transaction['created_at'] as String);
    final isCredit = WalletService.isCredit(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outline
              : colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCredit
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  WalletService.formatTransactionType(type),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${WalletService.formatCurrency(amount)}',
                style: TextStyle(
                  color: isCredit ? Colors.green : Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCredit ? 'Credit' : 'Debit',
                  style: TextStyle(
                    color: isCredit ? Colors.green : Colors.red,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    String message;
    String subtitle;
    
    switch (selectedFilter) {
      case 'credit':
        message = 'No credit transactions';
        subtitle = 'Your income transactions will appear here';
        break;
      case 'debit':
        message = 'No debit transactions';
        subtitle = 'Your expense transactions will appear here';
        break;
      default:
        message = 'No transactions yet';
        subtitle = 'Your transaction history will appear here';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}