/// Статус Gateway
/// 
/// Immutable объект, содержащий текущее состояние gateway

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gateway_status.g.dart';

/// Состояние gateway
enum GatewayState {
  stopped,
  starting,
  running,
  stopping,
  error,
  disconnected,
  connecting,
  connected,
}

/// Состояние SIP соединения
enum SipState {
  disconnected,
  connecting,
  connected,
  registered,
  error,
}

/// Состояние GSM соединения
enum GsmState {
  disconnected,
  connecting,
  connected,
  error,
}

/// Состояние SMS
enum SmsState {
  disabled,
  enabled,
  error,
}

/// Состояние USSD
enum UssdState {
  disabled,
  enabled,
  error,
}

@JsonSerializable()
class GatewayStatus extends Equatable {
  final GatewayState state;
  final SipState sipState;
  final GsmState gsmState;
  final SmsState smsState;
  final UssdState ussdState;
  
  final bool isConnected;
  final bool isRegistered;
  final String? errorMessage;
  final DateTime lastUpdate;
  
  // Дополнительная информация
  final String? sipServer;
  final String? sipUsername;
  final int? signalStrength;
  final String? operatorName;
  final String? imei;
  final String? imsi;
  final String? phoneNumber;
  
  // Статистика
  final int totalCalls;
  final int activeCalls;
  final int totalSms;
  final int unreadSms;
  final Duration uptime;

  const GatewayStatus({
    required this.state,
    this.sipState = SipState.disconnected,
    this.gsmState = GsmState.disconnected,
    this.smsState = SmsState.disabled,
    this.ussdState = UssdState.disabled,
    this.isConnected = false,
    this.isRegistered = false,
    this.errorMessage,
    required this.lastUpdate,
    this.sipServer,
    this.sipUsername,
    this.signalStrength,
    this.operatorName,
    this.imei,
    this.imsi,
    this.phoneNumber,
    this.totalCalls = 0,
    this.activeCalls = 0,
    this.totalSms = 0,
    this.unreadSms = 0,
    this.uptime = Duration.zero,
  });

  /// Создает копию с измененными полями
  GatewayStatus copyWith({
    GatewayState? state,
    SipState? sipState,
    GsmState? gsmState,
    SmsState? smsState,
    UssdState? ussdState,
    bool? isConnected,
    bool? isRegistered,
    String? errorMessage,
    DateTime? lastUpdate,
    String? sipServer,
    String? sipUsername,
    int? signalStrength,
    String? operatorName,
    String? imei,
    String? imsi,
    String? phoneNumber,
    int? totalCalls,
    int? activeCalls,
    int? totalSms,
    int? unreadSms,
    Duration? uptime,
  }) {
    return GatewayStatus(
      state: state ?? this.state,
      sipState: sipState ?? this.sipState,
      gsmState: gsmState ?? this.gsmState,
      smsState: smsState ?? this.smsState,
      ussdState: ussdState ?? this.ussdState,
      isConnected: isConnected ?? this.isConnected,
      isRegistered: isRegistered ?? this.isRegistered,
      errorMessage: errorMessage ?? this.errorMessage,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      sipServer: sipServer ?? this.sipServer,
      sipUsername: sipUsername ?? this.sipUsername,
      signalStrength: signalStrength ?? this.signalStrength,
      operatorName: operatorName ?? this.operatorName,
      imei: imei ?? this.imei,
      imsi: imsi ?? this.imsi,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totalCalls: totalCalls ?? this.totalCalls,
      activeCalls: activeCalls ?? this.activeCalls,
      totalSms: totalSms ?? this.totalSms,
      unreadSms: unreadSms ?? this.unreadSms,
      uptime: uptime ?? this.uptime,
    );
  }

  /// Проверяет, работает ли gateway
  bool get isRunning => state == GatewayState.running;

  /// Проверяет, остановлен ли gateway
  bool get isStopped => state == GatewayState.stopped;

  /// Проверяет, есть ли ошибка
  bool get hasError => state == GatewayState.error || errorMessage != null;

  /// Проверяет, подключен ли SIP
  bool get isSipConnected => sipState == SipState.connected || sipState == SipState.registered;

  /// Проверяет, зарегистрирован ли SIP
  bool get isSipRegistered => sipState == SipState.registered;

  /// Проверяет, подключен ли GSM
  bool get isGsmConnected => gsmState == GsmState.connected;

  /// Проверяет, включены ли SMS
  bool get isSmsEnabled => smsState == SmsState.enabled;

  /// Проверяет, включен ли USSD
  bool get isUssdEnabled => ussdState == UssdState.enabled;

  /// Возвращает уровень сигнала в процентах
  int get signalStrengthPercent {
    if (signalStrength == null) return 0;
    return ((signalStrength! / 31) * 100).round().clamp(0, 100);
  }

  /// Возвращает форматированное время работы
  String get formattedUptime {
    final hours = uptime.inHours;
    final minutes = uptime.inMinutes % 60;
    final seconds = uptime.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Создает статус по умолчанию
  factory GatewayStatus.initial() {
    return GatewayStatus(
      state: GatewayState.stopped,
      lastUpdate: DateTime.now(),
    );
  }

  /// Создает статус ошибки
  factory GatewayStatus.error(String message) {
    return GatewayStatus(
      state: GatewayState.error,
      errorMessage: message,
      lastUpdate: DateTime.now(),
    );
  }

  /// Создает из JSON
  factory GatewayStatus.fromJson(Map<String, dynamic> json) => 
      _$GatewayStatusFromJson(json);

  /// Преобразует в JSON
  Map<String, dynamic> toJson() => _$GatewayStatusToJson(this);

  @override
  List<Object?> get props => [
    state,
    sipState,
    gsmState,
    smsState,
    ussdState,
    isConnected,
    isRegistered,
    errorMessage,
    lastUpdate,
    sipServer,
    sipUsername,
    signalStrength,
    operatorName,
    imei,
    imsi,
    phoneNumber,
    totalCalls,
    activeCalls,
    totalSms,
    unreadSms,
    uptime,
  ];

  @override
  String toString() {
    return 'GatewayStatus('
        'state: $state, '
        'sipState: $sipState, '
        'gsmState: $gsmState, '
        'isConnected: $isConnected, '
        'isRegistered: $isRegistered, '
        'activeCalls: $activeCalls, '
        'errorMessage: $errorMessage'
        ')';
  }
}
