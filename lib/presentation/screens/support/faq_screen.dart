import 'package:flutter/material.dart';
import '../../../services/support_service.dart';

/// FAQ Screen - List of frequently asked questions
/// 
/// FILE LOCATION: lib/presentation/screens/support/faq_screen.dart
/// 
/// Features:
/// - List FAQs
/// - Search FAQs
/// - Filter by category
/// - Expandable answers
class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final SupportService _supportService = SupportService();
  final _searchController = TextEditingController();

  List<Map<String, dynamic>> _faqs = [];
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  Set<int> _expandedFAQs = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _loadCategories(),
      _loadFAQs(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadCategories() async {
    final response = await _supportService.getCategories();
    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _categories = response.data!);
    }
  }

  Future<void> _loadFAQs() async {
    final response = await _supportService.getFAQs(
      categoryId: _selectedCategoryId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (mounted && response.isSuccess && response.data != null) {
      setState(() => _faqs = response.data!);
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _loadFAQs();
  }

  void _onCategoryChanged(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _expandedFAQs.clear();
    });
    _loadFAQs();
  }

  void _toggleFAQ(int faqId) {
    setState(() {
      if (_expandedFAQs.contains(faqId)) {
        _expandedFAQs.remove(faqId);
      } else {
        _expandedFAQs.add(faqId);
      }
    });
  }

  Future<void> _markFAQHelpful(int faqId, bool helpful) async {
    if (helpful) {
      await _supportService.markFAQHelpful(faqId);
    } else {
      await _supportService.markFAQNotHelpful(faqId);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          'FAQs',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.surface,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Category Filter
          if (_categories.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: colorScheme.surface,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // All Categories Chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          if (selected) _onCategoryChanged(null);
                        },
                        backgroundColor: colorScheme.surfaceVariant,
                        selectedColor: colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == null
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight: _selectedCategoryId == null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    // Category Chips
                    ..._categories.map((category) {
                      final isSelected = _selectedCategoryId == category['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category['name'] ?? ''),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              _onCategoryChanged(category['id']);
                            }
                          },
                          backgroundColor: colorScheme.surfaceVariant,
                          selectedColor: colorScheme.primary.withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          // FAQ List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  )
                : _faqs.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _faqs.length,
                        itemBuilder: (context, index) {
                          return _buildFAQCard(
                            context,
                            _faqs[index],
                            colorScheme,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.help_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No FAQs found' : 'No FAQs available',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'FAQs will be available soon',
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

  Widget _buildFAQCard(
    BuildContext context,
    Map<String, dynamic> faq,
    ColorScheme colorScheme,
  ) {
    final faqId = faq['id'] as int;
    final question = faq['question'] ?? '';
    final answer = faq['answer'] ?? '';
    final categoryName = faq['category_name'] ?? '';
    final viewCount = faq['view_count'] ?? 0;
    final isExpanded = _expandedFAQs.contains(faqId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question Header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleFAQ(faqId),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Question Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Question Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                categoryName,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                              if (viewCount > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• $viewCount views',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Expand Icon
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Answer (when expanded)
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    answer,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Helpful Buttons
                  Row(
                    children: [
                      Text(
                        'Was this helpful?',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _markFAQHelpful(faqId, true),
                        icon: const Icon(Icons.thumb_up_outlined, size: 16),
                        label: const Text('Yes'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _markFAQHelpful(faqId, false),
                        icon: const Icon(Icons.thumb_down_outlined, size: 16),
                        label: const Text('No'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}