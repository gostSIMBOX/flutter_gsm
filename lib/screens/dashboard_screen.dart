import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/gateway_service.dart';
import '../services/sip_service.dart';
import '../services/sms_service.dart';
import '../services/telephony_service.dart';
import 'settings_screen.dart';
import 'call_screen.dart';
import 'sms_screen.dart';
import 'logs_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  GatewayStatus? _gatewayStatus;
  String? _phoneNumber;
  String? _networkOperator;
  int? _signalStrength;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    final gatewayService = context.read<GatewayService>();
    final telephonyService = context.read<TelephonyService>();
    
    // Listen to gateway status changes
    gatewayService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          _gatewayStatus = status;
        });
      }
    });
    
    // Get device info
    _phoneNumber = await telephonyService.getPhoneNumber();
    _networkOperator = await telephonyService.getNetworkOperatorName();
    _signalStrength = await telephonyService.getSignalStrength();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GOSTsimbox Gateway'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Overview
              _buildStatusOverview(),
              const SizedBox(height: 16),
              
              // Service Status Cards
              _buildServiceStatusCards(),
              const SizedBox(height: 16),
              
              // Device Information
              _buildDeviceInfo(),
              const SizedBox(height: 16),
              
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 16),
              
              // Statistics
              _buildStatistics(),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildStatusOverview() {
    final isRunning = _gatewayStatus?.isRunning ?? false;
    final uptime = _gatewayStatus?.uptime;
    
    return Card(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isRunning
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.grey.shade400, Colors.grey.shade600],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isRunning ? Icons.router : Icons.router_outlined,
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gateway Status',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        isRunning ? 'Running' : 'Stopped',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isRunning && uptime != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Uptime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      Text(
                        _formatDuration(uptime),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusCards() {
    final sipState = _gatewayStatus?.sipState ?? SipConnectionState.disconnected;
    final smppState = _gatewayStatus?.smppState ?? SmppConnectionState.disconnected;
    final activeCalls = _gatewayStatus?.activeCalls ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            'SIP',
            _sipStateToString(sipState),
            _sipStateToColor(sipState),
            Icons.phone_in_talk,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'SMS',
            _smppStateToString(smppState),
            _smppStateToColor(smppState),
            Icons.sms,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatusCard(
            'Calls',
            activeCalls.toString(),
            activeCalls > 0 ? Colors.blue : Colors.grey,
            Icons.call,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Device Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            if (_phoneNumber != null)
              _buildInfoRow('Phone Number', _phoneNumber!),
            if (_networkOperator != null)
              _buildInfoRow('Network Operator', _networkOperator!),
            if (_signalStrength != null)
              _buildInfoRow('Signal Strength', '$_signalStrength dBm'),
            
            _buildInfoRow('Gateway Version', '3.0.0'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                  'Make Call',
                  Icons.call,
                  () => _navigateToCallScreen(),
                ),
                _buildActionButton(
                  'Send SMS',
                  Icons.sms,
                  () => _navigateToSmsScreen(),
                ),
                _buildActionButton(
                  'USSD',
                  Icons.dialpad,
                  () => _showUssdDialog(),
                ),
                _buildActionButton(
                  'Logs',
                  Icons.list_alt,
                  () => _navigateToLogsScreen(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onPressed) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final totalCalls = _gatewayStatus?.totalCallsHandled ?? 0;
    final totalMessages = _gatewayStatus?.totalMessagesHandled ?? 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Calls', totalCalls.toString()),
                _buildStatItem('Total Messages', totalMessages.toString()),
                _buildStatItem('Success Rate', '98.5%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    final isRunning = _gatewayStatus?.isRunning ?? false;
    
    return FloatingActionButton.extended(
      onPressed: _toggleGateway,
      icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
      label: Text(isRunning ? 'Stop' : 'Start'),
      backgroundColor: isRunning ? Colors.red : Colors.green,
    );
  }

  // Navigation methods
  void _navigateToCallScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CallScreen()),
    );
  }

  void _navigateToSmsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SmsScreen()),
    );
  }

  void _navigateToLogsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LogsScreen()),
    );
  }

  void _showUssdDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send USSD'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'USSD Code',
            hintText: '*123#',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _sendUssd(controller.text);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // Action methods
  Future<void> _toggleGateway() async {
    final gatewayService = context.read<GatewayService>();
    
    if (_gatewayStatus?.isRunning == true) {
      await gatewayService.stop();
    } else {
      await gatewayService.start();
    }
  }

  Future<void> _sendUssd(String ussdCode) async {
    final telephonyService = context.read<TelephonyService>();
    
    try {
      final response = await telephonyService.sendUssd(ussdCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response ?? 'USSD sent successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('USSD failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    final telephonyService = context.read<TelephonyService>();
    
    _phoneNumber = await telephonyService.getPhoneNumber();
    _networkOperator = await telephonyService.getNetworkOperatorName();
    _signalStrength = await telephonyService.getSignalStrength();
    
    if (mounted) {
      setState(() {});
    }
  }

  // Helper methods
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _sipStateToString(SipConnectionState state) {
    switch (state) {
      case SipConnectionState.connected:
        return 'Connected';
      case SipConnectionState.connecting:
        return 'Connecting';
      case SipConnectionState.disconnected:
        return 'Disconnected';
      case SipConnectionState.error:
        return 'Error';
    }
  }

  Color _sipStateToColor(SipConnectionState state) {
    switch (state) {
      case SipConnectionState.connected:
        return Colors.green;
      case SipConnectionState.connecting:
        return Colors.orange;
      case SipConnectionState.disconnected:
        return Colors.grey;
      case SipConnectionState.error:
        return Colors.red;
    }
  }

  String _smppStateToString(SmppConnectionState state) {
    switch (state) {
      case SmppConnectionState.bound:
        return 'Connected';
      case SmppConnectionState.connecting:
        return 'Connecting';
      case SmppConnectionState.disconnected:
        return 'Disconnected';
      case SmppConnectionState.error:
        return 'Error';
    }
  }

  Color _smppStateToColor(SmppConnectionState state) {
    switch (state) {
      case SmppConnectionState.bound:
        return Colors.green;
      case SmppConnectionState.connecting:
        return Colors.orange;
      case SmppConnectionState.disconnected:
        return Colors.grey;
      case SmppConnectionState.error:
        return Colors.red;
    }
  }
}