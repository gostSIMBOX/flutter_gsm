/// Модель данных для конфигурации шлюза
/// Используется для сериализации/десериализации данных
import 'dart:convert';
import '../../domain/entities/gateway_config_entity.dart';

/// Модель конфигурации SIP
class SipConfigModel {
  final String server;
  final int port;
  final String username;
  final String password;
  final String transport;
  final int registrationTimeout;
  final bool enableKeepAlive;
  final int keepAliveInterval;

  SipConfigModel({
    required this.server,
    required this.port,
    required this.username,
    required this.password,
    this.transport = 'UDP',
    this.registrationTimeout = 3600,
    this.enableKeepAlive = true,
    this.keepAliveInterval = 30,
  });

  factory SipConfigModel.fromJson(Map<String, dynamic> json) {
    return SipConfigModel(
      server: json['server'] ?? '',
      port: json['port'] ?? 5060,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      transport: json['transport'] ?? 'UDP',
      registrationTimeout: json['registrationTimeout'] ?? 3600,
      enableKeepAlive: json['enableKeepAlive'] ?? true,
      keepAliveInterval: json['keepAliveInterval'] ?? 30,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'port': port,
      'username': username,
      'password': password,
      'transport': transport,
      'registrationTimeout': registrationTimeout,
      'enableKeepAlive': enableKeepAlive,
      'keepAliveInterval': keepAliveInterval,
    };
  }

  factory SipConfigModel.fromEntity(SipConfig entity) {
    return SipConfigModel(
      server: entity.server,
      port: entity.port,
      username: entity.username,
      password: entity.password,
      transport: entity.transport,
      registrationTimeout: entity.registrationTimeout,
      enableKeepAlive: entity.enableKeepAlive,
      keepAliveInterval: entity.keepAliveInterval,
    );
  }

  SipConfig toEntity() {
    return SipConfig(
      server: server,
      port: port,
      username: username,
      password: password,
      transport: transport,
      registrationTimeout: registrationTimeout,
      enableKeepAlive: enableKeepAlive,
      keepAliveInterval: keepAliveInterval,
    );
  }
}

/// Модель конфигурации GSM
class GsmConfigModel {
  final bool enableAutoAnswer;
  final int callTimeout;
  final bool enableCallForwarding;
  final String? forwardNumber;
  final bool enableCallRecording;
  final String recordingPath;
  final List<String> blacklistNumbers;
  final List<String> whitelistNumbers;
  final List<String> emergencyNumbers;

  GsmConfigModel({
    this.enableAutoAnswer = false,
    this.callTimeout = 300,
    this.enableCallForwarding = false,
    this.forwardNumber,
    this.enableCallRecording = false,
    this.recordingPath = '/storage/recordings',
    this.blacklistNumbers = const [],
    this.whitelistNumbers = const [],
    this.emergencyNumbers = const ['112', '911', '999'],
  });

