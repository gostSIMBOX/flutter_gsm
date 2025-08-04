import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../models/gateway_config.dart';
import '../models/gateway_status.dart';
import '../models/sms_message.dart';
import '../services/gateway_service.dart';
import '../services/sms_service.dart';
import '../services/statistics_service.dart';
import '../services/storage_service.dart';

class GatewayProvider extends ChangeNotifier {
  final GatewayService _gatewayService = GatewayService();
  final SmsService _smsService = SmsService();
  final StatisticsService _statisticsService = StatisticsService();
  final StorageService _storageService = StorageService();
  final Logger _logger = Logger();

  GatewayStatus _status = GatewayStatus(
    state: GatewayState.stopped,
    isConnected: false,
    isRegistered: false,
    lastUpdate: DateTime.now(),
  );

  GatewayConfig? _config;
  List<String> _logs = [];
  List<SmsMessage> _smsMessages = [];
  bool _isInitialized = false;

  GatewayStatus get status => _status;
  GatewayConfig? get config => _config;
  List<String> get logs => _logs;
  List<SmsMessage> get smsMessages => _smsMessages;
  bool get isInitialized => _isInitialized;

  StreamSubscription<GatewayStatus>? _statusSubscription;
  StreamSubscription<String>? _logSubscription;
  StreamSubscription<List<SmsMessage>>? _smsSubscription;
  StreamSubscription<SmsMessage>? _newSmsSubscription;

  GatewayProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Load configuration
      _config = await _storageService.getConfig();
      
      // Initialize services
      await _smsService.initialize();
      await _statisticsService.initialize();
      
      // Subscribe to status updates
      _statusSubscription = _gatewayService.statusStream.listen((status) {
        _status = status;
        notifyListeners();
      });

      // Subscribe to log updates
      _logSubscription = _gatewayService.logStream.listen((log) {
        _logs.add(log);
        if (_logs.length > 100) {
          _logs.removeAt(0);
        }
        _storageService.addLog(log);
        notifyListeners();
      });

      // Subscribe to SMS updates
      _smsSubscription = _smsService.messagesStream.listen((messages) {
        _smsMessages = messages;
        notifyListeners();
      });

      // Subscribe to new SMS
      _newSmsSubscription = _smsService.newMessageStream.listen((message) {
        _statisticsService.addSms(message);
        notifyListeners();
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _logger.e('Error initializing gateway provider: $e');
    }
  }

  Future<void> updateConfig(GatewayConfig config) async {
    _config = config;
    await _storageService.saveConfig(config);
    notifyListeners();
  }

  Future<void> startGateway() async {
    if (_config == null) {
      throw Exception('Gateway not configured');
    }

    try {
      await _gatewayService.initialize(_config!);
      await _gatewayService.start();
    } catch (e) {
      _logger.e('Error starting gateway: $e');
      rethrow;
    }
  }

  Future<void> stopGateway() async {
    try {
      await _gatewayService.stop();
    } catch (e) {
      _logger.e('Error stopping gateway: $e');
      rethrow;
    }
  }

  Future<void> makeCall(String number) async {
    try {
      await _gatewayService.makeCall(number, null, null, null);
    } catch (e) {
      _logger.e('Error making call: $e');
      rethrow;
    }
  }

  Future<void> answerCall() async {
    try {
      await _gatewayService.answerCall('current_call');
    } catch (e) {
      _logger.e('Error answering call: $e');
      rethrow;
    }
  }

  Future<void> endCall() async {
    try {
      await _gatewayService.endCall();
    } catch (e) {
      _logger.e('Error ending call: $e');
      rethrow;
    }
  }

  Future<bool> sendSms(String number, String message) async {
    try {
      final result = await _smsService.sendSms(number, message);
      return result;
    } catch (e) {
      _logger.e('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> deleteSms(String messageId) async {
    try {
      final result = await _smsService.deleteSms(messageId);
      return result;
    } catch (e) {
      _logger.e('Error deleting SMS: $e');
      return false;
    }
  }

  Future<bool> markSmsAsRead(String messageId) async {
    try {
      final result = await _smsService.markAsRead(messageId);
      return result;
    } catch (e) {
      _logger.e('Error marking SMS as read: $e');
      return false;
    }
  }

  Future<List<SmsMessage>> getMessagesByType(SmsType type) async {
    return await _smsService.getMessagesByType(type);
  }

  Future<List<SmsMessage>> getMessagesByNumber(String number) async {
    return await _smsService.getMessagesByNumber(number);
  }

  Future<List<SmsMessage>> searchMessages(String query) async {
    return await _smsService.searchMessages(query);
  }

  Future<Map<String, int>> getMessageCounts() async {
    return await _smsService.getMessageCounts();
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    return await _gatewayService.getDeviceInfo();
  }

  Future<void> addCallToStatistics(Map<String, dynamic> callInfo) async {
    _statisticsService.addCall(callInfo);
  }

  Future<Map<String, dynamic>> getSmsStatistics() async {
    return _statisticsService.getSmsStatistics();
  }

  Future<List<Map<String, dynamic>>> getTopCalledNumbers({int limit = 10}) async {
    return _statisticsService.getTopCalledNumbers(limit: limit);
  }

  Future<List<Map<String, dynamic>>> getTopSmsContacts({int limit = 10}) async {
    return _statisticsService.getTopSmsContacts(limit: limit);
  }

  Future<void> clearLogs() async {
    _logs.clear();
    await _storageService.clearLogs();
    notifyListeners();
  }

  Future<List<String>> loadStoredLogs() async {
    return await _storageService.loadLogs();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _logSubscription?.cancel();
    _smsSubscription?.cancel();
    _newSmsSubscription?.cancel();
    _gatewayService.dispose();
    _smsService.dispose();
    _statisticsService.dispose();
    super.dispose();
  }
} 