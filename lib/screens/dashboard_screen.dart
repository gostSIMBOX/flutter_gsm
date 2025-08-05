import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/text_styles.dart';
import '../providers/dashboard_provider.dart';
import '../providers/gateway_provider.dart';
import '../widgets/status_card.dart';
import '../widgets/line_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/active_call_card.dart';
import '../widgets/sip_status_card.dart';
import '../widgets/status_indicator.dart';
import '../services/theme_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();

    // Initialize dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      dashboardProvider.initialize();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                  await dashboardProvider.refresh();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickStats(),
                          const SizedBox(height: 24),
                          _buildActiveCalls(),
                          const SizedBox(height: 24),
                          _buildLinesSection(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildThemeIndicators(),
                          const SizedBox(height: 24),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phone_android,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GSM-SIP Gateway',
                  style: TextStyles.headline.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                Consumer<GatewayProvider>(
                  builder: (context, provider, child) {
                    final status = provider.status;
                    return Text(
                      _getStatusText(status.state),
                      style: TextStyles.body.copyWith(
                        color: _getStatusColor(status.state),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logs',
                child: Row(
                  children: [
                    Icon(Icons.list_alt),
                    SizedBox(width: 8),
                    Text('Logs'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Info'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            StatsCard(
              title: 'Total Calls',
              value: '0',
              icon: Icons.call,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/analytics'),
            ),
            StatsCard(
              title: 'SMS Messages',
              value: '0',
              icon: Icons.sms,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/sms'),
            ),
            StatsCard(
              title: 'Active Lines',
              value: dashboardProvider.activeLinesCount.toString(),
              icon: Icons.phone,
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/lines'),
            ),
            StatsCard(
              title: 'Uptime',
              value: '0h',
              icon: Icons.timer,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/info'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveCalls() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.activeCalls.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Call',
              style: TextStyles.headline.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ActiveCallCard(call: dashboardProvider.activeCalls.first),
          ],
        );
      },
    );
  }

  Widget _buildLinesSection() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: TextStyles.headline.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SipStatusCard(
                    connection: dashboardProvider.sipConnection,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatusCard(
                    title: 'GSM Network',
                    status: 'Connected',
                    icon: Icons.signal_cellular_alt,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildActionCard(
              title: 'Make Call',
              icon: Icons.call,
              color: Colors.green,
              onTap: () => Navigator.pushNamed(context, '/calls'),
            ),
            _buildActionCard(
              title: 'Send SMS',
              icon: Icons.sms,
              color: Colors.blue,
              onTap: () => Navigator.pushNamed(context, '/sms'),
            ),
            _buildActionCard(
              title: 'Statistics',
              icon: Icons.analytics,
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/analytics'),
            ),
            _buildActionCard(
              title: 'Settings',
              icon: Icons.settings,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFF1A1A1A),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyles.body.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        if (dashboardProvider.activeCalls.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Calls',
                  style: TextStyles.headline.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/calls'),
                  child: Text(
                    'View All',
                    style: TextStyles.body.copyWith(
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dashboardProvider.activeCalls.take(3).map((call) => _buildRecentCallItem(call)),
          ],
        );
      },
    );
  }

  Widget _buildRecentCallItem(dynamic call) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF1A1A1A),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: call.direction == 'incoming' ? Colors.green : Colors.blue,
          child: Icon(
            call.direction == 'incoming' ? Icons.call_received : Icons.call_made,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          call.fromNumber ?? 'Unknown',
          style: TextStyles.body.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _formatDateTime(call.startTime),
          style: TextStyles.body.copyWith(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () => Navigator.pushNamed(context, '/calls'),
      ),
    );
  }

  String _getStatusText(dynamic state) {
    switch (state) {
      case 'stopped':
        return 'Stopped';
      case 'starting':
        return 'Starting...';
      case 'running':
        return 'Running';
      case 'registered':
        return 'Registered';
      case 'callInProgress':
        return 'Call in Progress';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(dynamic state) {
    switch (state) {
      case 'stopped':
        return Colors.red;
      case 'starting':
        return Colors.orange;
      case 'running':
        return Colors.blue;
      case 'registered':
        return Colors.green;
      case 'callInProgress':
        return Colors.purple;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'logs':
        Navigator.pushNamed(context, '/logs');
        break;
      case 'info':
        Navigator.pushNamed(context, '/info');
        break;
    }
  }

  Widget _buildThemeIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: TextStyles.headline.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        Consumer<GatewayProvider>(
          builder: (context, provider, child) {
            final status = provider.status;
            return Column(
              children: [
                // Connection Status Indicator
                StatusIndicator(
                  status: _getStatusText(status.state),
                  subtitle: 'Gateway connection status',
                  onTap: () {
                    // Navigate to detailed status screen
                  },
                ),
                const SizedBox(height: 12),
                // Signal Level Indicator (simulated)
                SignalIndicator(
                  signalLevel: 75, // Simulated signal level
                  subtitle: 'GSM signal strength',
                ),
                const SizedBox(height: 12),
                // Call Status Indicator (if there's an active call)
                if (status.state == 'callInProgress')
                  CallStatusIndicator(
                    callStatus: 'Active',
                    phoneNumber: '+1234567890',
                    duration: '2:30',
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
} 