import 'package:flutter/material.dart';
import '../../wallet/widgets/transaction_history_screen.dart';

/// Production-Ready Wallet Quick Actions Widget
/// Features:
/// - Null-safe callback handling
/// - Disabled state management
/// - Smooth animations
/// - Accessibility labels
/// - History navigation to dedicated screen
class WalletQuickActionsWidget extends StatelessWidget {
  final VoidCallback? onTopUp;
  final VoidCallback? onWithdraw;
  final bool isDriver;

  const WalletQuickActionsWidget({
    Key? key,
    required this.onTopUp,
    required this.onWithdraw,
    required this.isDriver,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Top Up Button (always visible)
        Expanded(
          child: _buildActionButton(
            context: context,
            icon: Icons.add_circle_outline,
            label: 'Top Up',
            subtitle: 'Add Money',
            color: Colors.green,
            onTap: onTopUp,
            enabled: onTopUp != null,
          ),
        ),

        const SizedBox(width: 12),

        // Withdraw Button (drivers only) OR History Button (riders only)
        if (isDriver)
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.arrow_circle_up_outlined,
              label: 'Withdraw',
              subtitle: 'Cash Out',
              color: Colors.orange,
              onTap: onWithdraw,
              enabled: onWithdraw != null,
            ),
          )
        else
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.history,
              label: 'History',
              subtitle: 'View All',
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TransactionHistoryScreen(),
                  ),
                );
              },
              enabled: true,
            ),
          ),
      ],
    );
  }

  /// Build individual action button
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled && onTap != null ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: enabled
                ? color.withOpacity(0.08)
                : colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? color.withOpacity(0.2)
                  : colorScheme.outline.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled
                      ? color.withOpacity(0.15)
                      : colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: enabled ? color : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 28,
                ),
              ),

              const SizedBox(height: 12),

              // Label
              Text(
                label,
                style: TextStyle(
                  color: enabled ? color : colorScheme.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  color: enabled
                      ? color.withOpacity(0.7)
                      : colorScheme.onSurfaceVariant.withOpacity(0.3),
                  fontSize: 12,
                ),
              ),

              // Disabled indicator
              if (!enabled) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Processing',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}