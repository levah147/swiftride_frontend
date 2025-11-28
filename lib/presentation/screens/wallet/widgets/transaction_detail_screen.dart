import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../services/payment_service.dart';

/// Transaction Detail Screen
/// Shows complete information about a transaction
class TransactionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parse transaction data
    final type = transaction['transaction_type'] as String? ?? 'unknown';
    final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0.0;
    final reference = transaction['reference'] as String? ?? 'N/A';
    final description = transaction['description'] as String? ?? 'Transaction';
    final status = transaction['status'] as String? ?? 'unknown';
    final paymentMethod = transaction['payment_method'] as String? ?? 'unknown';
    final createdAtStr = transaction['created_at'] as String?;
    final completedAtStr = transaction['completed_at'] as String?;
    final balanceBefore = double.tryParse(transaction['balance_before']?.toString() ?? '0') ?? 0.0;
    final balanceAfter = double.tryParse(transaction['balance_after']?.toString() ?? '0') ?? 0.0;
    final isCredit = PaymentService.isCredit(type);

    // Parse timestamps
    DateTime? createdAt;
    DateTime? completedAt;
    try {
      if (createdAtStr != null) createdAt = DateTime.parse(createdAtStr);
      if (completedAtStr != null) completedAt = DateTime.parse(completedAtStr);
    } catch (e) {
      debugPrint('Error parsing dates: $e');
    }

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
          'Transaction Details',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            _buildAmountCard(context, amount, isCredit, colorScheme),

            const SizedBox(height: 20),

            // Status Badge
            _buildStatusBadge(status, colorScheme),

            const SizedBox(height: 24),

            // Transaction Info
            _buildInfoCard(
              context,
              colorScheme,
              [
                _InfoItem('Type', PaymentService.formatTransactionType(type)),
                _InfoItem('Reference', reference, copyable: true),
                _InfoItem('Payment Method', _formatPaymentMethod(paymentMethod)),
                _InfoItem('Description', description),
              ],
            ),

            const SizedBox(height: 16),

            // Balance Info
            _buildInfoCard(
              context,
              colorScheme,
              [
                _InfoItem('Balance Before', PaymentService.formatCurrency(balanceBefore)),
                _InfoItem('Balance After', PaymentService.formatCurrency(balanceAfter)),
                _InfoItem('Change', '${isCredit ? '+' : '-'}${PaymentService.formatCurrency(amount)}',
                    color: isCredit ? Colors.green : Colors.red),
              ],
            ),

            const SizedBox(height: 16),

            // Timestamps
            _buildInfoCard(
              context,
              colorScheme,
              [
                _InfoItem('Created', createdAt != null ? _formatFullDate(createdAt) : 'N/A'),
                if (completedAt != null)
                  _InfoItem('Completed', _formatFullDate(completedAt)),
              ],
            ),

            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context, double amount, bool isCredit, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCredit
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.red.shade400, Colors.red.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCredit ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            '${isCredit ? '+' : '-'}${PaymentService.formatCurrency(amount)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCredit ? 'Money Received' : 'Money Spent',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Pending';
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = 'Failed';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        statusText = status;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme, List<_InfoItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              if (index > 0) const Divider(height: 24),
              _buildInfoRow(context, colorScheme, item),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, ColorScheme colorScheme, _InfoItem item) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  item.value,
                  style: TextStyle(
                    color: item.color ?? colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              if (item.copyable) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Copied to clipboard'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(
                    Icons.copy,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return 'Card Payment';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'ussd':
        return 'USSD';
      case 'wallet':
        return 'Wallet';
      case 'cash':
        return 'Cash';
      default:
        return method;
    }
  }

  String _formatFullDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }
}

class _InfoItem {
  final String label;
  final String value;
  final bool copyable;
  final Color? color;

  _InfoItem(this.label, this.value, {this.copyable = false, this.color});
}