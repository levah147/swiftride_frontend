import 'package:flutter/material.dart';
import '../../../services/promotions_service.dart';
import 'package:intl/intl.dart';

/// Points History Screen - View all loyalty points transactions
/// 
/// FILE LOCATION: lib/presentation/screens/promotions/points_history_screen.dart
/// 
/// Features:
/// - Complete history of points earned and redeemed
/// - Filter by type (all, earned, redeemed)
/// - Shows date, description, amount
/// - Visual indicators for earn/redeem
/// - Pull to refresh
class PointsHistoryScreen extends StatefulWidget {
  const PointsHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PointsHistoryScreen> createState() => _PointsHistoryScreenState();
}

class _PointsHistoryScreenState extends State<PointsHistoryScreen> {
  final PromotionsService _promotionsService = PromotionsService();

  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, earned, redeemed

  // Stats
  int _totalEarned = 0;
  int _totalRedeemed = 0;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    // Note: This would need a backend endpoint like:
    // GET /api/promotions/loyalty/history/
    // For now, we'll show mock data structure

    // In production, call:
    // final response = await _promotionsService.getLoyaltyHistory();

    // Mock data for demonstration
    await Future.delayed(const Duration(seconds: 1));

    final mockTransactions = [
      {
        'id': 1,
        'type': 'earned',
        'source': 'ride_completion',
        'points': 15,
        'description': 'Completed ride #12345',
        'date': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 2,
        'type': 'earned',
        'source': 'referral_bonus',
        'points': 100,
        'description': 'Referral bonus from friend',
        'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 3,
        'type': 'redeemed',
        'source': 'wallet_credit',
        'points': -100,
        'description': 'Redeemed for ₦10 wallet credit',
        'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      },
      {
        'id': 4,
        'type': 'earned',
        'source': 'ride_completion',
        'points': 25,
        'description': 'Completed ride #12340',
        'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      },
      {
        'id': 5,
        'type': 'earned',
        'source': 'welcome_bonus',
        'points': 100,
        'description': 'Welcome bonus',
        'date': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      },
    ];

    if (mounted) {
      setState(() {
        _allTransactions = mockTransactions;
        _filteredTransactions = mockTransactions;
        _isLoading = false;
      });
      _calculateStats();
      _filterTransactions();
    }
  }

  void _calculateStats() {
    _totalEarned = _allTransactions
        .where((t) => t['type'] == 'earned')
        .fold(0, (sum, t) => sum + (t['points'] as int));

    _totalRedeemed = _allTransactions
        .where((t) => t['type'] == 'redeemed')
        .fold(0, (sum, t) => sum + ((t['points'] as int).abs()));
  }

  void _filterTransactions() {
    setState(() {
      if (_filterType == 'all') {
        _filteredTransactions = _allTransactions;
      } else {
        _filteredTransactions = _allTransactions
            .where((t) => t['type'] == _filterType)
            .toList();
      }
    });
  }

  String _getSourceIcon(String source) {
    switch (source) {
      case 'ride_completion':
        return '🚗';
      case 'referral_bonus':
        return '👥';
      case 'welcome_bonus':
        return '🎉';
      case 'wallet_credit':
        return '💰';
      case 'special_promotion':
        return '🎁';
      case 'review_reward':
        return '⭐';
      default:
        return '📝';
    }
  }

  String _getSourceLabel(String source) {
    switch (source) {
      case 'ride_completion':
        return 'Ride Completed';
      case 'referral_bonus':
        return 'Referral Bonus';
      case 'welcome_bonus':
        return 'Welcome Bonus';
      case 'wallet_credit':
        return 'Wallet Credit';
      case 'special_promotion':
        return 'Special Promotion';
      case 'review_reward':
        return 'Review Reward';
      default:
        return 'Other';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Points History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: Column(
                children: [
                  // Stats Cards
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: colorScheme.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Earned',
                            _totalEarned.toString(),
                            Icons.arrow_upward,
                            Colors.green,
                            colorScheme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Total Redeemed',
                            _totalRedeemed.toString(),
                            Icons.arrow_downward,
                            Colors.orange,
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: colorScheme.surface,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('All'),
                          icon: Icon(Icons.list),
                        ),
                        ButtonSegment(
                          value: 'earned',
                          label: Text('Earned'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                        ButtonSegment(
                          value: 'redeemed',
                          label: Text('Redeemed'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                      ],
                      selected: {_filterType},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() {
                          _filterType = selected.first;
                        });
                        _filterTransactions();
                      },
                    ),
                  ),

                  // Results Count
                  if (_filteredTransactions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Text(
                        '${_filteredTransactions.length} transaction${_filteredTransactions.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Transaction List
                  Expanded(
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = _filteredTransactions[index];
                              return _buildTransactionCard(
                                transaction,
                                colorScheme,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'points',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    ColorScheme colorScheme,
  ) {
    final type = transaction['type'] as String;
    final source = transaction['source'] as String;
    final points = transaction['points'] as int;
    final description = transaction['description'] as String;
    final date = DateTime.parse(transaction['date'] as String);

    final isEarned = type == 'earned';
    final color = isEarned ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getSourceIcon(source),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getSourceLabel(source),
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • h:mm a').format(date),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Points
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isEarned ? '+' : ''}$points',
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'points',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your points history will appear here',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
