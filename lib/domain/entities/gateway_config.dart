/// Конфигурация Gateway
/// 
/// Immutable объект, содержащий все настройки для работы gateway

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'gateway_config.g.dart';

@JsonSerializable()
class GatewayConfig extends Equatable {
  // SIP настройки
  final String sipUsername;
  final String sipPassword;
  final String sipServer;
  final int sipPort;
  final String transport;
  final int registrationTimeout;
  
  // Основные настройки
  final bool autoStart;
  final bool replaceDialer;
  final bool enablePermissions;
  
  // Настройки звонков
  final bool autoAnswer;
  final int callTimeout;
  final String defaultCountryCode;
  final bool enableCallForwarding;
  final String callForwardingNumber;
  final bool enableCallRecording;
  final String recordingPath;
  final int maxCallDuration;
  
  // Настройки SMS
  final bool enableSms;
  final bool enableCallLog;
  
  // Настройки статистики
  final bool enableCallStatistics;
  
  // Настройки безопасности
  final bool enableEmergencyCalls;
  final List<String> emergencyNumbers;
  final bool enableBlacklist;
  final List<String> blacklistedNumbers;
  final bool enableWhitelist;
  final List<String> whitelistedNumbers;

  const GatewayConfig({
    required this.sipUsername,
    required this.sipPassword,
    required this.sipServer,
    this.sipPort = 5060,
    this.transport = 'UDP',
    this.registrationTimeout = 3600,
    this.autoStart = false,
    this.replaceDialer = false,
    this.enablePermissions = false,
    this.autoAnswer = false,
    this.callTimeout = 300,
    this.defaultCountryCode = '+7',
    this.enableCallForwarding = false,
    this.callForwardingNumber = '',
    this.enableCallRecording = false,
    this.recordingPath = '/storage/emulated/0/GSMGateway/recordings',
    this.maxCallDuration = 3600,
    this.enableSms = true,
    this.enableCallLog = true,
    this.enableCallStatistics = true,
    this.enableEmergencyCalls = true,
    this.emergencyNumbers = const ['112', '911', '102', '103', '104'],
    this.enableBlacklist = false,
    this.blacklistedNumbers = const [],
    this.enableWhitelist = false,
    this.whitelistedNumbers = const [],
  });

  /// Создает копию с измененными полями
  GatewayConfig copyWith({
    String? sipUsername,
    String? sipPassword,
    String? sipServer,
    int? sipPort,
    String? transport,
    int? registrationTimeout,
    bool? autoStart,
    bool? replaceDialer,
    bool? enablePermissions,
    bool? autoAnswer,
    int? callTimeout,
    String? defaultCountryCode,
    bool? enableCallForwarding,
    String? callForwardingNumber,
    bool? enableCallRecording,
    String? recordingPath,
    int? maxCallDuration,
    bool? enableSms,
    bool? enableCallLog,
    bool? enableCallStatistics,
    bool? enableEmergencyCalls,
    List<String>? emergencyNumbers,
    bool? enableBlacklist,
    List<String>? blacklistedNumbers,
    bool? enableWhitelist,
    List<String>? whitelistedNumbers,
  }) {
    return GatewayConfig(
      sipUsername: sipUsername ?? this.sipUsername,
      sipPassword: sipPassword ?? this.sipPassword,
      sipServer: sipServer ?? this.sipServer,
      sipPort: sipPort ?? this.sipPort,
      transport: transport ?? this.transport,
      registrationTimeout: registrationTimeout ?? this.registrationTimeout,
      autoStart: autoStart ?? this.autoStart,
      replaceDialer: replaceDialer ?? this.replaceDialer,
      enablePermissions: enablePermissions ?? this.enablePermissions,
      autoAnswer: autoAnswer ?? this.autoAnswer,
      callTimeout: callTimeout ?? this.callTimeout,
      defaultCountryCode: defaultCountryCode ?? this.defaultCountryCode,
      enableCallForwarding: enableCallForwarding ?? this.enableCallForwarding,
      callForwardingNumber: callForwardingNumber ?? this.callForwardingNumber,
      enableCallRecording: enableCallRecording ?? this.enableCallRecording,
      recordingPath: recordingPath ?? this.recordingPath,
      maxCallDuration: maxCallDuration ?? this.maxCallDuration,
      enableSms: enableSms ?? this.enableSms,
      enableCallLog: enableCallLog ?? this.enableCallLog,
      enableCallStatistics: enableCallStatistics ?? this.enableCallStatistics,
      enableEmergencyCalls: enableEmergencyCalls ?? this.enableEmergencyCalls,
      emergencyNumbers: emergencyNumbers ?? this.emergencyNumbers,
      enableBlacklist: enableBlacklist ?? this.enableBlacklist,
      blacklistedNumbers: blacklistedNumbers ?? this.blacklistedNumbers,
      enableWhitelist: enableWhitelist ?? this.enableWhitelist,
      whitelistedNumbers: whitelistedNumbers ?? this.whitelistedNumbers,
    );
  }

