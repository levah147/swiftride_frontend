import 'package:flutter/material.dart';
import '../../../services/promotions_service.dart';

/// Loyalty Screen - View points, tier, and redeem rewards
/// 
/// FILE LOCATION: lib/presentation/screens/promotions/loyalty_screen.dart
/// 
/// Features:
/// - Display loyalty tier
/// - Show available/total points
/// - Progress to next tier
/// - Redeem points for wallet credit
/// - Points history (if available)
class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final PromotionsService _promotionsService = PromotionsService();

  Map<String, dynamic>? _loyaltyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }

  Future<void> _loadLoyaltyData() async {
    setState(() => _isLoading = true);

    final response = await _promotionsService.getMyLoyaltyPoints();

    if (mounted) {
      if (response.isSuccess && response.data != null) {
        setState(() {
          _loyaltyData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError(response.error ?? 'Failed to load loyalty data');
      }
    }
  }

  void _showError(String message) {
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

  void _showRedeemDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRedeemSheet(context),
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
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Loyalty Rewards',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : _loyaltyData == null
              ? _buildErrorState(colorScheme)
              : RefreshIndicator(
                  onRefresh: _loadLoyaltyData,
                  color: colorScheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tier Card
                        _buildTierCard(colorScheme),

                        const SizedBox(height: 16),

                        // Points Card
                        _buildPointsCard(colorScheme),

                        const SizedBox(height: 16),

                        // Progress Card
                        _buildProgressCard(colorScheme),

                        const SizedBox(height: 24),

                        // How to Earn
                        _buildHowToEarn(colorScheme),

                        const SizedBox(height: 24),

                        // Tier Benefits
                        _buildTierBenefits(colorScheme),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Loyalty Data',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLoyaltyData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(ColorScheme colorScheme) {
    final tier = _loyaltyData!['tier'] as String;
    final tierColor = PromotionsService.getTierColor(tier);
    final tierIcon = PromotionsService.getTierIcon(tier);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierColor,
            tierColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: tierColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            tierIcon,
            style: const TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            '${tier.toUpperCase()} MEMBER',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your loyalty tier',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(ColorScheme colorScheme) {
    final availablePoints = _loyaltyData!['available_points'] as int;
    final totalPoints = _loyaltyData!['total_points'] as int;
    final pointsValue = PromotionsService.pointsToMoney(availablePoints);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPointsStat(
                colorScheme: colorScheme,
                label: 'Available Points',
                value: '$availablePoints',
                icon: Icons.stars,
                color: Colors.amber,
              ),
              Container(
                width: 1,
                height: 40,
                color: colorScheme.outline.withOpacity(0.3),
              ),
              _buildPointsStat(
                colorScheme: colorScheme,
                label: 'Total Earned',
                value: '$totalPoints',
                icon: Icons.emoji_events,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Points Value',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₦${pointsValue.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: availablePoints >= 100 ? _showRedeemDialog : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Redeem'),
                ),
              ],
            ),
          ),
          if (availablePoints < 100) ...[
            const SizedBox(height: 8),
            Text(
              'Minimum 100 points required to redeem',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPointsStat({
    required ColorScheme colorScheme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard(ColorScheme colorScheme) {
    final tier = _loyaltyData!['tier'] as String;
    final totalPoints = _loyaltyData!['total_points'] as int;
    final nextTierInfo = PromotionsService.getNextTierInfo(tier, totalPoints);
    
    final pointsNeeded = nextTierInfo['points_needed'] as int;
    final totalRequired = nextTierInfo['total_required'] as int;
    final nextTier = nextTierInfo['next_tier'] as String;

    if (pointsNeeded <= 0) {
      return const SizedBox.shrink();
    }

    final progress = totalPoints / totalRequired;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next Tier: $nextTier',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$pointsNeeded points',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$totalPoints / $totalRequired points',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToEarn(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'How to Earn Points',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildEarnMethod(
                colorScheme: colorScheme,
                icon: Icons.directions_car,
                title: 'Complete Rides',
                description: '1 point per ₦100 spent',
                color: Colors.blue,
              ),
              const Divider(height: 24),
              _buildEarnMethod(
                colorScheme: colorScheme,
                icon: Icons.people,
                title: 'Refer Friends',
                description: 'Earn bonus points for referrals',
                color: Colors.green,
              ),
              const Divider(height: 24),
              _buildEarnMethod(
                colorScheme: colorScheme,
                icon: Icons.card_giftcard,
                title: 'Special Promotions',
                description: 'Bonus points during promotions',
                color: Colors.purple,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarnMethod({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierBenefits(ColorScheme colorScheme) {
    final tiers = [
      {
        'tier': 'Bronze',
        'icon': '🥉',
        'requirement': '0 points',
        'benefits': ['100 welcome points', 'Basic rewards'],
      },
      {
        'tier': 'Silver',
        'icon': '🥈',
        'requirement': '2,000 points',
        'benefits': ['10% bonus points', 'Priority support'],
      },
      {
        'tier': 'Gold',
        'icon': '🥇',
        'requirement': '5,000 points',
        'benefits': ['20% bonus points', 'Exclusive promos'],
      },
      {
        'tier': 'Platinum',
        'icon': '💎',
        'requirement': '10,000 points',
        'benefits': ['30% bonus points', 'VIP treatment'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Tier Benefits',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: tiers.length,
          itemBuilder: (context, index) {
            final tier = tiers[index];
            return _buildTierBenefitCard(
              colorScheme: colorScheme,
              tier: tier,
              isCurrentTier:
                  tier['tier'].toString().toLowerCase() ==
                      (_loyaltyData!['tier'] as String).toLowerCase(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTierBenefitCard({  // ✅ RENAMED
  required ColorScheme colorScheme,
  required Map<String, dynamic> tier,
  required bool isCurrentTier,
}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentTier
            ? colorScheme.primary.withOpacity(0.1)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentTier
              ? colorScheme.primary
              : colorScheme.outline.withOpacity(0.3),
          width: isCurrentTier ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                tier['icon'] as String,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier['tier'] as String,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isCurrentTier) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier['requirement'] as String,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...((tier['benefits'] as List).map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      benefit as String,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  Widget _buildRedeemSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final availablePoints = _loyaltyData!['available_points'] as int;
    
    // Predefined redemption options
    final options = [
      {'points': 100, 'amount': 10.0},
      {'points': 500, 'amount': 50.0},
      {'points': 1000, 'amount': 100.0},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Redeem Points',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have $availablePoints points available',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ...options.map((option) {
            final points = option['points'] as int;
            final amount = option['amount'] as double;
            final canRedeem = availablePoints >= points;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: canRedeem
                      ? () {
                          Navigator.pop(context);
                          _confirmRedeem(points, amount);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: canRedeem
                          ? Colors.green.withOpacity(0.1)
                          : colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: canRedeem
                            ? Colors.green
                            : colorScheme.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$points Points',
                              style: TextStyle(
                                color: canRedeem
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '100 points = ₦10',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₦${amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: canRedeem ? Colors.green : Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _confirmRedeem(int points, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text(
          'Redeem $points points for ₦${amount.toStringAsFixed(2)}?\n\n'
          'This amount will be added to your wallet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRedemption(points, amount);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _processRedemption(int points, double amount) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Call redemption API
      final response = await _promotionsService.redeemPoints(points: points);

      if (mounted) {
        // Close loading dialog
        Navigator.pop(context);

        if (response.isSuccess && response.data != null) {
          // Success! Points redeemed
          final data = response.data!;
          final redeemedAmount = data['amount'] as num;
          final newPoints = data['new_available_points'] as int;

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🎉 ₦${redeemedAmount.toStringAsFixed(2)} added to your wallet!\n'
                'New balance: $newPoints points',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );

          // Reload loyalty data to show updated points
          _loadLoyaltyData();
        } else {
          // Error occurred
          _showError(response.error ?? 'Failed to redeem points');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        _showError('An error occurred: ${e.toString()}');
      }
    }
  }
}