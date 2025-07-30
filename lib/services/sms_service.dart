import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:flutter_tele/flutter_tele.dart';
import '../models/sms_message.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Logger _logger = Logger();
  final TeleEndpoint _teleEndpoint = TeleEndpoint();
  
  final StreamController<List<SmsMessage>> _messagesController = 
      StreamController<List<SmsMessage>>.broadcast();
  final StreamController<SmsMessage> _newMessageController = 
      StreamController<SmsMessage>.broadcast();

  Stream<List<SmsMessage>> get messagesStream => _messagesController.stream;
  Stream<SmsMessage> get newMessageStream => _newMessageController.stream;

  List<SmsMessage> _messages = [];
  StreamSubscription? _smsEventSubscription;

  Future<void> initialize() async {
    _log('Initializing SMS service');
    
    try {
      // Setup SMS event listeners
      await _setupSmsListeners();
      
      // Load existing messages
      await loadMessages();
      
      _log('SMS service initialized successfully');
    } catch (e) {
      _log('Error initializing SMS service: $e');
      throw Exception('Failed to initialize SMS service: $e');
    }
  }

  Future<void> loadMessages() async {
    try {
      final rawMessages = await _teleEndpoint.getSmsMessages();
      _messages = rawMessages.map((json) => SmsMessage.fromJson(json)).toList();
      _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _messagesController.add(_messages);
      _log('Loaded ${_messages.length} SMS messages');
    } catch (e) {
      _log('Error loading SMS messages: $e');
    }
  }

  Future<bool> sendSms(String number, String message) async {
    _log('Sending SMS to: $number');
    
    try {
      final result = await _teleEndpoint.sendSms(number, message);
      _log('SMS sent successfully: $result');
      
      // Add to messages list
      final newMessage = SmsMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        address: number,
        body: message,
        timestamp: DateTime.now(),
        type: SmsType.sent,
        status: SmsStatus.sent,
      );
      
      _messages.insert(0, newMessage);
      _messagesController.add(_messages);
      _newMessageController.add(newMessage);
      
      return true;
    } catch (e) {
      _log('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> deleteSms(String messageId) async {
    try {
      final result = await _teleEndpoint.deleteSms(messageId);
      _log('SMS deleted: $result');
      
      _messages.removeWhere((msg) => msg.id == messageId);
      _messagesController.add(_messages);
      
      return true;
    } catch (e) {
      _log('Error deleting SMS: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    try {
      final result = await _teleEndpoint.markSmsAsRead(messageId);
      _log('SMS marked as read: $result');
      
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(isRead: true);
        _messagesController.add(_messages);
      }
      
      return true;
    } catch (e) {
      _log('Error marking SMS as read: $e');
      return false;
    }
  }

  Future<List<SmsMessage>> getMessagesByType(SmsType type) async {
    return _messages.where((msg) => msg.type == type).toList();
  }

  Future<List<SmsMessage>> getMessagesByNumber(String number) async {
    return _messages.where((msg) => msg.address == number).toList();
  }

  Future<List<SmsMessage>> searchMessages(String query) async {
    return _messages.where((msg) => 
      msg.address.toLowerCase().contains(query.toLowerCase()) ||
      msg.body.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<Map<String, int>> getMessageCounts() async {
    final counts = <String, int>{};
    for (final type in SmsType.values) {
      counts[type.name] = _messages.where((msg) => msg.type == type).length;
    }
    return counts;
  }

  Future<void> _setupSmsListeners() async {
    _smsEventSubscription = _teleEndpoint.on('sms_received').listen((event) {
      _log('SMS received: $event');
      _handleNewSms(event);
    });
  }

  void _handleNewSms(Map<String, dynamic> event) {
    try {
      final newMessage = SmsMessage.fromJson(event);
      _messages.insert(0, newMessage);
      _messagesController.add(_messages);
      _newMessageController.add(newMessage);
      _log('New SMS added: ${newMessage.address}');
    } catch (e) {
      _log('Error handling new SMS: $e');
    }
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] SMS Service: $message';
    _logger.i(logMessage);
  }

  void dispose() {
    _messagesController.close();
    _newMessageController.close();
    _smsEventSubscription?.cancel();
  }
} 