import 'package:flutter/material.dart';
import '../utils/text_styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({Key? key}) : super(key: key);

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen> {
  final List<SmsMessage> _messages = [];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMockMessages();
  }

  void _loadMockMessages() {
    _messages.addAll([
      SmsMessage(
        id: '1',
        phoneNumber: '+1234567890',
        message: 'Test message from gateway',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        type: SmsType.outgoing,
        status: SmsStatus.sent,
      ),
      SmsMessage(
        id: '2',
        phoneNumber: '+0987654321',
        message: 'Incoming SMS notification',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: SmsType.incoming,
        status: SmsStatus.received,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: Text(
          'SMS',
          style: AppTextStyles.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshMessages,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : _buildMessagesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSendSmsDialog,
        backgroundColor: Colors.blue[600] ?? Colors.blue,
        child: const Icon(Icons.send, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItemWithTooltip(
              icon: Icons.inbox,
              label: 'Total SMS',
              value: '${_messages.length}',
              color: Colors.blue,
              tooltip: 'Total number of SMS messages in the system',
            ),
          ),
          Expanded(
            child: _buildStatItemWithTooltip(
              icon: Icons.call_made,
              label: 'Sent',
              value: '${_messages.where((m) => m.type == SmsType.outgoing).length}',
              color: Colors.green,
              tooltip: 'Number of SMS messages sent from the gateway',
            ),
          ),
          Expanded(
            child: _buildStatItemWithTooltip(
              icon: Icons.call_received,
              label: 'Received',
              value: '${_messages.where((m) => m.type == SmsType.incoming).length}',
              color: Colors.orange,
              tooltip: 'Number of SMS messages received by the gateway',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.poppinsBold(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.poppins(
            fontSize: 12,
            color: Colors.grey[400],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatItemWithTooltip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.poppinsBold(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.poppins(
              fontSize: 12,
              color: Colors.grey[400],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sms,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No SMS messages',
            style: AppTextStyles.poppinsBold(
              fontSize: 18,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send your first SMS message',
            style: AppTextStyles.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageCard(message);
      },
    );
  }

  Widget _buildMessageCard(SmsMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: message.type == SmsType.outgoing
              ? Colors.blue.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                message.type == SmsType.outgoing ? Icons.call_made : Icons.call_received,
                color: message.type == SmsType.outgoing ? Colors.blue : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.phoneNumber,
                  style: AppTextStyles.poppinsBold(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildStatusIcon(message.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.message,
            style: AppTextStyles.poppins(
              fontSize: 14,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTimestamp(message.timestamp),
            style: AppTextStyles.poppins(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(SmsStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case SmsStatus.sent:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case SmsStatus.received:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case SmsStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
      case SmsStatus.pending:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }

    return Icon(
      icon,
      color: color,
      size: 16,
    );
  }

  void _showSendSmsDialog() {
    _phoneController.clear();
    _messageController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          'Send SMS',
          style: AppTextStyles.poppinsBold(
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _phoneController,
              style: AppTextStyles.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: AppTextStyles.poppins(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[400]!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              style: AppTextStyles.poppins(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: AppTextStyles.poppins(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.blue[400]!),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.poppins(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _sendSms,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Send',
                    style: AppTextStyles.poppins(color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSms() async {
    if (_phoneController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate sending SMS
    await Future.delayed(const Duration(seconds: 2));

    final newMessage = SmsMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      phoneNumber: _phoneController.text,
      message: _messageController.text,
      timestamp: DateTime.now(),
      type: SmsType.outgoing,
      status: SmsStatus.sent,
    );

    setState(() {
      _messages.insert(0, newMessage);
      _isLoading = false;
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('SMS sent successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _refreshMessages() {
    // Simulate refresh
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Messages refreshed'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

enum SmsType { incoming, outgoing }
enum SmsStatus { sent, received, failed, pending }

class SmsMessage {
  final String id;
  final String phoneNumber;
  final String message;
  final DateTime timestamp;
  final SmsType type;
  final SmsStatus status;

  SmsMessage({
    required this.id,
    required this.phoneNumber,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.status,
  });
} 