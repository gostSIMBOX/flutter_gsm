import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';

/// SMS Message model
class SmsMessage {
  final String id;
  final String sender;
  final String recipient;
  final String content;
  final DateTime timestamp;
  final SmsMessageType type;
  final SmsMessageStatus status;

  const SmsMessage({
    required this.id,
    required this.sender,
    required this.recipient,
    required this.content,
    required this.timestamp,
    required this.type,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'sender': sender,
    'recipient': recipient,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'type': type.name,
    'status': status.name,
  };

  factory SmsMessage.fromJson(Map<String, dynamic> json) => SmsMessage(
    id: json['id'],
    sender: json['sender'],
    recipient: json['recipient'],
    content: json['content'],
    timestamp: DateTime.parse(json['timestamp']),
    type: SmsMessageType.values.firstWhere((e) => e.name == json['type']),
    status: SmsMessageStatus.values.firstWhere((e) => e.name == json['status']),
  );
}

enum SmsMessageType { incoming, outgoing }
enum SmsMessageStatus { pending, sent, delivered, failed, received }

/// SMPP Configuration
class SmppConfig {
  final String host;
  final int port;
  final String systemId;
  final String password;
  final String systemType;
  final String sourceAddrTon;
  final String sourceAddrNpi;
  final String addressRange;

  const SmppConfig({
    required this.host,
    required this.port,
    required this.systemId,
    required this.password,
    this.systemType = '',
    this.sourceAddrTon = '0',
    this.sourceAddrNpi = '0',
    this.addressRange = '',
  });

  Map<String, dynamic> toJson() => {
    'host': host,
    'port': port,
    'systemId': systemId,
    'password': password,
    'systemType': systemType,
    'sourceAddrTon': sourceAddrTon,
    'sourceAddrNpi': sourceAddrNpi,
    'addressRange': addressRange,
  };

  factory SmppConfig.fromJson(Map<String, dynamic> json) => SmppConfig(
    host: json['host'],
    port: json['port'],
    systemId: json['systemId'],
    password: json['password'],
    systemType: json['systemType'] ?? '',
    sourceAddrTon: json['sourceAddrTon'] ?? '0',
    sourceAddrNpi: json['sourceAddrNpi'] ?? '0',
    addressRange: json['addressRange'] ?? '',
  );
}

enum SmppConnectionState { 
  disconnected, 
  connecting, 
  bound, 
  error 
}

/// SMS Service for handling SMS via SMPP and local SMS
class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Logger _logger = Logger();
  
  SmppConfig? _smppConfig;
  SmppConnectionState _smppConnectionState = SmppConnectionState.disconnected;
  final Map<String, SmsMessage> _messages = {};
  int _messageCounter = 0;
  
  // Stream controllers
  final StreamController<SmppConnectionState> _connectionStateController = 
      StreamController<SmppConnectionState>.broadcast();
  final StreamController<SmsMessage> _messageController = 
      StreamController<SmsMessage>.broadcast();
  final StreamController<String> _logController = 
      StreamController<String>.broadcast();

  // Getters
  SmppConnectionState get connectionState => _smppConnectionState;
  SmppConfig? get smppConfig => _smppConfig;
  List<SmsMessage> get messages => _messages.values.toList();

  // Streams
  Stream<SmppConnectionState> get connectionStateStream => 
      _connectionStateController.stream;
  Stream<SmsMessage> get messageStream => _messageController.stream;
  Stream<String> get logStream => _logController.stream;

  /// Initialize SMS service with SMPP configuration
  Future<bool> initializeSmpp(SmppConfig config) async {
    try {
      _smppConfig = config;
      _log('Initializing SMPP connection to ${config.host}:${config.port}');
      
      _updateConnectionState(SmppConnectionState.connecting);
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate SMPP bind operation
      _updateConnectionState(SmppConnectionState.bound);
      _log('SMPP connection established and bound');
      return true;
    } catch (e) {
      _log('Failed to initialize SMPP: $e');
      _updateConnectionState(SmppConnectionState.error);
      return false;
    }
  }

  /// Connect to SMPP server
  Future<bool> connectSmpp() async {
    if (_smppConfig == null) {
      _log('No SMPP configuration available');
      return false;
    }

    try {
      _log('Connecting to SMPP server...');
      _updateConnectionState(SmppConnectionState.connecting);
      
      // Simulate connection process
      await Future.delayed(const Duration(seconds: 1));
      
      _updateConnectionState(SmppConnectionState.bound);
      _log('Successfully connected to SMPP server');
      return true;
    } catch (e) {
      _log('SMPP connection failed: $e');
      _updateConnectionState(SmppConnectionState.error);
      return false;
    }
  }

  /// Disconnect from SMPP server
  Future<void> disconnectSmpp() async {
    try {
      _log('Disconnecting from SMPP server...');
      _updateConnectionState(SmppConnectionState.disconnected);
      _log('Disconnected from SMPP server');
    } catch (e) {
      _log('SMPP disconnection failed: $e');
    }
  }

