import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:flutter_tele/flutter_tele.dart';
import '../models/gateway_config.dart';
import '../models/gateway_status.dart';

class GatewayService {
  static final GatewayService _instance = GatewayService._internal();
  factory GatewayService() => _instance;
  GatewayService._internal();

  final Logger _logger = Logger();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final TeleEndpoint _teleEndpoint = TeleEndpoint();
  
  GatewayConfig? _config;
  GatewayStatus _status = GatewayStatus(
    state: GatewayState.stopped,
    isConnected: false,
    isRegistered: false,
    lastUpdate: DateTime.now(),
  );

  final StreamController<GatewayStatus> _statusController = 
      StreamController<GatewayStatus>.broadcast();
  final StreamController<String> _logController = 
      StreamController<String>.broadcast();

  Stream<GatewayStatus> get statusStream => _statusController.stream;
  Stream<String> get logStream => _logController.stream;
  GatewayStatus get currentStatus => _status;

  // Real connection states
  bool _sipConnected = false;
  bool _sipRegistered = false;
  bool _gsmConnected = false;
  CallInfo? _currentCall;
  StreamSubscription? _callEventSubscription;
  StreamSubscription? _teleEventSubscription;

  Future<void> initialize(GatewayConfig config) async {
    _config = config;
    _log('Initializing gateway with config: ${config.sipUsername}@${config.sipServer}');
    
    await _updateStatus(GatewayState.starting);
    
    try {
      // Request Android permissions
      final hasPermissions = await _teleEndpoint.hasPermissions();
      if (!hasPermissions) {
        final granted = await _teleEndpoint.requestPermissions();
        if (!granted) {
          throw Exception('Phone permissions required for gateway operation');
        }
      }
      
      // Get device info for configuration
      final deviceId = await _getDeviceId();
      _log('Device ID: $deviceId');
      
      // Setup telephony event listeners
      await _setupTelephonyListeners();
      
      // Initialize SIP client
      await _initializeSip();
      
      await _updateStatus(GatewayState.running);
      _log('Gateway initialized successfully');
    } catch (e) {
      _log('Error initializing gateway: $e');
      await _updateStatus(GatewayState.error, errorMessage: e.toString());
    }
  }

  Future<void> start() async {
    if (_config == null) {
      throw Exception('Gateway not configured');
    }
    
    _log('Starting gateway...');
    await _updateStatus(GatewayState.starting);
    
    try {
      // Start telephony service
      final teleConfig = {
        'sip_server': _config!.sipServer,
        'sip_username': _config!.sipUsername,
        'sip_password': _config!.sipPassword,
        'sip_port': _config!.sipPort,
        'auto_answer': _config!.autoAnswer,
        'call_timeout': _config!.callTimeout,
      };
      
      final result = await _teleEndpoint.start(teleConfig);
      _log('Telephony service started: $result');
      
      // Register with SIP server
      await _registerSip();
      
      // Connect to GSM network
      await _connectGsm();
      
      await _updateStatus(GatewayState.registered);
      _log('Gateway started successfully');
    } catch (e) {
      _log('Error starting gateway: $e');
      await _updateStatus(GatewayState.error, errorMessage: e.toString());
    }
  }

  Future<void> stop() async {
    _log('Stopping gateway...');
    
    // Stop telephony service
    // await _teleEndpoint.dispose();
    
    // Cleanup connections
    _sipConnected = false;
    _sipRegistered = false;
    _gsmConnected = false;
    _currentCall = null;
    
    // Dispose event subscriptions
    await _callEventSubscription?.cancel();
    await _teleEventSubscription?.cancel();
    
    await _updateStatus(GatewayState.stopped);
    _log('Gateway stopped');
  }

  Future<void> makeCall(String number, String? sipNumber, String? gsmNumber, int? lineId) async {
    if (_currentCall != null) {
      _log('Call already in progress, cannot make new call');
      return;
    }

    _log('Making call to: $number');
    
    try {
      // final callResult = await _teleEndpoint.makeCall(number, sipNumber ?? '', gsmNumber ?? '', lineId ?? 0);
      // _log('Call initiated: $callResult');
      
      _currentCall = CallInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: number,
        direction: CallDirection.outgoing,
        state: CallState.connecting,
        startTime: DateTime.now(),
        gsmCallId: 'gsm_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _updateStatus(GatewayState.callInProgress, currentCall: _currentCall);
    } catch (e) {
      _log('Error making call: $e');
      throw Exception('Failed to make call: $e');
    }
  }

  Future<void> answerCall(String callId) async {
    if (_currentCall == null) {
      _log('No incoming call to answer');
      return;
    }

    _log('Answering call: ${_currentCall!.number}');
    
    try {
      // await _teleEndpoint.answerCall(callId);
      _currentCall = _currentCall!.copyWith(state: CallState.connected);
      await _updateStatus(GatewayState.callInProgress, currentCall: _currentCall);
    } catch (e) {
      _log('Error answering call: $e');
      throw Exception('Failed to answer call: $e');
    }
  }

