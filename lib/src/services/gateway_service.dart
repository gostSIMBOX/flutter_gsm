import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sip_service.dart';
import 'sms_service.dart';
import 'telephony_service.dart';
import '../models/smpp_config.dart';
import '../domain/entities/gateway_status.dart';
import '../domain/entities/gateway_config.dart';
import '../domain/entities/call_routing.dart';
import '../domain/entities/sip_account.dart';
import '../domain/entities/sip_call.dart';
import '../domain/entities/sip_event.dart';

/// Main Gateway Service that coordinates SIP, SMS, and Telephony services
class GatewayService {
  static final GatewayService _instance = GatewayService._internal();
  factory GatewayService() => _instance;
  GatewayService._internal();

  final Logger _logger = Logger();
  
  // Service instances
  final SipService _sipService = SipService();
  final SmsService _smsService = SmsService();
  final TelephonyService _telephonyService = TelephonyService();
  
  // Configuration and state
  GatewayConfig? _config;
  bool _isRunning = false;
  DateTime? _startTime;
  int _totalCallsHandled = 0;
  int _totalMessagesHandled = 0;
  
  // Call routing
  final Map<String, CallRouting> _activeRoutings = {};
  int _routingCounter = 0;
  
  // Stream controllers
  final StreamController<GatewayStatus> _statusController = 
      StreamController<GatewayStatus>.broadcast();
  final StreamController<CallRouting> _routingController = 
      StreamController<CallRouting>.broadcast();
  final StreamController<String> _logController = 
      StreamController<String>.broadcast();

  // Getters
  bool get isRunning => _isRunning;
  GatewayConfig? get config => _config;
  List<CallRouting> get activeRoutings => _activeRoutings.values.toList();

  // Streams
  Stream<GatewayStatus> get statusStream => _statusController.stream;
  Stream<CallRouting> get routingStream => _routingController.stream;
  Stream<String> get logStream => _logController.stream;

  /// Initialize the gateway with configuration
  Future<bool> initialize(GatewayConfig config) async {
    try {
      _config = config;
      _log('Initializing Gateway service...');
      
      // Initialize telephony service first
      final telephonyInitialized = await _telephonyService.initialize();
      if (!telephonyInitialized) {
        _log('Failed to initialize telephony service');
        return false;
      }
      
      // Initialize SIP service
      final sipInitialized = await _sipService.initialize(config.sipAccount);
      if (!sipInitialized) {
        _log('Failed to initialize SIP service');
        return false;
      }
      
      // Initialize SMPP if configured
      if (config.smppConfig != null) {
        final smppInitialized = await _smsService.initializeSmpp(config.smppConfig!);
        if (!smppInitialized) {
          _log('Warning: Failed to initialize SMPP service');
        }
      }
      
      // Set up event listeners
      _setupEventListeners();
      
      // Save configuration
      await _saveConfiguration();
      
      _log('Gateway service initialized successfully');
      return true;
    } catch (e) {
      _log('Failed to initialize Gateway service: $e');
      return false;
    }
  }

  /// Start the gateway service
  Future<bool> start() async {
    if (_config == null) {
      _log('Gateway not configured');
      return false;
    }

    try {
      _log('Starting Gateway service...');
      
      // Register SIP
      final sipRegistered = await _sipService.register();
      if (!sipRegistered) {
        _log('Failed to register SIP');
        return false;
      }
      
      // Connect SMPP if configured
      if (_config!.smppConfig != null) {
        final smppConnected = await _smsService.connectSmpp();
        if (!smppConnected) {
          _log('Warning: Failed to connect SMPP');
        }
      }
      
      _isRunning = true;
      _startTime = DateTime.now();
      _log('Gateway service started successfully');
      _updateStatus();
      
      return true;
    } catch (e) {
      _log('Failed to start Gateway service: $e');
      return false;
    }
  }

  /// Stop the gateway service
  Future<void> stop() async {
    try {
      _log('Stopping Gateway service...');

      // End all active routings
      await endAllRoutings();

      // Unregister SIP
      await _sipService.unregister();

      // Disconnect SMPP
      await _smsService.disconnectSmpp();

      _isRunning = false;
      _startTime = null;
      _log('Gateway service stopped');
      _updateStatus();
    } catch (e) {
      _log('Error stopping Gateway service: $e');
    }
  }

