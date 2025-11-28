import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/promotions_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// Referral Screen - Share code and track referrals
/// 
/// FILE LOCATION: lib/presentation/screens/promotions/referral_screen.dart
/// 
/// Features:
/// - Display referral code
/// - Share code via SMS, WhatsApp, etc.
/// - List of referrals with status
/// - Earnings tracking
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final PromotionsService _promotionsService = PromotionsService();

  Map<String, dynamic>? _referralData;
  List<Map<String, dynamic>> _referrals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadReferralCode(),
      _loadReferrals(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadReferralCode() async {
    final response = await _promotionsService.getMyReferralCode();
    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _referralData = response.data);
    }
  }

  Future<void> _loadReferrals() async {
    final response = await _promotionsService.getMyReferrals();
    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _referrals = response.data!);
    }
  }

  void _copyCode() {
    if (_referralData != null) {
      final code = _referralData!['referral_code'] as String;
      Clipboard.setData(ClipboardData(text: code));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareCode() {
    if (_referralData != null) {
      final code = _referralData!['referral_code'] as String;
      // Deep link for direct app installation with code
      final deepLink = 'https://swiftride.app/ref/$code';
      final message = '''
Hey! 🚗

Join SwiftRide with my referral code and earn rewards!

Code: $code
Link: $deepLink

Download the app and start saving on rides today!

📱 iOS: https://apps.apple.com/app/swiftride
📱 Android: https://play.google.com/store/apps/details?id=com.swiftride
''';
      Share.share(message, subject: 'Join SwiftRide and Get Rewards! 🎁');
    }
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
          'Refer & Earn',
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
          : RefreshIndicator(
              onRefresh: _loadData,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Referral Code Card
                    if (_referralData != null) ...[
                      _buildReferralCodeCard(colorScheme),
                      const SizedBox(height: 16),
                    ],

                    // How It Works
                    _buildHowItWorks(colorScheme),

                    const SizedBox(height: 24),

                    // Referrals List
                    _buildReferralsList(colorScheme),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildReferralCodeCard(ColorScheme colorScheme) {
    final referralCode = _referralData!['referral_code'] as String;
    final referralsCount = _referralData!['referrals_count'] as int;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.card_giftcard, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Share & Earn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Your Referral Code',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                referralCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              IconButton(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: 'Copy Code',
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _copyCode,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareCode,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$referralsCount friends referred',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(ColorScheme colorScheme) {
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
          Text(
            'How It Works',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStep(
            colorScheme: colorScheme,
            number: '1',
            title: 'Share Your Code',
            description: 'Share your referral code with friends and family',
            icon: Icons.share,
          ),
          const SizedBox(height: 12),
          _buildStep(
            colorScheme: colorScheme,
            number: '2',
            title: 'They Sign Up',
            description: 'Your friend signs up using your code',
            icon: Icons.person_add,
          ),
          const SizedBox(height: 12),
          _buildStep(
            colorScheme: colorScheme,
            number: '3',
            title: 'Complete Rides',
            description: 'They complete their first ride',
            icon: Icons.directions_car,
          ),
          const SizedBox(height: 12),
          _buildStep(
            colorScheme: colorScheme,
            number: '4',
            title: 'Earn Rewards',
            description: 'You both get rewards in your wallet!',
            icon: Icons.celebration,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required ColorScheme colorScheme,
    required String number,
    required String title,
    required String description,
    required IconData icon,
    Color? color,
  }) {
    final stepColor = color ?? colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: stepColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: stepColor, size: 20),
          ),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
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

  Widget _buildReferralsList(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your Referrals',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_referrals.isEmpty)
          _buildEmptyState(colorScheme)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _referrals.length,
            itemBuilder: (context, index) {
              return _buildReferralCard(
                context,
                _referrals[index],
                colorScheme,
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No Referrals Yet',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start sharing your code to earn rewards!',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _shareCode,
            icon: const Icon(Icons.share),
            label: const Text('Share Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(
    BuildContext context,
    Map<String, dynamic> referral,
    ColorScheme colorScheme,
  ) {
    final refereeName = referral['referee_name'] ?? 'Unknown';
    final status = referral['status'] ?? 'pending';
    final ridesCompleted = referral['referee_rides_completed'] ?? 0;
    final referredAt = DateTime.tryParse(referral['referred_at'] ?? '');

    final statusColor = PromotionsService.getStatusColor(status);
    final statusText = PromotionsService.formatReferralStatus(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(Icons.person, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      refereeName,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$ridesCompleted rides completed',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (referredAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Joined ${DateFormat('MMM d, yyyy').format(referredAt)}',
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
}