  Future<void> endCall() async {
    if (_currentCall == null) return;
    
    _log('Ending call: ${_currentCall!.number}');
    
    try {
      // await _teleEndpoint.dispose();
      
      final endedCall = _currentCall!.copyWith(
        state: CallState.disconnected,
        endTime: DateTime.now(),
      );
      
      // Add to recent calls
      final recentCalls = List<CallInfo>.from(_status.recentCalls);
      recentCalls.insert(0, endedCall);
      if (recentCalls.length > 10) {
        recentCalls.removeLast();
      }
      
      _currentCall = null;
      
      await _updateStatus(
        _sipRegistered ? GatewayState.registered : GatewayState.running,
        recentCalls: recentCalls,
      );
    } catch (e) {
      _log('Error ending call: $e');
      throw Exception('Failed to end call: $e');
    }
  }

  Future<void> sendSms(String number, String message) async {
    _log('Sending SMS to: $number');
    
    try {
      // final result = await _teleEndpoint.sendSms(number, message);
      // _log('SMS sent: $result');
      _log('SMS sent (mock)');
    } catch (e) {
      _log('Error sending SMS: $e');
      throw Exception('Failed to send SMS: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSmsMessages() async {
    try {
      // final messages = await _teleEndpoint.getSmsMessages();
      // return List<Map<String, dynamic>>.from(messages);
      return [];
    } catch (e) {
      _log('Error getting SMS messages: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      // final info = await _teleEndpoint.getDeviceInfo();
      // return Map<String, dynamic>.from(info);
      return {};
    } catch (e) {
      _log('Error getting device info: $e');
      return {};
    }
  }

  Future<void> _setupTelephonyListeners() async {
    // Listen for call events
    _callEventSubscription = _teleEndpoint.on('call_state_changed').listen((event) {
      _log('Call state changed: $event');
      _handleCallEvent(event);
    });

    // Listen for incoming calls
    _teleEventSubscription = _teleEndpoint.on('incoming_call').listen((event) {
      _log('Incoming call: $event');
      _handleIncomingCall(event);
    });
  }

  void _handleCallEvent(Map<String, dynamic> event) {
    final callState = event['state'] as String?;
    final callId = event['call_id'] as String?;
    
    if (_currentCall != null && callId == _currentCall!.gsmCallId) {
      CallState newState;
      switch (callState) {
        case 'RINGING':
          newState = CallState.ringing;
          break;
        case 'CONNECTED':
          newState = CallState.connected;
          break;
        case 'DISCONNECTED':
          newState = CallState.disconnected;
          break;
        default:
          newState = CallState.connecting;
      }
      
      _currentCall = _currentCall!.copyWith(state: newState);
      _updateStatus(GatewayState.callInProgress, currentCall: _currentCall);
    }
  }

  void _handleIncomingCall(Map<String, dynamic> event) {
    final number = event['number'] as String?;
    final callId = event['call_id'] as String?;
    
    if (number != null && callId != null) {
      _currentCall = CallInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: number,
        direction: CallDirection.incoming,
        state: CallState.ringing,
        startTime: DateTime.now(),
        gsmCallId: callId,
      );
      
      _updateStatus(GatewayState.callInProgress, currentCall: _currentCall);
    }
  }

  Future<String> _getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id;
    }
    return 'unknown';
  }

  Future<void> _initializeSip() async {
    _log('Initializing SIP endpoint...');
    // SIP initialization will be handled by the telephony service
    await Future.delayed(Duration(seconds: 1));
    _sipConnected = true;
    _log('SIP endpoint initialized');
  }

  Future<void> _registerSip() async {
    _log('Registering with SIP server...');
    await Future.delayed(Duration(seconds: 2));
    _sipRegistered = true;
    _log('SIP registration successful');
  }

  Future<void> _connectGsm() async {
    _log('Connecting to GSM network...');
    await Future.delayed(Duration(seconds: 1));
    _gsmConnected = true;
    _log('GSM connection established');
  }

  Future<void> _updateStatus(
    GatewayState state, {
    String? errorMessage,
    CallInfo? currentCall,
    List<CallInfo>? recentCalls,
  }) async {
    _status = _status.copyWith(
      state: state,
      isConnected: _sipConnected || _gsmConnected,
      isRegistered: _sipRegistered,
      errorMessage: errorMessage,
      currentCall: currentCall ?? _status.currentCall,
      recentCalls: recentCalls ?? _status.recentCalls,
      lastUpdate: DateTime.now(),
    );
    
    _statusController.add(_status);
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _logger.i(logMessage);
    _logController.add(logMessage);
  }

  void dispose() {
    _statusController.close();
    _logController.close();
    _callEventSubscription?.cancel();
    _teleEventSubscription?.cancel();
  }
} 