  /// Проверяет валидность конфигурации
  bool get isValid {
    return sipUsername.isNotEmpty &&
           sipPassword.isNotEmpty &&
           sipServer.isNotEmpty &&
           sipPort > 0 &&
           sipPort <= 65535 &&
           registrationTimeout > 0 &&
           callTimeout > 0 &&
           maxCallDuration > 0;
  }

  /// Возвращает список ошибок валидации
  List<String> get validationErrors {
    final errors = <String>[];
    
    if (sipUsername.isEmpty) {
      errors.add('SIP username is required');
    }
    
    if (sipPassword.isEmpty) {
      errors.add('SIP password is required');
    }
    
    if (sipServer.isEmpty) {
      errors.add('SIP server is required');
    }
    
    if (sipPort <= 0 || sipPort > 65535) {
      errors.add('SIP port must be between 1 and 65535');
    }
    
    if (registrationTimeout <= 0) {
      errors.add('Registration timeout must be greater than 0');
    }
    
    if (callTimeout <= 0) {
      errors.add('Call timeout must be greater than 0');
    }
    
    if (maxCallDuration <= 0) {
      errors.add('Max call duration must be greater than 0');
    }
    
    if (enableCallForwarding && callForwardingNumber.isEmpty) {
      errors.add('Call forwarding number is required when call forwarding is enabled');
    }
    
    return errors;
  }

  /// Создает конфигурацию по умолчанию
  factory GatewayConfig.defaultConfig() {
    return const GatewayConfig(
      sipUsername: '',
      sipPassword: '',
      sipServer: '192.168.88.254',
      sipPort: 5060,
      transport: 'UDP',
      registrationTimeout: 3600,
      autoStart: false,
      replaceDialer: false,
      enablePermissions: false,
      autoAnswer: false,
      callTimeout: 300,
      defaultCountryCode: '+7',
      enableCallForwarding: false,
      callForwardingNumber: '',
      enableCallRecording: false,
      recordingPath: '/storage/emulated/0/GSMGateway/recordings',
      maxCallDuration: 3600,
      enableSms: true,
      enableCallLog: true,
      enableCallStatistics: true,
      enableEmergencyCalls: true,
      emergencyNumbers: ['112', '911', '102', '103', '104'],
      enableBlacklist: false,
      blacklistedNumbers: [],
      enableWhitelist: false,
      whitelistedNumbers: [],
    );
  }

  /// Создает из JSON
  factory GatewayConfig.fromJson(Map<String, dynamic> json) => 
      _$GatewayConfigFromJson(json);

  /// Преобразует в JSON
  Map<String, dynamic> toJson() => _$GatewayConfigToJson(this);

  @override
  List<Object?> get props => [
    sipUsername,
    sipPassword,
    sipServer,
    sipPort,
    transport,
    registrationTimeout,
    autoStart,
    replaceDialer,
    enablePermissions,
    autoAnswer,
    callTimeout,
    defaultCountryCode,
    enableCallForwarding,
    callForwardingNumber,
    enableCallRecording,
    recordingPath,
    maxCallDuration,
    enableSms,
    enableCallLog,
    enableCallStatistics,
    enableEmergencyCalls,
    emergencyNumbers,
    enableBlacklist,
    blacklistedNumbers,
    enableWhitelist,
    whitelistedNumbers,
  ];

  @override
  String toString() {
    return 'GatewayConfig('
        'sipUsername: $sipUsername, '
        'sipServer: $sipServer, '
        'sipPort: $sipPort, '
        'transport: $transport, '
        'autoStart: $autoStart, '
        'enableSms: $enableSms, '
        'enableCallLog: $enableCallLog'
        ')';
  }
}