  factory GsmConfigModel.fromJson(Map<String, dynamic> json) {
    return GsmConfigModel(
      enableAutoAnswer: json['enableAutoAnswer'] ?? false,
      callTimeout: json['callTimeout'] ?? 300,
      enableCallForwarding: json['enableCallForwarding'] ?? false,
      forwardNumber: json['forwardNumber'],
      enableCallRecording: json['enableCallRecording'] ?? false,
      recordingPath: json['recordingPath'] ?? '/storage/recordings',
      blacklistNumbers: List<String>.from(json['blacklistNumbers'] ?? []),
      whitelistNumbers: List<String>.from(json['whitelistNumbers'] ?? []),
      emergencyNumbers: List<String>.from(json['emergencyNumbers'] ?? ['112', '911', '999']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableAutoAnswer': enableAutoAnswer,
      'callTimeout': callTimeout,
      'enableCallForwarding': enableCallForwarding,
      'forwardNumber': forwardNumber,
      'enableCallRecording': enableCallRecording,
      'recordingPath': recordingPath,
      'blacklistNumbers': blacklistNumbers,
      'whitelistNumbers': whitelistNumbers,
      'emergencyNumbers': emergencyNumbers,
    };
  }

  factory GsmConfigModel.fromEntity(GsmConfig entity) {
    return GsmConfigModel(
      enableAutoAnswer: entity.enableAutoAnswer,
      callTimeout: entity.callTimeout,
      enableCallForwarding: entity.enableCallForwarding,
      forwardNumber: entity.forwardNumber,
      enableCallRecording: entity.enableCallRecording,
      recordingPath: entity.recordingPath,
      blacklistNumbers: entity.blacklistNumbers,
      whitelistNumbers: entity.whitelistNumbers,
      emergencyNumbers: entity.emergencyNumbers,
    );
  }

  GsmConfig toEntity() {
    return GsmConfig(
      enableAutoAnswer: enableAutoAnswer,
      callTimeout: callTimeout,
      enableCallForwarding: enableCallForwarding,
      forwardNumber: forwardNumber,
      enableCallRecording: enableCallRecording,
      recordingPath: recordingPath,
      blacklistNumbers: blacklistNumbers,
      whitelistNumbers: whitelistNumbers,
      emergencyNumbers: emergencyNumbers,
    );
  }
}

/// Модель конфигурации шлюза
class GatewayConfigModel {
  final String id;
  final String name;
  final SipConfigModel sipConfig;
  final GsmConfigModel gsmConfig;
  final bool enableSms;
  final bool enableCallLog;
  final bool enableStatistics;
  final String logLevel;
  final int maxLogEntries;

  GatewayConfigModel({
    required this.id,
    required this.name,
    required this.sipConfig,
    required this.gsmConfig,
    this.enableSms = true,
    this.enableCallLog = true,
    this.enableStatistics = true,
    this.logLevel = 'INFO',
    this.maxLogEntries = 1000,
  });

  factory GatewayConfigModel.fromJson(Map<String, dynamic> json) {
    return GatewayConfigModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      sipConfig: SipConfigModel.fromJson(json['sipConfig'] ?? {}),
      gsmConfig: GsmConfigModel.fromJson(json['gsmConfig'] ?? {}),
      enableSms: json['enableSms'] ?? true,
      enableCallLog: json['enableCallLog'] ?? true,
      enableStatistics: json['enableStatistics'] ?? true,
      logLevel: json['logLevel'] ?? 'INFO',
      maxLogEntries: json['maxLogEntries'] ?? 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sipConfig': sipConfig.toJson(),
      'gsmConfig': gsmConfig.toJson(),
      'enableSms': enableSms,
      'enableCallLog': enableCallLog,
      'enableStatistics': enableStatistics,
      'logLevel': logLevel,
      'maxLogEntries': maxLogEntries,
    };
  }

  factory GatewayConfigModel.fromEntity(GatewayConfig entity) {
    return GatewayConfigModel(
      id: entity.id,
      name: entity.name,
      sipConfig: SipConfigModel.fromEntity(entity.sipConfig),
      gsmConfig: GsmConfigModel.fromEntity(entity.gsmConfig),
      enableSms: entity.enableSms,
      enableCallLog: entity.enableCallLog,
      enableStatistics: entity.enableStatistics,
      logLevel: entity.logLevel,
      maxLogEntries: entity.maxLogEntries,
    );
  }

  GatewayConfig toEntity() {
    return GatewayConfig(
      id: id,
      name: name,
      sipConfig: sipConfig.toEntity(),
      gsmConfig: gsmConfig.toEntity(),
      enableSms: enableSms,
      enableCallLog: enableCallLog,
      enableStatistics: enableStatistics,
      logLevel: logLevel,
      maxLogEntries: maxLogEntries,
    );
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory GatewayConfigModel.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return GatewayConfigModel.fromJson(json);
  }
}
