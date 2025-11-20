import 'package:flutter/material.dart';

/// Wallet Quick Actions Widget - Top Up and Withdraw buttons
/// Shows Top Up for all users, Withdraw only for drivers
class WalletQuickActionsWidget extends StatelessWidget {
  final VoidCallback onTopUp;
  final VoidCallback onWithdraw;
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
          ),
        ),
        
        // Withdraw Button (drivers only)
        if (isDriver) ...[
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              context: context,
              icon: Icons.arrow_circle_up_outlined,
              label: 'Withdraw',
              subtitle: 'Cash Out',
              color: Colors.orange,
              onTap: onWithdraw,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}