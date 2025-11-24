import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../services/wallet_service.dart';
import '../../../../constants/colors.dart';

/// Production-Ready Wallet Transactions List Widget
/// Features:
/// - Transaction filtering (All/Credit/Debit)
/// - Proper null safety
/// - Empty states with helpful messages
/// - Smooth animations
/// - Comprehensive error handling
class WalletTransactionsListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String selectedFilter;
  final Function(String)? onFilterChanged;
  final bool isLoading;

  const WalletTransactionsListWidget({
    Key? key,
    required this.transactions,
    required this.selectedFilter,
    this.onFilterChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Chips Section
        if (transactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildFilterChips(colorScheme),
          ),

        // Transactions Header or Loading
        if (transactions.isNotEmpty && !isLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTransactionsHeader(colorScheme),
          ),

        // Loading State
        if (isLoading)
          _buildLoadingState(colorScheme)
        // Empty State
        else if (transactions.isEmpty)
          _buildEmptyState(colorScheme)
        // Transactions List
        else
          _buildTransactionsList(colorScheme),
      ],
    );
  }

  // ============================================
  // UI BUILDERS
  // ============================================

  Widget _buildFilterChips(ColorScheme colorScheme) {
    final filters = [
      ('All', 'all'),
      ('Credit', 'credit'),
      ('Debit', 'debit'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final label = filter.$1;
          final value = filter.$2;
          final isSelected = selectedFilter == value;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (isSelected) =>
                  onFilterChanged?.call(value),
              backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: isSelected
                    ? AppColors.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionsHeader(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Transactions',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${transactions.length} total',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading transactions...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    String message;
    String subtitle;
    IconData icon;

    switch (selectedFilter) {
      case 'credit':
        message = 'No income yet';
        subtitle = 'Your income transactions will appear here';
        icon = Icons.arrow_downward;
        break;
      case 'debit':
        message = 'No expenses yet';
        subtitle = 'Your expense transactions will appear here';
        icon = Icons.arrow_upward;
        break;
      default:
        message = 'No transactions yet';
        subtitle = 'Your transaction history will appear here';
        icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
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

  Widget _buildTransactionsList(ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(
          transactions[index],
          colorScheme,
          index,
        );
      },
    );
  }

  Widget _buildTransactionItem(
    Map<String, dynamic> transaction,
    ColorScheme colorScheme,
    int index,
  ) {
    try {
      final type = transaction['transaction_type'] as String? ?? 'unknown';
      final amount =
          double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
      final description =
          transaction['description'] as String? ?? 'Transaction';
      final createdAtStr = transaction['created_at'] as String?;
      final isCredit = WalletService.isCredit(type);

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(createdAtStr ?? DateTime.now().toIso8601String());
      } catch (e) {
        timestamp = DateTime.now();
      }

      return AnimatedSlide(
        offset: Offset.zero,
        duration: Duration(milliseconds: 300 + (index * 50)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
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
                  isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: isCredit ? Colors.green : Colors.red,
                  size: 18,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(timestamp),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: (isCredit ? Colors.green : Colors.red)
                          .withOpacity(0.1),
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
        ),
      );
    } catch (e) {
      debugPrint('❌ Error building transaction item: $e');
      return const SizedBox.shrink();
    }
  }

  /// Format datetime to readable string
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final transactionDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (transactionDate == today) {
      return 'Today • ${DateFormat('h:mm a').format(dateTime)}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday • ${DateFormat('h:mm a').format(dateTime)}';
    } else if (now.difference(dateTime).inDays < 7) {
      return '${DateFormat('EEEE').format(dateTime)} • ${DateFormat('h:mm a').format(dateTime)}';
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
    }
  }
}