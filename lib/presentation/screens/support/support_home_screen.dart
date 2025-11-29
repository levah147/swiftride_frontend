import 'package:flutter/material.dart';
import 'package:swiftride/presentation/screens/support/create_ticket_screen.dart';
import 'package:swiftride/presentation/screens/support/my_tickets_screen.dart';
import 'package:swiftride/presentation/screens/support/ticket_detail_screen.dart';
import '../../../services/support_service.dart';

/// Support Home Screen - Main hub for help & support
/// 
/// FILE LOCATION: lib/presentation/screens/support/support_home_screen.dart
/// 
/// Features:
/// - Support categories grid
/// - Recent tickets
/// - Quick FAQ access
/// - Search support 
class SupportHomeScreen extends StatefulWidget {
  const SupportHomeScreen({Key? key}) : super(key: key);

  @override
  State<SupportHomeScreen> createState() => _SupportHomeScreenState();
}

class _SupportHomeScreenState extends State<SupportHomeScreen> {
  final SupportService _supportService = SupportService();

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _recentTickets = [];
  List<Map<String, dynamic>> _popularFAQs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadCategories(),
      _loadRecentTickets(),
      _loadPopularFAQs(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    final response = await _supportService.getCategories();
    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _categories = response.data!);
    }
  }

  Future<void> _loadRecentTickets() async {
    final response = await _supportService.getTickets(page: 1);
    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _recentTickets = response.data!.take(3).toList());
    }
  }

  Future<void> _loadPopularFAQs() async {
    final response = await _supportService.getFAQs();
    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _popularFAQs = response.data!.take(5).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search/FAQ screen
              Navigator.pushNamed(context, '/support/faq');
            },
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
              onRefresh: _loadData,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    _buildHeaderBanner(colorScheme),

                    const SizedBox(height: 24),

                    // Quick Actions
                    _buildQuickActions(context, colorScheme),

                    const SizedBox(height: 24),

                    // Support Categories
                    if (_categories.isNotEmpty) ...[
                      _buildSectionHeader('Browse Categories', colorScheme),
                      const SizedBox(height: 12),
                      _buildCategoriesGrid(context, colorScheme),
                      const SizedBox(height: 24),
                    ],

                    // Recent Tickets
                    if (_recentTickets.isNotEmpty) ...[
                      _buildSectionHeader('Recent Tickets', colorScheme,
                          action: () => Navigator.pushNamed(context, '/support/tickets')),
                      const SizedBox(height: 12),
                      _buildRecentTickets(context, colorScheme),
                      const SizedBox(height: 24),
                    ],

                    // Popular FAQs
                    if (_popularFAQs.isNotEmpty) ...[
                      _buildSectionHeader('Popular FAQs', colorScheme,
                          action: () => Navigator.pushNamed(context, '/support/faq')),
                      const SizedBox(height: 12),
                      _buildPopularFAQs(context, colorScheme),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.support_agent, color: Colors.white, size: 48),
          SizedBox(height: 12),
          Text(
            'How can we help?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Browse categories or create a ticket',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              context: context,
              icon: Icons.add_circle_outline,
              title: 'New Ticket',
              subtitle: 'Create ticket',
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/support/create-ticket'),
        
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickActionCard(
              context: context,
              icon: Icons.confirmation_number_outlined,
              title: 'My Tickets',
              subtitle: 'View all',
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/support/tickets'), 
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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

  Widget _buildSectionHeader(String title, ColorScheme colorScheme,
      {VoidCallback? action}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: action,
              child: Text(
                'See All',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, ColorScheme colorScheme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(context, category, colorScheme);
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Map<String, dynamic> category,
    ColorScheme colorScheme,
  ) {
    final icon = category['icon'] ?? '📂';
    final name = category['name'] ?? 'Category';
    final ticketCount = category['ticket_count'] ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () 
         {
          Navigator.pushNamed(
            context,
            '/support/create-ticket',
            arguments: {'category': category},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (ticketCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '$ticketCount open',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTickets(BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recentTickets.length,
      itemBuilder: (context, index) {
        final ticket = _recentTickets[index];
        return _buildTicketCard(context, ticket, colorScheme);
      },
    );
  }

  Widget _buildTicketCard(
    BuildContext context,
    Map<String, dynamic> ticket,
    ColorScheme colorScheme,
  ) {
    final ticketId = (ticket['id'] as int? ?? 0).toString();  // ✅ FIXED: Convert to String
    final ticketIdDisplay = ticket['ticket_id'] ?? '';
    final subject = ticket['subject'] ?? '';
    final status = ticket['status'] ?? 'open';
    final statusColor = SupportService.getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () 
        
          {
            Navigator.pushNamed(
              context,
              '/support/ticket-detail',
              arguments: {'ticketId': ticket['id']},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ticketIdDisplay,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    SupportService.formatTicketStatus(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPopularFAQs(BuildContext context, ColorScheme colorScheme) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _popularFAQs.length,
      itemBuilder: (context, index) {
        final faq = _popularFAQs[index];
        return _buildFAQCard(context, faq, colorScheme);
      },
    );
  }

  Widget _buildFAQCard(
    BuildContext context,
    Map<String, dynamic> faq,
    ColorScheme colorScheme,
  ) {
    final question = faq['question'] ?? '';
    final viewCount = faq['view_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: ()
          {
            Navigator.pushNamed(
              context,
              '/support/faq-detail',
              arguments: {'faq': faq},
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.help_outline, size: 20, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (viewCount > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '$viewCount views',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}