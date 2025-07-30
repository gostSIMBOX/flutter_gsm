import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/call_statistics.dart';
import '../models/active_call.dart';
import '../models/sms_message.dart';
import '../models/gateway_status.dart';

class StatisticsService {
  static final StatisticsService _instance = StatisticsService._internal();
  factory StatisticsService() => _instance;
  StatisticsService._internal();

  final Logger _logger = Logger();
  
  final StreamController<CallStatistics> _statisticsController = 
      StreamController<CallStatistics>.broadcast();

  Stream<CallStatistics> get statisticsStream => _statisticsController.stream;

  CallStatistics _currentStatistics = CallStatistics.empty();
  List<CallInfo> _allCalls = [];
  List<SmsMessage> _allSms = [];

  Future<void> initialize() async {
    _log('Initializing statistics service');
    
    try {
      // Load historical data
      await loadHistoricalData();
      
      // Calculate initial statistics
      await calculateStatistics();
      
      _log('Statistics service initialized successfully');
    } catch (e) {
      _log('Error initializing statistics service: $e');
      throw Exception('Failed to initialize statistics service: $e');
    }
  }

  Future<void> loadHistoricalData() async {
    // This would load data from local storage or database
    _log('Loading historical data');
    
    // For now, we'll start with empty data
    _allCalls = [];
    _allSms = [];
  }

  Future<void> addCall(CallInfo call) async {
    _allCalls.add(call);
    await calculateStatistics();
    _log('Added call to statistics: ${call.number}');
  }

  Future<void> addSms(SmsMessage sms) async {
    _allSms.add(sms);
    _log('Added SMS to statistics: ${sms.address}');
  }

