import 'dart:async';
import 'package:flutter_tele/flutter_tele.dart';
import '../models/sms_message.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

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
    try {
      // Setup SMS event listeners
      _smsEventSubscription = _teleEndpoint.on('sms_received').listen((event) {
        _handleNewSms(event);
      });

      // Load existing messages
      await loadMessages();
    } catch (e) {
      print('Error initializing SMS service: $e');
    }
  }

  Future<void> loadMessages() async {
    try {
      final rawMessages = await _teleEndpoint.getSmsMessages();
      _messages = rawMessages.map((msg) => SmsMessage.fromJson(msg)).toList();
      _messagesController.add(_messages);
    } catch (e) {
      print('Error loading SMS messages: $e');
    }
  }

  Future<bool> sendSms(String number, String message) async {
    try {
      final result = await _teleEndpoint.sendSms(number, message);
      return result['success'] == true;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> deleteSms(String messageId) async {
    try {
      final result = await _teleEndpoint.deleteSms(messageId);
      return result['success'] == true;
    } catch (e) {
      print('Error deleting SMS: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    try {
      final result = await _teleEndpoint.markSmsAsRead(messageId);
      return result['success'] == true;
    } catch (e) {
      print('Error marking SMS as read: $e');
      return false;
    }
  }

  Future<List<SmsMessage>> getMessagesByType(SmsType type) async {
    return _messages.where((msg) => msg.type == type).toList();
  }

  Future<List<SmsMessage>> getMessagesByNumber(String number) async {
    return _messages.where((msg) => msg.number == number).toList();
  }

  Future<List<SmsMessage>> searchMessages(String query) async {
    return _messages.where((msg) => 
      msg.number.contains(query) || 
      msg.message.contains(query)
    ).toList();
  }

  Future<Map<String, int>> getMessageCounts() async {
    final counts = <String, int>{};
    for (final msg in _messages) {
      counts[msg.type.name] = (counts[msg.type.name] ?? 0) + 1;
    }
    return counts;
  }

  void _handleNewSms(Map<String, dynamic> event) {
    try {
      final smsMessage = SmsMessage.fromJson(event);
      _messages.insert(0, smsMessage);
      _messagesController.add(_messages);
      _newMessageController.add(smsMessage);
    } catch (e) {
      print('Error handling new SMS: $e');
    }
  }

  void dispose() {
    _messagesController.close();
    _newMessageController.close();
    _smsEventSubscription?.cancel();
  }
} 