  /// End all active routings
  Future<void> endAllRoutings() async {
    for (final routing in _activeRoutings.values) {
      await _endRouting(routing.id);
    }
    _log('All routings ended');
  }

  /// Make a call via SIP that will be routed to GSM
  Future<String?> makeCallViaSip(String number) async {
    if (!_isRunning || !_config!.routeSipToGsm) {
      return null;
    }

    try {
      _log('Making call via SIP to be routed to GSM: $number');
      
      // Make SIP call
      final sipCallId = await _sipService.makeCall(number);
      if (sipCallId == null) {
        return null;
      }
      
      // Create routing
      final routingId = 'routing_${++_routingCounter}_${DateTime.now().millisecondsSinceEpoch}';
      final routing = CallRouting(
        id: routingId,
        sipCallId: sipCallId,
        number: number,
        direction: CallRoutingDirection.sipToGsm,
        state: CallRoutingState.connecting,
        startTime: DateTime.now(),
      );
      
      _activeRoutings[routingId] = routing;
      _routingController.add(routing);
      
      // When SIP call becomes active, make GSM call
      _sipService.callStateStream.listen((sipCall) {
        if (sipCall.id == sipCallId && sipCall.state == CallState.active) {
          _makeGsmCallForRouting(routingId, number);
        }
      });
      
      return routingId;
    } catch (e) {
      _log('Error making call via SIP: $e');
      return null;
    }
  }

  /// Handle incoming GSM call and route to SIP
  Future<void> _handleIncomingGsmCall(TelephonyCall gsmCall) async {
    if (!_config!.routeGsmToSip) {
      return;
    }

    try {
      _log('Routing incoming GSM call to SIP: ${gsmCall.number}');
      
      // Create SIP call to route the GSM call
      final sipCallId = await _sipService.makeCall(gsmCall.number);
      if (sipCallId == null) {
        return;
      }
      
      final routingId = 'routing_${++_routingCounter}_${DateTime.now().millisecondsSinceEpoch}';
      final routing = CallRouting(
        id: routingId,
        sipCallId: sipCallId,
        telephonyCallId: gsmCall.id,
        number: gsmCall.number,
        direction: CallRoutingDirection.gsmToSip,
        state: CallRoutingState.connecting,
        startTime: DateTime.now(),
      );
      
      _activeRoutings[routingId] = routing;
      _routingController.add(routing);
      
      // Auto-answer GSM call if configured
      if (_config!.autoAnswer) {
        await _telephonyService.answerCall();
      }
      
      _totalCallsHandled++;
    } catch (e) {
      _log('Error routing GSM call to SIP: $e');
    }
  }

  /// Make GSM call for SIP routing
  Future<void> _makeGsmCallForRouting(String routingId, String number) async {
    try {
      final telephonyCallId = await _telephonyService.makeCall(number);
      if (telephonyCallId == null) {
        await _endRouting(routingId);
        return;
      }
      
      final routing = _activeRoutings[routingId];
      if (routing != null) {
        final updatedRouting = CallRouting(
          id: routing.id,
          sipCallId: routing.sipCallId,
          telephonyCallId: telephonyCallId,
          number: routing.number,
          direction: routing.direction,
          state: CallRoutingState.active,
          startTime: routing.startTime,
        );
        
        _activeRoutings[routingId] = updatedRouting;
        _routingController.add(updatedRouting);
      }
      
      _totalCallsHandled++;
    } catch (e) {
      _log('Error making GSM call for routing: $e');
      await _endRouting(routingId);
    }
  }

  /// End a call routing
  Future<void> _endRouting(String routingId) async {
    final routing = _activeRoutings[routingId];
    if (routing == null) return;

    try {
      // End SIP call
      await _sipService.endCall(routing.sipCallId);
      
      // End GSM call if exists
      if (routing.telephonyCallId != null) {
        await _telephonyService.endCall();
      }
      
      final endedRouting = CallRouting(
        id: routing.id,
        sipCallId: routing.sipCallId,
        telephonyCallId: routing.telephonyCallId,
        number: routing.number,
        direction: routing.direction,
        state: CallRoutingState.ended,
        startTime: routing.startTime,
      );
      
      _activeRoutings.remove(routingId);
      _routingController.add(endedRouting);
      
    } catch (e) {
      _log('Error ending routing: $e');
    }
  }

