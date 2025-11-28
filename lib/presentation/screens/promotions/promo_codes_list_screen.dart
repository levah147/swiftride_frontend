import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/promotions_service.dart';
import 'package:intl/intl.dart';

/// Promo Codes List Screen - Browse all available promo codes
/// 
/// FILE LOCATION: lib/presentation/screens/promotions/promo_codes_list_screen.dart
/// 
/// Features:
/// - Complete list of active promo codes
/// - Search by code or name
/// - Filter by discount type (percentage/fixed)
/// - Sort by discount amount or expiry date
/// - Copy code to clipboard
/// - Promo details modal
class PromoCodesListScreen extends StatefulWidget {
  const PromoCodesListScreen({Key? key}) : super(key: key);

  @override
  State<PromoCodesListScreen> createState() => _PromoCodesListScreenState();
}

class _PromoCodesListScreenState extends State<PromoCodesListScreen> {
  final PromotionsService _promotionsService = PromotionsService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allPromoCodes = [];
  List<Map<String, dynamic>> _filteredPromoCodes = [];
  bool _isLoading = true;
  String _filterType = 'all'; // all, percentage, fixed
  String _sortBy = 'expiry'; // expiry, discount

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
    _searchController.addListener(_filterPromoCodes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPromoCodes() async {
    setState(() => _isLoading = true);

    final response = await _promotionsService.getPromoCodes();

    if (mounted) {
      if (response.isSuccess && response.data != null) {
        setState(() {
          _allPromoCodes = response.data!;
          _filteredPromoCodes = _allPromoCodes;
          _isLoading = false;
        });
        _filterPromoCodes();
      } else {
        setState(() => _isLoading = false);
        _showError(response.error ?? 'Failed to load promo codes');
      }
    }
  }

  void _filterPromoCodes() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredPromoCodes = _allPromoCodes.where((promo) {
        // Search filter
        final code = (promo['code'] as String? ?? '').toLowerCase();
        final name = (promo['name'] as String? ?? '').toLowerCase();
        final matchesSearch = code.contains(query) || name.contains(query);

        // Type filter
        final type = promo['discount_type'] as String? ?? '';
        final matchesType = _filterType == 'all' || type == _filterType;

        return matchesSearch && matchesType;
      }).toList();

      // Sort
      if (_sortBy == 'expiry') {
        _filteredPromoCodes.sort((a, b) {
          final dateA = DateTime.parse(a['end_date'] as String);
          final dateB = DateTime.parse(b['end_date'] as String);
          return dateA.compareTo(dateB);
        });
      } else if (_sortBy == 'discount') {
        _filteredPromoCodes.sort((a, b) {
          final discountA = (a['discount_value'] as num).toDouble();
          final discountB = (b['discount_value'] as num).toDouble();
          return discountB.compareTo(discountA); // Descending
        });
      }
    });
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

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code $code copied to clipboard!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showPromoDetails(Map<String, dynamic> promo, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    promo['code'] ?? '',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              promo['name'] ?? '',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            // Description
            if (promo['description'] != null &&
                (promo['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                promo['description'],
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Details Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    'Discount',
                    _promotionsService.formatDiscountDisplay(
                      promo['discount_type'],
                      promo['discount_value'],
                    ),
                    colorScheme,
                  ),
                  if (promo['max_discount'] != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Max Discount',
                      '₦${promo['max_discount']}',
                      colorScheme,
                    ),
                  ],
                  if (promo['minimum_fare'] != null &&
                      (promo['minimum_fare'] as num) > 0) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Min. Fare',
                      '₦${promo['minimum_fare']}',
                      colorScheme,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Expires',
                    DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(promo['end_date']),
                    ),
                    colorScheme,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Copy Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _copyCode(promo['code']);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text(
                  'Copy Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
          'Promo Codes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPromoCodes,
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: colorScheme.surface,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search promo codes...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterPromoCodes();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // Filters & Sort
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: colorScheme.surface,
                    child: Row(
                      children: [
                        // Type Filter
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'all',
                                label: Text('All'),
                              ),
                              ButtonSegment(
                                value: 'percentage',
                                label: Text('%'),
                              ),
                              ButtonSegment(
                                value: 'fixed',
                                label: Text('₦'),
                              ),
                            ],
                            selected: {_filterType},
                            onSelectionChanged: (Set<String> selected) {
                              setState(() {
                                _filterType = selected.first;
                              });
                              _filterPromoCodes();
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Sort Menu
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.sort),
                          onSelected: (value) {
                            setState(() => _sortBy = value);
                            _filterPromoCodes();
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'expiry',
                              child: Text('Sort by Expiry'),
                            ),
                            const PopupMenuItem(
                              value: 'discount',
                              child: Text('Sort by Discount'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Results Count
                  if (_filteredPromoCodes.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Text(
                        '${_filteredPromoCodes.length} promo code${_filteredPromoCodes.length != 1 ? 's' : ''} available',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  // Promo List
                  Expanded(
                    child: _filteredPromoCodes.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredPromoCodes.length,
                            itemBuilder: (context, index) {
                              final promo = _filteredPromoCodes[index];
                              return _buildPromoCard(promo, colorScheme);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo, ColorScheme colorScheme) {
    final discountType = promo['discount_type'] as String;
    final discountValue = promo['discount_value'] as num;
    final endDate = DateTime.parse(promo['end_date'] as String);
    final daysLeft = endDate.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _showPromoDetails(promo, colorScheme),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Discount Badge
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _promotionsService.formatDiscountDisplay(
                      discountType,
                      discountValue,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Promo Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo['code'] ?? '',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promo['name'] ?? '',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysLeft > 0
                          ? 'Expires in $daysLeft day${daysLeft != 1 ? 's' : ''}'
                          : 'Expires today!',
                      style: TextStyle(
                        color: daysLeft <= 3
                            ? Colors.red
                            : colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Copy Button
              IconButton(
                icon: const Icon(Icons.copy),
                color: colorScheme.primary,
                onPressed: () => _copyCode(promo['code']),
              ),
            ],
          ),
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
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No promo codes found'
                : 'No promo codes available',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Check back later for new deals!',
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