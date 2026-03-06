/// Gateway Service
/// Core orchestration service for bidirectional SIP↔GSM routing

import 'dart:async';
import 'package:logger/logger.dart';
import '../entities/gateway_config.dart';
import '../entities/gateway_status.dart';
import '../entities/call_routing.dart';
import 'sip_service.dart';

/// Gateway Service Singleton
///
/// Orchestrates bidirectional routing between SIP and GSM telephony.
/// Manages call routings, state synchronization, and statistics.
class GatewayService {
  static final GatewayService _instance = GatewayService._internal();
  factory GatewayService() => _instance;
  GatewayService._internal();

  final Logger _logger = Logger();

  // Sub-services
  final SipService _sipService = SipService();
  // TelephonyService would be imported from existing implementation
  // final TelephonyService _telephonyService = TelephonyService();

  // Configuration
  GatewayConfig? _config;
  bool _isRunning = false;
  DateTime? _startTime;

  // Statistics
  int _totalCallsHandled = 0;
  int _totalMessagesHandled = 0;

  // Active routings
  final Map<String, CallRouting> _activeRoutings = {};
  int _routingCounter = 0;

  // Stream controllers
  final _statusController = StreamController<GatewayStatus>.broadcast();
  final _routingController = StreamController<CallRouting>.broadcast();
  final _logController = StreamController<String>.broadcast();

  // Event subscriptions
  StreamSubscription? _sipEventSubscription;

  /// Get current configuration
  GatewayConfig? get config => _config;

  /// Check if gateway is running
  bool get isRunning => _isRunning;

  /// Get start time
  DateTime? get startTime => _startTime;

  /// Get total calls handled
  int get totalCallsHandled => _totalCallsHandled;

  /// Get total messages handled
  int get totalMessagesHandled => _totalMessagesHandled;

  /// Get active routings
  Map<String, CallRouting> get activeRoutings =>
      Map.unmodifiable(_activeRoutings);

  /// Get active routing count
  int get activeRoutingCount => _activeRoutings.length;

  /// Get active call count
  int get activeCallCount =>
      _activeRoutings.values.where((r) => r.isActive).length;

  /// Stream of gateway status updates
  Stream<GatewayStatus> get statusStream => _statusController.stream;

  /// Stream of call routing updates
  Stream<CallRouting> get routingStream => _routingController.stream;

  /// Stream of log messages
  Stream<String> get logStream => _logController.stream;

  /// Initialize gateway with configuration
  Future<bool> initialize(GatewayConfig config) async {
    try {
      _log('Initializing gateway...');

      // Validate configuration
      if (!config.isValid) {
        _log('Invalid configuration: ${config.validationErrors.join(', ')}');
        return false;
      }

      _config = config;

      // Initialize SIP service
      _log('Initializing SIP service...');
      await _sipService.initialize();

      // Setup SIP event listeners
      _setupSipEventListeners();

      _log('Gateway initialized successfully');
      _broadcastStatus();
      return true;
    } catch (e) {
      _log('Failed to initialize gateway: $e');
      _broadcastStatus();
      return false;
    }
  }

  /// Start gateway routing
  Future<bool> start() async {
    try {
      if (_config == null) {
        _log('Cannot start: configuration not loaded');
        return false;
      }

      if (_isRunning) {
        _log('Gateway already running');
        return true;
      }

      _log('Starting gateway...');

      // Register SIP account
      final sipAccount = _config!.sipAccount;
      await _sipService.createAccount(sipAccount);
      await _sipService.registerAccount(sipAccount.id);

      _isRunning = true;
      _startTime = DateTime.now();

      _log('Gateway started successfully');
      _broadcastStatus();
      return true;
    } catch (e) {
      _log('Failed to start gateway: $e');
      _isRunning = false;
      _broadcastStatus();
      return false;
    }
  }

  /// Stop gateway routing
  Future<void> stop() async {
    try {
      if (!_isRunning) return;

      _log('Stopping gateway...');

      // End all active routings
      await _endAllRoutings();

      // Unregister SIP account
      if (_config?.sipAccount != null) {
        await _sipService.unregisterAccount(_config!.sipAccount.id);
      }

      _isRunning = false;
      _startTime = null;

      _log('Gateway stopped');
      _broadcastStatus();
    } catch (e) {
      _log('Error stopping gateway: $e');
    }
  }

  /// Dispose gateway resources
  Future<void> dispose() async {
    try {
      await stop();

      // Close stream controllers
      await _statusController.close();
      await _routingController.close();
      await _logController.close();

      // Cancel subscriptions
      await _sipEventSubscription?.cancel();

      _log('Gateway disposed');
    } catch (e) {
      _log('Error disposing gateway: $e');
    }
  }

  /// Setup SIP event listeners
  void _setupSipEventListeners() {
    _sipEventSubscription = _sipService.eventStream.listen(
      _handleSipEvent,
      onError: (e) => _log('SIP event error: $e'),
    );
  }

  /// Handle SIP event
  void _handleSipEvent(dynamic event) {
    // Handle SIP events and update routings accordingly
    // This would sync SIP call states with GSM call states
  }