  Future<void> calculateStatistics() async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1); // Current month
    
    final incomingCalls = _allCalls.where((call) => 
      call.direction == CallDirection.incoming &&
      call.startTime.isAfter(periodStart)
    ).toList();
    
    final outgoingCalls = _allCalls.where((call) => 
      call.direction == CallDirection.outgoing &&
      call.startTime.isAfter(periodStart)
    ).toList();
    
    final answeredCalls = incomingCalls.where((call) => 
      call.state == CallState.connected || call.state == CallState.disconnected
    ).toList();
    
    final missedCalls = incomingCalls.where((call) => 
      call.state == CallState.disconnected && call.endTime != null
    ).toList();
    
    final rejectedCalls = incomingCalls.where((call) => 
      call.state == CallState.disconnected && call.endTime != null
    ).toList();
    
    // Calculate call durations
    Duration totalDuration = Duration.zero;
    final callDurationByNumber = <String, Duration>{};
    
    for (final call in _allCalls.where((call) => 
      call.startTime.isAfter(periodStart) && 
      call.endTime != null
    )) {
      final duration = call.endTime!.difference(call.startTime);
      totalDuration += duration;
      
      final existing = callDurationByNumber[call.number] ?? Duration.zero;
      callDurationByNumber[call.number] = existing + duration;
    }
    
    // Calculate most called number
    final callCountByNumber = <String, int>{};
    for (final call in _allCalls.where((call) => call.startTime.isAfter(periodStart))) {
      callCountByNumber[call.number] = (callCountByNumber[call.number] ?? 0) + 1;
    }
    
    String mostCalledNumber = '';
    int mostCalledCount = 0;
    callCountByNumber.forEach((number, count) {
      if (count > mostCalledCount) {
        mostCalledCount = count;
        mostCalledNumber = number;
      }
    });
    
    // Calculate average call duration
    final completedCalls = _allCalls.where((call) => 
      call.startTime.isAfter(periodStart) && 
      call.endTime != null
    ).length;
    
    final averageDuration = completedCalls > 0 
      ? Duration(milliseconds: totalDuration.inMilliseconds ~/ completedCalls)
      : Duration.zero;
    
    // Find last call time
    final lastCall = _allCalls.isNotEmpty 
      ? _allCalls.reduce((a, b) => a.startTime.isAfter(b.startTime) ? a : b)
      : null;
    
    _currentStatistics = CallStatistics(
      totalCalls: incomingCalls.length + outgoingCalls.length,
      incomingCalls: incomingCalls.length,
      outgoingCalls: outgoingCalls.length,
      missedCalls: missedCalls.length,
      answeredCalls: answeredCalls.length,
      rejectedCalls: rejectedCalls.length,
      totalCallDuration: totalDuration,
      averageCallDuration: averageDuration,
      lastCallTime: lastCall?.startTime ?? now,
      mostCalledNumber: mostCalledNumber,
      mostCalledCount: mostCalledCount,
      callCountByNumber: callCountByNumber,
      callDurationByNumber: callDurationByNumber,
      periodStart: periodStart,
      periodEnd: now,
    );
    
    _statisticsController.add(_currentStatistics);
    _log('Statistics calculated: ${_currentStatistics.totalCalls} total calls');
  }

  Future<CallStatistics> getStatistics() async {
    return _currentStatistics;
  }

  Future<CallStatistics> getStatisticsForPeriod(DateTime start, DateTime end) async {
    final periodCalls = _allCalls.where((call) => 
      call.startTime.isAfter(start) && call.startTime.isBefore(end)
    ).toList();
    
    // Calculate statistics for the specific period
    // This is a simplified version - in a real implementation you'd want more detailed calculations
    return CallStatistics(
      totalCalls: periodCalls.length,
      incomingCalls: periodCalls.where((call) => call.direction == CallDirection.incoming).length,
      outgoingCalls: periodCalls.where((call) => call.direction == CallDirection.outgoing).length,
      missedCalls: 0, // Would need to calculate based on call states
      answeredCalls: 0, // Would need to calculate based on call states
      rejectedCalls: 0, // Would need to calculate based on call states
      totalCallDuration: Duration.zero, // Would need to calculate from call durations
      averageCallDuration: Duration.zero, // Would need to calculate from call durations
      lastCallTime: periodCalls.isNotEmpty 
        ? periodCalls.reduce((a, b) => a.startTime.isAfter(b.startTime) ? a : b).startTime
        : start,
      mostCalledNumber: '',
      mostCalledCount: 0,
      callCountByNumber: {},
      callDurationByNumber: {},
      periodStart: start,
      periodEnd: end,
    );
  }

  Future<Map<String, dynamic>> getSmsStatistics() async {
    final now = DateTime.now();
    final periodStart = DateTime(now.year, now.month, 1);
    
    final periodSms = _allSms.where((sms) => 
      sms.timestamp.isAfter(periodStart)
    ).toList();
    
    final inboxCount = periodSms.where((sms) => sms.type == SmsType.inbox).length;
    final sentCount = periodSms.where((sms) => sms.type == SmsType.sent).length;
    final unreadCount = periodSms.where((sms) => !sms.isRead).length;
    
    // Calculate most contacted numbers
    final contactCounts = <String, int>{};
    for (final sms in periodSms) {
      contactCounts[sms.address] = (contactCounts[sms.address] ?? 0) + 1;
    }
    
    String mostContacted = '';
    int mostContactedCount = 0;
    contactCounts.forEach((number, count) {
      if (count > mostContactedCount) {
        mostContactedCount = count;
        mostContacted = number;
      }
    });
    
    return {
      'totalMessages': periodSms.length,
      'inboxCount': inboxCount,
      'sentCount': sentCount,
      'unreadCount': unreadCount,
      'mostContactedNumber': mostContacted,
      'mostContactedCount': mostContactedCount,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': now.toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> getTopCalledNumbers({int limit = 10}) async {
    final callCounts = <String, int>{};
    for (final call in _allCalls) {
      callCounts[call.number] = (callCounts[call.number] ?? 0) + 1;
    }
    
    final sortedNumbers = callCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedNumbers.take(limit).map((entry) => {
      'number': entry.key,
      'count': entry.value,
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTopSmsContacts({int limit = 10}) async {
    final contactCounts = <String, int>{};
    for (final sms in _allSms) {
      contactCounts[sms.address] = (contactCounts[sms.address] ?? 0) + 1;
    }
    
    final sortedContacts = contactCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedContacts.take(limit).map((entry) => {
      'number': entry.key,
      'count': entry.value,
    }).toList();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] Statistics Service: $message';
    _logger.i(logMessage);
  }

  void dispose() {
    _statisticsController.close();
  }
} 