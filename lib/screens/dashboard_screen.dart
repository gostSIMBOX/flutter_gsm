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
import '../models/sip_connection.dart';
import '../theme/app_colors.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
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
                          _buildQuickStats(context),
                          const SizedBox(height: 24),
                          _buildActiveCalls(context),
                          const SizedBox(height: 24),
                          _buildLinesSection(context),
                          const SizedBox(height: 24),
                          _buildQuickActions(context),
                          const SizedBox(height: 24),
                          _buildThemeIndicators(context),
                          const SizedBox(height: 24),
                          _buildRecentActivity(context),
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

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.phone_android,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOSTsimbox Gateway',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Consumer<GatewayProvider>(
                  builder: (context, provider, child) {
                    final status = provider.status;
                    return Text(
                      _getStatusText(status.state),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: _getStatusColor(status.state),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Settings', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logs',
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Logs', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text('Info', style: TextStyle(color: colorScheme.onSurface)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final theme = Theme.of(context);
    
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
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/analytics'),
            ),
            Consumer<GatewayProvider>(
              builder: (context, gatewayProvider, child) {
                return StatsCard(
                  title: 'SMS Messages',
                  value: gatewayProvider.smsMessages.length.toString(),
                  icon: Icons.sms,
                  color: AppColors.accent,
                  onTap: () => Navigator.pushNamed(context, '/sms'),
                );
              },
            ),
            StatsCard(
              title: 'Active Lines',
              value: dashboardProvider.activeLinesCount.toString(),
              icon: Icons.phone,
              color: AppColors.technical,
              onTap: () => Navigator.pushNamed(context, '/lines'),
            ),
            StatsCard(
              title: 'Uptime',
              value: '0h',
              icon: Icons.timer,
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(context, '/info'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveCalls(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ActiveCallCard(call: dashboardProvider.activeCalls.first),
          ],
        );
      },
    );
  }

  Widget _buildLinesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Consumer<DashboardProvider>(
      builder: (context, dashboardProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SipStatusCard(
                    connection: dashboardProvider.sipConnection ?? SipConnection(
                      status: 'disconnected',
                      server: '',
                      port: 5060,
                      transport: 'UDP',
                      lastRegistration: DateTime.now(),
                      registrationExpiry: DateTime.now(),
                      jitter: 0.0,
                      latency: 0.0,
                      bandwidthIn: 0.0,
                      bandwidthOut: 0.0,
                      packetLoss: 0.0,
                      mos: 0.0,
                      supportedCodecs: [],
                      activeCodecs: [],
                      username: '',
                      isRegistered: false,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: StatusCard(
                    title: 'GSM Network',
                    status: 'Connected',
                    icon: Icons.signal_cellular_alt,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
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
              context: context,
              title: 'Make Call',
              icon: Icons.call,
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/calls'),
            ),
            _buildActionCard(
              context: context,
              title: 'Send SMS',
              icon: Icons.sms,
              color: AppColors.primary,
              onTap: () => Navigator.pushNamed(context, '/sms'),
            ),
            _buildActionCard(
              context: context,
              title: 'USSD',
              icon: Icons.phone_android,
              color: AppColors.accent,
              onTap: () => Navigator.pushNamed(context, '/ussd'),
            ),
            _buildActionCard(
              context: context,
              title: 'SMPP Settings',
              icon: Icons.settings,
              color: Colors.purple,
              onTap: () => Navigator.pushNamed(context, '/smpp-settings'),
            ),
            _buildActionCard(
              context: context,
              title: 'Statistics',
              icon: Icons.analytics,
              color: AppColors.technical,
              onTap: () => Navigator.pushNamed(context, '/analytics'),
            ),
            _buildActionCard(
              context: context,
              title: 'Settings',
              icon: Icons.settings,
              color: AppColors.warning,
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      color: colorScheme.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/calls'),
                  child: Text(
                    'View All',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...dashboardProvider.activeCalls.take(3).map((call) => _buildRecentCallItem(context, call)),
          ],
        );
      },
    );
  }

  Widget _buildRecentCallItem(BuildContext context, dynamic call) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: call.direction == 'incoming' ? AppColors.accent : AppColors.primary,
          child: Icon(
            call.direction == 'incoming' ? Icons.call_received : Icons.call_made,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          call.fromNumber ?? 'Unknown',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          _formatDateTime(call.startTime),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: colorScheme.onSurfaceVariant,
          size: 16,
        ),
        onTap: () => Navigator.pushNamed(context, '/calls'),
      ),
    );
  }

  Widget _buildThemeIndicators(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Status',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
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
        return AppColors.error;
      case 'starting':
        return AppColors.warning;
      case 'running':
        return AppColors.primary;
      case 'registered':
        return AppColors.success;
      case 'callInProgress':
        return AppColors.technical;
      case 'error':
        return AppColors.error;
      default:
        return AppColors.info;
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
} 