  /// Send SMS via appropriate service
  Future<String?> sendSms(String recipient, String content, {bool useSmpp = false}) async {
    try {
      if (useSmpp && _config?.smppConfig != null) {
        return await _smsService.sendSmsViaSmpp(recipient, content);
      } else {
        return await _smsService.sendSmsLocal(recipient, content);
      }
    } catch (e) {
      _log('Error sending SMS: $e');
      return null;
    }
  }

  /// Get gateway status
  GatewayStatus getStatus() {
    final telephonyPermissions = TelephonyPermissionStatus.granted; // Simplified for now
    
    return GatewayStatus(
      isRunning: _isRunning,
      sipState: _sipService.connectionState,
      smppState: _smsService.connectionState,
      telephonyPermissions: telephonyPermissions,
      activeCalls: _activeRoutings.length,
      totalCallsHandled: _totalCallsHandled,
      totalMessagesHandled: _totalMessagesHandled,
      startTime: _startTime,
      uptime: _startTime != null ? DateTime.now().difference(_startTime!) : null,
    );
  }

  /// Set up event listeners for all services
  void _setupEventListeners() {
    // SIP event listeners
    _sipService.callStateStream.listen(_handleSipCallStateChange);
    _sipService.logStream.listen(_handleServiceLog);
    
    // SMS event listeners
    _smsService.messageStream.listen(_handleSmsMessage);
    _smsService.logStream.listen(_handleServiceLog);
    
    // Telephony event listeners
    _telephonyService.callStateStream.listen(_handleTelephonyCallStateChange);
    _telephonyService.logStream.listen(_handleServiceLog);
  }

  /// Handle SIP call state changes
  void _handleSipCallStateChange(SipCall call) {
    _log('SIP call state changed: ${call.id} -> ${call.state.name}');
    _updateStatus();
  }

  /// Handle telephony call state changes
  void _handleTelephonyCallStateChange(TelephonyCall call) {
    _log('Telephony call state changed: ${call.id} -> ${call.state.name}');
    
    if (call.direction == TelephonyCallDirection.incoming && 
        call.state == TelephonyCallState.ringing) {
      _handleIncomingGsmCall(call);
    }
    
    _updateStatus();
  }

  /// Handle SMS messages
  void _handleSmsMessage(SmsMessage message) {
    _log('SMS message: ${message.type.name} ${message.id}');
    _totalMessagesHandled++;
    _updateStatus();
  }

  /// Handle service logs
  void _handleServiceLog(String log) {
    if (_config?.enableLogging == true) {
      _logController.add(log);
    }
  }

  /// Update gateway status
  void _updateStatus() {
    _statusController.add(getStatus());
  }

  /// Save configuration to persistent storage
  Future<void> _saveConfiguration() async {
    if (_config == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = jsonEncode(_config!.toJson());
      await prefs.setString('gateway_config', configJson);
    } catch (e) {
      _log('Error saving configuration: $e');
    }
  }

  /// Load configuration from persistent storage
  Future<GatewayConfig?> loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('gateway_config');
      if (configJson != null) {
        final configMap = jsonDecode(configJson) as Map<String, dynamic>;
        return GatewayConfig.fromJson(configMap);
      }
    } catch (e) {
      _log('Error loading configuration: $e');
    }
    return null;
  }

  /// Make a call via GSM
  Future<String?> makeCallViaGsm(String number) async {
    if (!_isRunning) {
      return null;
    }
    try {
      _log('Making call via GSM: $number');
      final callId = await _telephonyService.makeCall(number);
      return callId;
    } catch (e) {
      _log('Failed to make GSM call: $e');
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

  /// End a specific routing
  Future<void> endRouting(String routingId) async {
    final routing = _activeRoutings.remove(routingId);
    if (routing != null) {
      _log('Ended routing: $routingId');
      _routingController.add(routing);
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalCallsHandled': _totalCallsHandled,
      'totalMessagesHandled': _totalMessagesHandled,
      'activeRoutings': _activeRoutings.length,
      'uptime': _startTime != null ? DateTime.now().difference(_startTime!) : Duration.zero,
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _totalCallsHandled = 0;
    _totalMessagesHandled = 0;
    _log('Statistics reset');
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] Gateway: $message';
    _logger.i(logMessage);
    _logController.add(logMessage);
  }

  /// Clean up resources
  void dispose() {
    _statusController.close();
    _routingController.close();
    _logController.close();
    
        _sipService.dispose();
    _smsService.dispose();
    _telephonyService.dispose();
  }
}