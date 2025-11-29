import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Support Service - Handles all support/help desk API calls
/// 
/// FILE LOCATION: lib/services/support_service.dart
/// 
/// Endpoints:
/// - GET /api/support/categories/ - List categories
/// - GET /api/support/tickets/ - List tickets
/// - POST /api/support/tickets/ - Create ticket
/// - GET /api/support/tickets/{id}/ - Get ticket detail
/// - GET /api/support/tickets/{id}/messages/ - Get messages
/// - POST /api/support/messages/ - Send message
/// - POST /api/support/tickets/{id}/rate/ - Rate ticket
/// - GET /api/support/faq/ - List FAQs
/// - POST /api/support/faq/{id}/helpful/ - Mark FAQ helpful
class SupportService {
  final ApiClient _apiClient = ApiClient.instance;

  // ============================================
  // SUPPORT CATEGORIES
  // ============================================

  /// Get all support categories
  Future<ApiResponse<List<Map<String, dynamic>>>> getCategories() async {
    try {
      debugPrint('📂 Fetching support categories...');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/support/categories/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as List;
        final categories = data.map((e) => e as Map<String, dynamic>).toList();
        debugPrint('✅ Loaded ${categories.length} categories');
        return ApiResponse.success(categories);
      }

      return ApiResponse.error(response.error ?? 'Failed to load categories');
    } catch (e) {
      debugPrint('❌ Error getting categories: $e');
      return ApiResponse.error('Failed to fetch categories: ${e.toString()}');
    }
  }

  // ============================================
  // SUPPORT TICKETS
  // ============================================

  /// Get user's tickets
  Future<ApiResponse<List<Map<String, dynamic>>>> getTickets({
    String? status, // 'open', 'in_progress', 'resolved', 'closed'
    int? categoryId,
    int page = 1,
  }) async {
    try {
      debugPrint('🎫 Fetching tickets (status: $status, page: $page)...');

      final queryParams = <String, String>{
        'page': page.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }
      if (categoryId != null) {
        queryParams['category'] = categoryId.toString();
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/support/tickets/',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as List;
        final tickets = data.map((e) => e as Map<String, dynamic>).toList();
        debugPrint('✅ Loaded ${tickets.length} tickets');
        return ApiResponse.success(tickets);
      }

      return ApiResponse.error(response.error ?? 'Failed to load tickets');
    } catch (e) {
      debugPrint('❌ Error getting tickets: $e');
      return ApiResponse.error('Failed to fetch tickets: ${e.toString()}');
    }
  }

  /// Create new ticket
  Future<ApiResponse<Map<String, dynamic>>> createTicket({
    required int categoryId,
    required String subject,
    required String description,
    int? rideId,
    String priority = 'medium', // 'low', 'medium', 'high', 'urgent'
  }) async {
    try {
      debugPrint('📝 Creating ticket: $subject');

      final data = {
        'category': categoryId,
        'subject': subject,
        'description': description,
        'priority': priority,
      };

      if (rideId != null) {
        data['ride'] = rideId;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/support/tickets/',
        data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final ticketData = response.data!['data'] as Map<String, dynamic>;
        debugPrint('✅ Ticket created: ${ticketData['ticket_id']}');
        return ApiResponse.success(ticketData);
      }

      return ApiResponse.error(response.error ?? 'Failed to create ticket');
    } catch (e) {
      debugPrint('❌ Error creating ticket: $e');
      return ApiResponse.error('Failed to create ticket: ${e.toString()}');
    }
  }

  /// Get ticket details
  Future<ApiResponse<Map<String, dynamic>>> getTicketDetail(int ticketId) async {
    try {
      debugPrint('🔍 Fetching ticket detail: $ticketId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/support/tickets/$ticketId/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final ticketData = response.data!['data'] as Map<String, dynamic>;
        debugPrint('✅ Loaded ticket: ${ticketData['ticket_id']}');
        return ApiResponse.success(ticketData);
      }

      return ApiResponse.error(response.error ?? 'Failed to load ticket');
    } catch (e) {
      debugPrint('❌ Error getting ticket detail: $e');
      return ApiResponse.error('Failed to fetch ticket: ${e.toString()}');
    }
  }

  // ============================================
  // TICKET MESSAGES
  // ============================================

  /// Get messages for a ticket
  Future<ApiResponse<List<Map<String, dynamic>>>> getTicketMessages(
      int ticketId) async {
    try {
      debugPrint('💬 Fetching messages for ticket: $ticketId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/support/tickets/$ticketId/messages/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!['data'] as List;
        final messages = data.map((e) => e as Map<String, dynamic>).toList();
        debugPrint('✅ Loaded ${messages.length} messages');
        return ApiResponse.success(messages);
      }

      return ApiResponse.error(response.error ?? 'Failed to load messages');
    } catch (e) {
      debugPrint('❌ Error getting messages: $e');
      return ApiResponse.error('Failed to fetch messages: ${e.toString()}');
    }
  }

  /// Send message to ticket
  Future<ApiResponse<Map<String, dynamic>>> sendMessage({
    required int ticketId,
    required String message,
  }) async {
    try {
      debugPrint('📤 Sending message to ticket: $ticketId');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/support/messages/',
        {
          'ticket': ticketId,
          'message': message,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final messageData = response.data!['data'] as Map<String, dynamic>;
        debugPrint('✅ Message sent');
        return ApiResponse.success(messageData);
      }

      return ApiResponse.error(response.error ?? 'Failed to send message');
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return ApiResponse.error('Failed to send message: ${e.toString()}');
    }
  }

  /// Rate a ticket
  Future<ApiResponse<Map<String, dynamic>>> rateTicket({
    required int ticketId,
    required int rating, // 1-5
    String? feedback,
  }) async {
    try {
      debugPrint('⭐ Rating ticket: $ticketId with $rating stars');

      final data = <String, dynamic>{
        'rating': rating,
      };

      if (feedback != null && feedback.isNotEmpty) {
        data['feedback'] = feedback;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/support/tickets/$ticketId/rate/',
        data,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        debugPrint('✅ Ticket rated');
        return ApiResponse.success(response.data ?? {});
      }

      return ApiResponse.error(response.error ?? 'Failed to rate ticket');
    } catch (e) {
      debugPrint('❌ Error rating ticket: $e');
      return ApiResponse.error('Failed to rate ticket: ${e.toString()}');
    }
  }

  // ============================================
  // FAQ
  // ============================================

  /// Get FAQs
  /// 
  /// ✅ FIXED: Now uses correct response parsing pattern
  Future<ApiResponse<List<Map<String, dynamic>>>> getFAQs({
    int? categoryId,
    String? search,
  }) async {
    try {
      debugPrint('❓ Fetching FAQs...');

      final queryParams = <String, String>{};

      if (categoryId != null) {
        queryParams['category'] = categoryId.toString();
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      // ✅ FIXED: Changed from List<dynamic> to Map<String, dynamic>
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/support/faq/',
        queryParams: queryParams,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        // ✅ FIXED: Added data extraction like all other methods
        final data = response.data!['data'] as List;
        final faqs = data.map((e) => e as Map<String, dynamic>).toList();
        debugPrint('✅ Loaded ${faqs.length} FAQs');
        return ApiResponse.success(faqs);
      }

      return ApiResponse.error(response.error ?? 'Failed to load FAQs');
    } catch (e) {
      debugPrint('❌ Error getting FAQs: $e');
      return ApiResponse.error('Failed to fetch FAQs: ${e.toString()}');
    }
  }

  /// Get FAQ detail
  Future<ApiResponse<Map<String, dynamic>>> getFAQDetail(int faqId) async {
    try {
      debugPrint('🔍 Fetching FAQ: $faqId');

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/support/faq/$faqId/',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess && response.data != null) {
        final faqData = response.data!['data'] as Map<String, dynamic>;
        debugPrint('✅ Loaded FAQ');
        return ApiResponse.success(faqData);
      }

      return ApiResponse.error(response.error ?? 'Failed to load FAQ');
    } catch (e) {
      debugPrint('❌ Error getting FAQ: $e');
      return ApiResponse.error('Failed to fetch FAQ: ${e.toString()}');
    }
  }

  /// Mark FAQ as helpful
  Future<ApiResponse<void>> markFAQHelpful(int faqId) async {
    try {
      debugPrint('👍 Marking FAQ helpful: $faqId');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/support/faq/$faqId/helpful/',
        {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        debugPrint('✅ FAQ marked helpful');
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.error ?? 'Failed to mark FAQ');
    } catch (e) {
      debugPrint('❌ Error marking FAQ: $e');
      return ApiResponse.error('Failed to mark FAQ: ${e.toString()}');
    }
  }

  /// Mark FAQ as not helpful
  Future<ApiResponse<void>> markFAQNotHelpful(int faqId) async {
    try {
      debugPrint('👎 Marking FAQ not helpful: $faqId');

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/support/faq/$faqId/not-helpful/',
        {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.isSuccess) {
        debugPrint('✅ FAQ marked not helpful');
        return ApiResponse.success(null);
      }

      return ApiResponse.error(response.error ?? 'Failed to mark FAQ');
    } catch (e) {
      debugPrint('❌ Error marking FAQ: $e');
      return ApiResponse.error('Failed to mark FAQ: ${e.toString()}');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Format ticket status for display
  static String formatTicketStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'waiting_user':
        return 'Waiting for You';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return status;
    }
  }

  /// Format priority for display
  static String formatPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Low';
      case 'medium':
        return 'Medium';
      case 'high':
        return 'High';
      case 'urgent':
        return 'Urgent';
      default:
        return priority;
    }
  }

  /// Get color for ticket status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'waiting_user':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  /// Get color for priority level
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}