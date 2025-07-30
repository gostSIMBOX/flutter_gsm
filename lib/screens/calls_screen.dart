import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gateway_provider.dart';
import '../models/active_call.dart';
import '../models/gateway_status.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({Key? key}) : super(key: key);

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh call history
            },
          ),
        ],
      ),
      body: Consumer<GatewayProvider>(
        builder: (context, provider, child) {
          final status = provider.status;
          final currentCall = status.currentCall;
          final recentCalls = status.recentCalls;

          return Column(
            children: [
              // Current call status
              if (currentCall != null) _buildCurrentCallCard(currentCall),
              
              // Call controls
              _buildCallControls(provider),
              
              // Recent calls
              Expanded(
                child: _buildRecentCallsList(recentCalls),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentCallCard(CallInfo call) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  call.direction == CallDirection.incoming 
                    ? Icons.call_received 
                    : Icons.call_made,
                  color: _getCallStateColor(call.state),
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Call',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              call.number,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _getCallStateText(call.state),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _getCallStateColor(call.state),
              ),
            ),
            if (call.startTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Started: ${_formatDateTime(call.startTime!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCallControls(GatewayProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Number input
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            
            // Call buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(provider),
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendSms(provider),
                    icon: const Icon(Icons.sms),
                    label: const Text('SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            // Message input for SMS
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter SMS message',
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCallsList(List<CallInfo> calls) {
    if (calls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.call_history,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No recent calls',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCallStateColor(call.state),
              child: Icon(
                call.direction == CallDirection.incoming 
                  ? Icons.call_received 
                  : Icons.call_made,
                color: Colors.white,
              ),
            ),
            title: Text(call.number),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getCallStateText(call.state)),
                if (call.startTime != null)
                  Text(
                    _formatDateTime(call.startTime!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleCallAction(value, call),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'call',
                  child: Row(
                    children: [
                      Icon(Icons.call),
                      SizedBox(width: 8),
                      Text('Call'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sms',
                  child: Row(
                    children: [
                      Icon(Icons.sms),
                      SizedBox(width: 8),
                      Text('Send SMS'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 8),
                      Text('Call Info'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCallStateColor(CallState state) {
    switch (state) {
      case CallState.ringing:
        return Colors.orange;
      case CallState.connecting:
        return Colors.blue;
      case CallState.connected:
        return Colors.green;
      case CallState.disconnected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getCallStateText(CallState state) {
    switch (state) {
      case CallState.ringing:
        return 'Ringing';
      case CallState.connecting:
        return 'Connecting';
      case CallState.connected:
        return 'Connected';
      case CallState.disconnected:
        return 'Disconnected';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _makeCall(GatewayProvider provider) {
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }

    provider.makeCall(number).then((_) {
      _numberController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling $number...')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making call: $error')),
      );
    });
  }

  void _sendSms(GatewayProvider provider) {
    final number = _numberController.text.trim();
    final message = _messageController.text.trim();
    
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a phone number')),
      );
      return;
    }
    
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
      return;
    }

    provider.sendSms(number, message).then((success) {
      if (success) {
        _numberController.clear();
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SMS sent to $number')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send SMS')),
        );
      }
    });
  }

  void _handleCallAction(String action, CallInfo call) {
    switch (action) {
      case 'call':
        _numberController.text = call.number;
        _makeCall(context.read<GatewayProvider>());
        break;
      case 'sms':
        _numberController.text = call.number;
        // Show SMS dialog
        _showSmsDialog(call.number);
        break;
      case 'info':
        _showCallInfoDialog(call);
        break;
    }
  }

  void _showSmsDialog(String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send SMS to $number'),
        content: TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Message',
            hintText: 'Enter your message',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSms(context.read<GatewayProvider>());
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showCallInfoDialog(CallInfo call) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Number: ${call.number}'),
            Text('Direction: ${call.direction.name}'),
            Text('State: ${call.state.name}'),
            if (call.startTime != null)
              Text('Start Time: ${_formatDateTime(call.startTime!)}'),
            if (call.endTime != null)
              Text('End Time: ${_formatDateTime(call.endTime!)}'),
            if (call.startTime != null && call.endTime != null) {
              final duration = call.endTime!.difference(call.startTime!);
              Text('Duration: ${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}'),
            } else const SizedBox.shrink(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 