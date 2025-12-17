import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// FIXED Paystack Webview Screen
/// Now properly detects payment completion
class PaystackWebviewScreen extends StatefulWidget {
  final String authorizationUrl;
  final String reference;

  const PaystackWebviewScreen({
    Key? key,
    required this.authorizationUrl,
    required this.reference,
  }) : super(key: key);

  @override
  State<PaystackWebviewScreen> createState() => _PaystackWebviewScreenState();
}

class _PaystackWebviewScreenState extends State<PaystackWebviewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            debugPrint('===== PAGE STARTED =====');
            debugPrint('URL: $url');
            _checkPaymentCompletion(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            debugPrint('===== PAGE FINISHED =====');
            debugPrint('URL: $url');
            _checkPaymentCompletion(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('===== NAVIGATION REQUEST =====');
            debugPrint('URL: ${request.url}');
            _checkPaymentCompletion(request.url);
            return NavigationDecision.navigate;
          },
          onWebResourceError: (error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.authorizationUrl));
  }

  /// FIXED: Check if payment has been completed
  /// Paystack redirects to https://standard.paystack.co/close when successful
  void _checkPaymentCompletion(String url) {
    if (_paymentCompleted) return;

    debugPrint('Checking URL for payment completion: $url');

    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        debugPrint('Could not parse URL');
        return;
      }

      // CRITICAL FIX: Check for Paystack success patterns
      // Pattern 1: /close endpoint (most common)
      if (url.contains('/close')) {
        debugPrint('✅ SUCCESS: Paystack close URL detected');
        _completePayment(success: true);
        return;
      }

      // Pattern 2: trxref parameter (alternative success indicator)
      if (uri.queryParameters.containsKey('trxref') || 
          uri.queryParameters.containsKey('reference')) {
        debugPrint('✅ SUCCESS: Transaction reference found in URL');
        _completePayment(success: true);
        return;
      }

      // Pattern 3: Check for cancelled/failed
      if (url.contains('cancelled=true') || 
          url.contains('/cancel') ||
          url.contains('status=cancelled') ||
          url.contains('status=failed')) {
        debugPrint('❌ CANCELLED: Payment was cancelled');
        _completePayment(success: false);
        return;
      }

      debugPrint('ℹ️ No completion pattern detected in URL');
    } catch (e) {
      debugPrint('Error checking payment completion: $e');
    }
  }

  void _completePayment({required bool success}) {
    if (_paymentCompleted) return;
    
    _paymentCompleted = true;
    debugPrint('===== COMPLETING PAYMENT =====');
    debugPrint('Success: $success');
    debugPrint('Reference: ${widget.reference}');
    
    Navigator.pop(context, {
      'success': success,
      'reference': widget.reference,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => _showCancelDialog(),
        ),
        title: Text(
          'Secure Payment',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Secured',
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
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          
          if (_isLoading)
            Container(
              color: colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading secure payment...',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payments processed securely by Paystack',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cancel Payment?',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this payment?',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Payment',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(this.context, {'success': false}); // Close webview
              },
              child: const Text(
                'Cancel Payment',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}