  /// Make call via SIP (SIP→GSM routing)
  Future<String?> makeCallViaSip(String number) async {
    try {
      if (!_isRunning) {
        _log('Cannot make call: gateway not running');
        return null;
      }

      if (!_config!.routeSipToGsm) {
        _log('SIP→GSM routing is disabled');
        return null;
      }

      // Check max concurrent calls
      if (activeCallCount >= _config!.maxConcurrentCalls) {
        _log('Max concurrent calls reached: ${_config!.maxConcurrentCalls}');
        return null;
      }

      _log('Making call via SIP: $number');

      // Get default account
      final account = _config!.sipAccount;

      // Make SIP call
      final sipCall = await _sipService.makeCall(account.id, number);
      final sipCallId = sipCall.id;

      // Create routing
      final routingId = _generateRoutingId();
      final routing = CallRouting.sipToGsm(
        id: routingId,
        sipCallId: sipCallId,
        number: number,
      );

      _activeRoutings[routingId] = routing;
      _routingController.add(routing);

      _log('Created routing $routingId for SIP call $sipCallId');

      // Wait for SIP call to be active, then make GSM call
      // This would be handled by event listeners in full implementation

      return routingId;
    } catch (e) {
      _log('Error making call via SIP: $e');
      return null;
    }
  }

  /// Make call via GSM (GSM→SIP routing)
  Future<String?> makeCallViaGsm(String number) async {
    try {
      if (!_isRunning) {
        _log('Cannot make call: gateway not running');
        return null;
      }

      if (!_config!.routeGsmToSip) {
        _log('GSM→SIP routing is disabled');
        return null;
      }

      _log('Making call via GSM: $number');

      // Create routing first
      final routingId = _generateRoutingId();
      final routing = CallRouting.gsmToSip(
        id: routingId,
        telephonyCallId: 'gsm_${DateTime.now().millisecondsSinceEpoch}',
        number: number,
      );

      _activeRoutings[routingId] = routing;
      _routingController.add(routing);

      _log('Created routing $routingId for GSM call');

      // Make SIP call to bridge
      // This would be handled by event listeners in full implementation

      return routingId;
    } catch (e) {
      _log('Error making call via GSM: $e');
      return null;
    }
  }

  /// Send SMS
  Future<String?> sendSms(String recipient, String content, {bool useSmpp = false}) async {
    try {
      if (!_isRunning) {
        _log('Cannot send SMS: gateway not running');
        return null;
      }

      _log('Sending SMS to $recipient (useSmpp: $useSmpp)');

      // If useSmpp and SMPP configured, use SMPP
      if (useSmpp && _config!.isSmppConfigured) {
        _log('Would send via SMPP (not implemented in this phase)');
      } else {
        _log('Would send via local GSM (not implemented in this phase)');
      }

      _totalMessagesHandled++;
      _broadcastStatus();

      return 'sms_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      _log('Error sending SMS: $e');
      return null;
    }
  }

  /// Get routing by ID
  CallRouting? getRouting(String routingId) {
    return _activeRoutings[routingId];
  }

  /// Get all active routings
  List<CallRouting> getActiveRoutings() {
    return _activeRoutings.values.toList();
  }

  /// End specific routing
  Future<void> endRouting(String routingId) async {
    try {
      final routing = _activeRoutings[routingId];
      if (routing == null) {
        _log('Routing not found: $routingId');
        return;
      }

      _log('Ending routing $routingId');

      // End SIP call if exists
      if (routing.sipCallId.isNotEmpty) {
        try {
          await _sipService.hangupCall(routing.sipCallId);
        } catch (e) {
          _log('Error ending SIP call: $e');
        }
      }

      // Update routing state
      final updatedRouting = routing.copyWith(
        state: CallRoutingState.ended,
        endTime: DateTime.now(),
      );
      _activeRoutings[routingId] = updatedRouting;
      _routingController.add(updatedRouting);

      // Remove from active routings after delay
      Future.delayed(const Duration(seconds: 5), () {
        _activeRoutings.remove(routingId);
      });

      _totalCallsHandled++;
      _broadcastStatus();

      _log('Routing $routingId ended');
    } catch (e) {
      _log('Error ending routing: $e');
    }
  }

  /// End all active routings
  Future<void> _endAllRoutings() async {
    final routingIds = _activeRoutings.keys.toList();
    for (final id in routingIds) {
      await endRouting(id);
    }
  }

  /// Get current status
  GatewayStatus getStatus() {
    return GatewayStatus(
      isRunning: _isRunning,
      sipState: _sipService.isInitialized
          ? SipConnectionState.connected
          : SipConnectionState.disconnected,
      telephonyPermissions: TelephonyPermissionStatus.granted,
      activeCalls: activeCallCount,
      totalCallsHandled: _totalCallsHandled,
      totalMessagesHandled: _totalMessagesHandled,
      startTime: _startTime,
      uptime: _startTime != null ? DateTime.now().difference(_startTime!) : null,
      activeRoutings: _activeRoutings.length,
    );
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isRunning': _isRunning,
      'startTime': _startTime?.toIso8601String(),
      'uptime': _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0,
      'totalCallsHandled': _totalCallsHandled,
      'totalMessagesHandled': _totalMessagesHandled,
      'activeCalls': activeCallCount,
      'activeRoutings': _activeRoutings.length,
      'sipConnected': _sipService.isInitialized,
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _totalCallsHandled = 0;
    _totalMessagesHandled = 0;
    _log('Statistics reset');
    _broadcastStatus();
  }

  /// Generate unique routing ID
  String _generateRoutingId() {
    _routingCounter++;
    return 'routing_${DateTime.now().millisecondsSinceEpoch}_$_routingCounter';
  }

  /// Broadcast status update
  void _broadcastStatus() {
    final status = getStatus();
    _statusController.add(status);
  }

  /// Log message
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _logger.i(logMessage);
    if (_config?.enableLogging ?? true) {
      _logController.add(logMessage);
    }
  }
}
