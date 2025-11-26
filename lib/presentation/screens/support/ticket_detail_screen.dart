import 'package:flutter/material.dart';
import '../../../services/support_service.dart';
import 'package:intl/intl.dart';

/// Ticket Detail Screen - View ticket with message thread
/// 
/// FILE LOCATION: lib/presentation/screens/support/ticket_detail_screen.dart
/// 
/// Features:
/// - Ticket information
/// - Message thread
/// - Reply to ticket
/// - Rate resolved tickets
class TicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const TicketDetailScreen({
    Key? key,
    required this.ticketId,
  }) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportService _supportService = SupportService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _showRatingDialog = false;
  int _selectedRating = 0;
  final _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTicketData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadTicketData() async {
    setState(() => _isLoading = true);

    // Load ticket details and messages in parallel
    final results = await Future.wait([
      _supportService.getTicketDetail(widget.ticketId),
      _supportService.getTicketMessages(widget.ticketId),
    ]);

    if (mounted) {
      final ticketResponse = results[0];
      final messagesResponse = results[1];

      // ✅ FIX: Cast the responses properly
    if (ticketResponse.isSuccess && ticketResponse.data != null) {
      setState(() {
        _ticket = ticketResponse.data as Map<String, dynamic>?;  // ✅ ADD CAST
      });
    }

    if (messagesResponse.isSuccess && messagesResponse.data != null) {
      setState(() {
        _messages = (messagesResponse.data as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];  // ✅ ADD CAST
      });
    }

      setState(() => _isLoading = false);

      // Scroll to bottom after loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSendingMessage = true);

    final response = await _supportService.sendMessage(
      ticketId: widget.ticketId,
      message: message,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      _messageController.clear();
      _showSuccess('Message sent');
      await _loadTicketData(); // Reload to get new message
    } else {
      _showError(response.error ?? 'Failed to send message');
    }

    setState(() => _isSendingMessage = false);
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      _showError('Please select a rating');
      return;
    }

    final response = await _supportService.rateTicket(
      ticketId: widget.ticketId,
      rating: _selectedRating,
      feedback: _feedbackController.text.trim(),
    );

    if (!mounted) return;

    if (response.isSuccess) {
      setState(() => _showRatingDialog = false);
      _showSuccess('Thank you for your feedback!');
      await _loadTicketData();
    } else {
      _showError(response.error ?? 'Failed to submit rating');
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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Ticket Details',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),
      );
    }

    if (_ticket == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Ticket not found',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final status = _ticket!['status'] ?? 'open';
    final canReply = status != 'closed';
    final canRate = (status == 'resolved' || status == 'closed') &&
        (_ticket!['rating'] == null);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          _ticket!['ticket_id'] ?? 'Ticket',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Ticket Info Card
          _buildTicketInfoCard(colorScheme),

          // Rate Ticket Button (if resolved/closed and not rated)
          if (canRate) _buildRateTicketBanner(colorScheme),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyMessages(colorScheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(
                        context,
                        _messages[index],
                        colorScheme,
                      );
                    },
                  ),
          ),

          // Reply Input (only if not closed)
          if (canReply) _buildReplyInput(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard(ColorScheme colorScheme) {
    final subject = _ticket!['subject'] ?? '';
    final description = _ticket!['description'] ?? '';
    final status = _ticket!['status'] ?? 'open';
    final statusDisplay = _ticket!['status_display'] ?? '';
    final priority = _ticket!['priority'] ?? 'medium';
    final categoryName = _ticket!['category_name'] ?? '';
    final createdAt = DateTime.parse(_ticket!['created_at'] ?? '');

    final statusColor = SupportService.getStatusColor(status);
    final priorityColor = SupportService.getPriorityColor(priority);

    return Container(
      margin: const EdgeInsets.all(16),
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
          // Status & Priority
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusDisplay,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  SupportService.formatPriority(priority),
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Subject
          Text(
            subject,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 12),

          // Meta Info
          Row(
            children: [
              Icon(
                Icons.folder_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                categoryName,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(createdAt),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateTicketBanner(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'How was your experience?',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _showRatingDialog = true),
            child: const Text('Rate'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessages(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    ColorScheme colorScheme,
  ) {
    final isStaff = message['is_staff_reply'] ?? false;
    final messageText = message['message'] ?? '';
    final sender = message['sender'] as Map<String, dynamic>?;
    final senderName = sender != null
        ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'.trim()
        : 'Unknown';
    final createdAt = DateTime.parse(message['created_at'] ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isStaff) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.withOpacity(0.2),
              child: const Icon(Icons.support_agent, size: 16, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          if (!isStaff) const Spacer(),
          Flexible(
            flex: 7,
            child: Column(
              crossAxisAlignment:
                  isStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                // Sender name
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isStaff ? 'Support Team' : 'You',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Message bubble
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isStaff
                        ? colorScheme.surfaceVariant
                        : colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isStaff
                          ? colorScheme.outline.withOpacity(0.3)
                          : colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    messageText,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Timestamp
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('MMM d, h:mm a').format(createdAt),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isStaff) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.2),
              child: Icon(Icons.person, size: 16, color: colorScheme.primary),
            ),
          ],
          if (isStaff) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildReplyInput(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                enabled: !_isSendingMessage,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isSendingMessage ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: _isSendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}