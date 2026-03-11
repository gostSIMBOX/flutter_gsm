/// Доменная сущность конфигурации шлюза
/// Представляет настройки шлюза в бизнес-логике
import 'package:equatable/equatable.dart';
import 'voice_line_config.dart';

/// Конфигурация SIP
class SipConfig extends Equatable {
  final String server;
  final int port;
  final String username;
  final String password;
  final String transport; // UDP/TCP/TLS
  final int registrationTimeout;
  final bool enableKeepAlive;
  final int keepAliveInterval;

  const SipConfig({
    required this.server,
    required this.port,
    required this.username,
    required this.password,
    this.transport = 'UDP',
    this.registrationTimeout = 3600,
    this.enableKeepAlive = true,
    this.keepAliveInterval = 30,
  });

  SipConfig copyWith({
    String? server,
    int? port,
    String? username,
    String? password,
    String? transport,
    int? registrationTimeout,
    bool? enableKeepAlive,
    int? keepAliveInterval,
  }) {
    return SipConfig(
      server: server ?? this.server,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      transport: transport ?? this.transport,
      registrationTimeout: registrationTimeout ?? this.registrationTimeout,
      enableKeepAlive: enableKeepAlive ?? this.enableKeepAlive,
      keepAliveInterval: keepAliveInterval ?? this.keepAliveInterval,
    );
  }

  @override
  List<Object?> get props => [
        server,
        port,
        username,
        password,
        transport,
        registrationTimeout,
        enableKeepAlive,
        keepAliveInterval,
      ];
}

/// Конфигурация GSM
class GsmConfig extends Equatable {
  final bool enableAutoAnswer;
  final int callTimeout;
  final bool enableCallForwarding;
  final String? forwardNumber;
  final bool enableCallRecording;
  final String recordingPath;
  final List<String> blacklistNumbers;
  final List<String> whitelistNumbers;
  final List<String> emergencyNumbers;

  const GsmConfig({
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

  GsmConfig copyWith({
    bool? enableAutoAnswer,
    int? callTimeout,
    bool? enableCallForwarding,
    String? forwardNumber,
    bool? enableCallRecording,
    String? recordingPath,
    List<String>? blacklistNumbers,
    List<String>? whitelistNumbers,
    List<String>? emergencyNumbers,
  }) {
    return GsmConfig(
      enableAutoAnswer: enableAutoAnswer ?? this.enableAutoAnswer,
      callTimeout: callTimeout ?? this.callTimeout,
      enableCallForwarding: enableCallForwarding ?? this.enableCallForwarding,
      forwardNumber: forwardNumber ?? this.forwardNumber,
      enableCallRecording: enableCallRecording ?? this.enableCallRecording,
      recordingPath: recordingPath ?? this.recordingPath,
      blacklistNumbers: blacklistNumbers ?? this.blacklistNumbers,
      whitelistNumbers: whitelistNumbers ?? this.whitelistNumbers,
      emergencyNumbers: emergencyNumbers ?? this.emergencyNumbers,
    );
  }

  @override
  List<Object?> get props => [
        enableAutoAnswer,
        callTimeout,
        enableCallForwarding,
        forwardNumber,
        enableCallRecording,
        recordingPath,
        blacklistNumbers,
        whitelistNumbers,
        emergencyNumbers,
      ];
}

/// Основная конфигурация шлюза
class GatewayConfig extends Equatable {
  final String id;
  final String name;
  final SipConfig sipConfig;
  final GsmConfig gsmConfig;
  final VoiceLineConfig voiceLineConfig;
  final bool enableSms;
  final bool enableCallLog;
  final bool enableStatistics;
  final String logLevel;
  final int maxLogEntries;

  const GatewayConfig({
    required this.id,
    required this.name,
    required this.sipConfig,
    required this.gsmConfig,
    this.voiceLineConfig = const VoiceLineConfig(),
    this.enableSms = true,
    this.enableCallLog = true,
    this.enableStatistics = true,
    this.logLevel = 'INFO',
    this.maxLogEntries = 1000,
  });

  GatewayConfig copyWith({
    String? id,
    String? name,
    SipConfig? sipConfig,
    GsmConfig? gsmConfig,
    VoiceLineConfig? voiceLineConfig,
    bool? enableSms,
    bool? enableCallLog,
    bool? enableStatistics,
    String? logLevel,
    int? maxLogEntries,
  }) {
    return GatewayConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      sipConfig: sipConfig ?? this.sipConfig,
      gsmConfig: gsmConfig ?? this.gsmConfig,
      voiceLineConfig: voiceLineConfig ?? this.voiceLineConfig,
      enableSms: enableSms ?? this.enableSms,
      enableCallLog: enableCallLog ?? this.enableCallLog,
      enableStatistics: enableStatistics ?? this.enableStatistics,
      logLevel: logLevel ?? this.logLevel,
      maxLogEntries: maxLogEntries ?? this.maxLogEntries,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sipConfig,
        gsmConfig,
        voiceLineConfig,
        enableSms,
        enableCallLog,
        enableStatistics,
        logLevel,
        maxLogEntries,
      ];
}