  /// Send SMS via SMPP
  Future<String?> sendSmsViaSmpp(String recipient, String content) async {
    if (_smppConnectionState != SmppConnectionState.bound) {
      _log('Cannot send SMS: SMPP not connected');
      return null;
    }

    try {
      final messageId = 'smpp_${++_messageCounter}_${DateTime.now().millisecondsSinceEpoch}';
      _log('Sending SMS via SMPP to $recipient (ID: $messageId)');
      
      final message = SmsMessage(
        id: messageId,
        sender: _smppConfig?.systemId ?? 'SMPP',
        recipient: recipient,
        content: content,
        timestamp: DateTime.now(),
        type: SmsMessageType.outgoing,
        status: SmsMessageStatus.pending,
      );
      
      _messages[messageId] = message;
      _messageController.add(message);
      
      // Simulate message delivery
      _simulateMessageDelivery(messageId);
      
      return messageId;
    } catch (e) {
      _log('Failed to send SMS via SMPP: $e');
      return null;
    }
  }

  /// Send SMS via local Android SMS
  Future<String?> sendSmsLocal(String recipient, String content) async {
    try {
      final messageId = 'local_${++_messageCounter}_${DateTime.now().millisecondsSinceEpoch}';
      _log('Sending SMS locally to $recipient (ID: $messageId)');
      
      final message = SmsMessage(
        id: messageId,
        sender: 'Local',
        recipient: recipient,
        content: content,
        timestamp: DateTime.now(),
        type: SmsMessageType.outgoing,
        status: SmsMessageStatus.pending,
      );
      
      _messages[messageId] = message;
      _messageController.add(message);
      
      // Simulate local SMS sending
      Timer(const Duration(seconds: 1), () {
        _updateMessageStatus(messageId, SmsMessageStatus.sent);
        Timer(const Duration(seconds: 2), () {
          _updateMessageStatus(messageId, SmsMessageStatus.delivered);
        });
      });
      
      return messageId;
    } catch (e) {
      _log('Failed to send local SMS: $e');
      return null;
    }
  }

  /// Receive SMS (simulate incoming SMS)
  void simulateIncomingSms(String sender, String content) {
    final messageId = 'incoming_${++_messageCounter}_${DateTime.now().millisecondsSinceEpoch}';
    _log('Received SMS from $sender (ID: $messageId)');
    
    final message = SmsMessage(
      id: messageId,
      sender: sender,
      recipient: 'Local',
      content: content,
      timestamp: DateTime.now(),
      type: SmsMessageType.incoming,
      status: SmsMessageStatus.received,
    );
    
    _messages[messageId] = message;
    _messageController.add(message);
  }

  /// Get message history
  List<SmsMessage> getMessageHistory({
    String? sender,
    String? recipient,
    SmsMessageType? type,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return _messages.values.where((message) {
      if (sender != null && message.sender != sender) return false;
      if (recipient != null && message.recipient != recipient) return false;
      if (type != null && message.type != type) return false;
      if (fromDate != null && message.timestamp.isBefore(fromDate)) return false;
      if (toDate != null && message.timestamp.isAfter(toDate)) return false;
      return true;
    }).toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get message by ID
  SmsMessage? getMessage(String messageId) {
    return _messages[messageId];
  }

  /// Delete message
  bool deleteMessage(String messageId) {
    return _messages.remove(messageId) != null;
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _log('Cleared all messages');
  }

  /// Get message statistics
  Map<String, int> getMessageStats() {
    final stats = <String, int>{
      'total': _messages.length,
      'incoming': 0,
      'outgoing': 0,
      'sent': 0,
      'delivered': 0,
      'failed': 0,
    };

    for (final message in _messages.values) {
      stats[message.type.name] = (stats[message.type.name] ?? 0) + 1;
      stats[message.status.name] = (stats[message.status.name] ?? 0) + 1;
    }

    return stats;
  }

  /// Simulate message delivery for SMPP messages
  void _simulateMessageDelivery(String messageId) {
    Timer(const Duration(seconds: 1), () {
      _updateMessageStatus(messageId, SmsMessageStatus.sent);
      
      Timer(const Duration(seconds: 3), () {
        // 95% delivery success rate
        final delivered = DateTime.now().millisecond % 100 < 95;
        _updateMessageStatus(
          messageId, 
          delivered ? SmsMessageStatus.delivered : SmsMessageStatus.failed
        );
      });
    });
  }

  /// Update message status
  void _updateMessageStatus(String messageId, SmsMessageStatus status) {
    final message = _messages[messageId];
    if (message != null) {
      final updatedMessage = SmsMessage(
        id: message.id,
        sender: message.sender,
        recipient: message.recipient,
        content: message.content,
        timestamp: message.timestamp,
        type: message.type,
        status: status,
      );
      
      _messages[messageId] = updatedMessage;
      _messageController.add(updatedMessage);
      _log('Message $messageId status updated to ${status.name}');
    }
  }

  void _updateConnectionState(SmppConnectionState state) {
    _smppConnectionState = state;
    _connectionStateController.add(state);
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] SMS: $message';
    _logger.i(logMessage);
    _logController.add(logMessage);
  }

  /// Clean up resources
  void dispose() {
        _connectionStateController.close();
    _messageController.close();
    _logController.close();
  }
}