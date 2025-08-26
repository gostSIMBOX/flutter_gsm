import 'dart:async';
import 'package:flutter_smsussd/flutter_smsussd.dart';
import '../models/sms_message.dart';

class SmsService {
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final FlutterSmsussd _smsussd = FlutterSmsussd();
  final StreamController<List<SmsMessage>> _messagesController = 
      StreamController<List<SmsMessage>>.broadcast();
  final StreamController<SmsMessage> _newMessageController = 
      StreamController<SmsMessage>.broadcast();

  Stream<List<SmsMessage>> get messagesStream => _messagesController.stream;
  Stream<SmsMessage> get newMessageStream => _newMessageController.stream;

  List<SmsMessage> _messages = [];
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      // Check and request SMS permissions
      final hasPermissions = await _smsussd.hasSmsPermissions();
      if (!hasPermissions) {
        final granted = await _smsussd.requestSmsPermissions();
        if (!granted) {
          throw Exception('SMS permissions not granted');
        }
      }

      // Load existing messages
      await loadMessages();
      
      _isInitialized = true;
      print('SMS service initialized successfully');
    } catch (e) {
      print('Error initializing SMS service: $e');
      rethrow;
    }
  }

  Future<void> loadMessages() async {
    try {
      final rawMessages = await _smsussd.getSmsMessages();
      _messages = rawMessages.map((msg) => SmsMessage.fromSmsussd(msg)).toList();
      _messagesController.add(_messages);
    } catch (e) {
      print('Error loading SMS messages: $e');
      rethrow;
    }
  }

  Future<bool> sendSms(String number, String message) async {
    try {
      if (!_isInitialized) {
        throw Exception('SMS service not initialized');
      }

      final result = await _smsussd.sendSms(
        phoneNumber: number,
        message: message,
      );

      if (result) {
        // Create a new SMS message for the sent message
        final sentMessage = SmsMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          address: number,
          body: message,
          timestamp: DateTime.now(),
          type: SmsType.sent,
          status: SmsStatus.sent,
        );

        _messages.insert(0, sentMessage);
        _messagesController.add(_messages);
        _newMessageController.add(sentMessage);
      }

      return result;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  Future<bool> deleteSms(String messageId) async {
    try {
      // Note: flutter_smsussd doesn't have delete functionality yet
      // This is a placeholder for future implementation
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        _messages.removeAt(index);
        _messagesController.add(_messages);
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting SMS: $e');
      return false;
    }
  }

  Future<bool> markAsRead(String messageId) async {
    try {
      final index = _messages.indexWhere((msg) => msg.id == messageId);
      if (index != -1) {
        final message = _messages[index];
        final updatedMessage = message.copyWith(isRead: true);
        _messages[index] = updatedMessage;
        _messagesController.add(_messages);
        return true;
      }
      return false;
    } catch (e) {
      print('Error marking SMS as read: $e');
      return false;
    }
  }

  Future<List<SmsMessage>> getMessagesByType(SmsType type) async {
    return _messages.where((msg) => msg.type == type).toList();
  }

  Future<List<SmsMessage>> getMessagesByNumber(String number) async {
    try {
      final rawMessages = await _smsussd.getSmsMessagesByPhoneNumber(number);
      return rawMessages.map((msg) => SmsMessage.fromSmsussd(msg)).toList();
    } catch (e) {
      print('Error getting messages by number: $e');
      return _messages.where((msg) => msg.address == number).toList();
    }
  }

  Future<List<SmsMessage>> searchMessages(String query) async {
    return _messages.where((msg) => 
      msg.address.toLowerCase().contains(query.toLowerCase()) || 
      msg.body.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  Future<Map<String, int>> getMessageCounts() async {
    final counts = <String, int>{};
    for (final msg in _messages) {
      counts[msg.type.name] = (counts[msg.type.name] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> refreshMessages() async {
    await loadMessages();
  }

  Future<bool> hasPermissions() async {
    return await _smsussd.hasSmsPermissions();
  }

  Future<bool> requestPermissions() async {
    return await _smsussd.requestSmsPermissions();
  }

  void dispose() {
    _messagesController.close();
    _newMessageController.close();
  }
} 