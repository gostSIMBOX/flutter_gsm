/// Gateway Configuration entity
/// Immutable domain model for gateway service configuration

import 'package:equatable/equatable.dart';
import 'sip_account.dart';

/// SMPP Configuration for SMS routing
class SmppConfig extends Equatable {
  final String server;
  final int port;
  final String systemId;
  final String password;
  final String? serviceType;
  final String? addressRange;

  const SmppConfig({
    required this.server,
    required this.port,
    required this.systemId,
    required this.password,
    this.serviceType,
    this.addressRange,
  });

  SmppConfig copyWith({
    String? server,
    int? port,
    String? systemId,
    String? password,
    String? serviceType,
    String? addressRange,
  }) {
    return SmppConfig(
      server: server ?? this.server,
      port: port ?? this.port,
      systemId: systemId ?? this.systemId,
      password: password ?? this.password,
      serviceType: serviceType ?? this.serviceType,
      addressRange: addressRange ?? this.addressRange,
    );
  }

  bool get isValid =>
      server.isNotEmpty &&
      port > 0 &&
      port <= 65535 &&
      systemId.isNotEmpty &&
      password.isNotEmpty;

  @override
  List<Object?> get props => [
        server,
        port,
        systemId,
        password,
        serviceType,
        addressRange,
      ];

  @override
  String toString() {
    return 'SmppConfig(server: $server, port: $port, systemId: $systemId)';
  }
}

/// Gateway Configuration entity
///
/// Contains all configuration options for the Gateway Service.
/// This is an immutable domain model.
class GatewayConfig extends Equatable {
  /// SIP account (required)
  final SipAccount sipAccount;

  /// SMPP configuration (optional)
  final SmppConfig? smppConfig;

  /// Auto-answer incoming GSM calls
  final bool autoAnswer;

  /// Enable log streaming
  final bool enableLogging;

  /// Enable SIP→GSM routing
  final bool routeSipToGsm;

  /// Enable GSM→SIP routing
  final bool routeGsmToSip;

  /// Enable SMS→SMPP routing
  final bool routeSmsToSmpp;

  /// Enable SMPP→SMS routing
  final bool routeSmppToSms;

  /// Maximum concurrent calls
  final int maxConcurrentCalls;

  const GatewayConfig({
    required this.sipAccount,
    this.smppConfig,
    this.autoAnswer = false,
    this.enableLogging = true,
    this.routeSipToGsm = true,
    this.routeGsmToSip = true,
    this.routeSmsToSmpp = false,
    this.routeSmppToSms = false,
    this.maxConcurrentCalls = 5,
  });

  /// Create a copy with updated fields
  GatewayConfig copyWith({
    SipAccount? sipAccount,
    SmppConfig? smppConfig,
    bool? autoAnswer,
    bool? enableLogging,
    bool? routeSipToGsm,
    bool? routeGsmToSip,
    bool? routeSmsToSmpp,
    bool? routeSmppToSms,
    int? maxConcurrentCalls,
  }) {
    return GatewayConfig(
      sipAccount: sipAccount ?? this.sipAccount,
      smppConfig: smppConfig ?? this.smppConfig,
      autoAnswer: autoAnswer ?? this.autoAnswer,
      enableLogging: enableLogging ?? this.enableLogging,
      routeSipToGsm: routeSipToGsm ?? this.routeSipToGsm,
      routeGsmToSip: routeGsmToSip ?? this.routeGsmToSip,
      routeSmsToSmpp: routeSmsToSmpp ?? this.routeSmsToSmpp,
      routeSmppToSms: routeSmppToSms ?? this.routeSmppToSms,
      maxConcurrentCalls: maxConcurrentCalls ?? this.maxConcurrentCalls,
    );
  }

  /// Validate configuration
  List<String> get validationErrors {
    final errors = <String>[];

    // SIP account is required
    final sipErrors = sipAccount.validationErrors;
    if (sipErrors.isNotEmpty) {
      errors.addAll(sipErrors.map((e) => 'SIP: $e'));
    }

    // SMPP validation (if configured)
    if (smppConfig != null && !smppConfig!.isValid) {
      errors.add('SMPP: Invalid SMPP configuration');
    }

    // Max concurrent calls validation
    if (maxConcurrentCalls <= 0) {
      errors.add('Max concurrent calls must be greater than 0');
    }

    if (maxConcurrentCalls > 20) {
      errors.add('Max concurrent calls should not exceed 20');
    }

    return errors;
  }

  /// Check if configuration is valid
  bool get isValid => validationErrors.isEmpty;

  /// Check if SMPP is configured
  bool get isSmppConfigured => smppConfig != null && smppConfig!.isValid;

  /// Check if SMS routing is enabled
  bool get isSmsRoutingEnabled => routeSmsToSmpp || routeSmppToSms;

  /// Create default configuration
  factory GatewayConfig.defaultConfig() {
    return GatewayConfig(
      sipAccount: SipAccount.defaultAccount(),
    );
  }

  /// Create from JSON
  factory GatewayConfig.fromJson(Map<String, dynamic> json) {
    return GatewayConfig(
      sipAccount: SipAccount.fromJson(json['sipAccount'] ?? {}),
      smppConfig: json['smppConfig'] != null
          ? SmppConfig.fromJson(json['smppConfig'])
          : null,
      autoAnswer: json['autoAnswer'] ?? false,
      enableLogging: json['enableLogging'] ?? true,
      routeSipToGsm: json['routeSipToGsm'] ?? true,
      routeGsmToSip: json['routeGsmToSip'] ?? true,
      routeSmsToSmpp: json['routeSmsToSmpp'] ?? false,
      routeSmppToSms: json['routeSmppToSms'] ?? false,
      maxConcurrentCalls: json['maxConcurrentCalls'] ?? 5,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sipAccount': sipAccount.toJson(),
      'smppConfig': smppConfig?.toJson(),
      'autoAnswer': autoAnswer,
      'enableLogging': enableLogging,
      'routeSipToGsm': routeSipToGsm,
      'routeGsmToSip': routeGsmToSip,
      'routeSmsToSmpp': routeSmsToSmpp,
      'routeSmppToSms': routeSmppToSms,
      'maxConcurrentCalls': maxConcurrentCalls,
    };
  }

  @override
  List<Object?> get props => [
        sipAccount,
        smppConfig,
        autoAnswer,
        enableLogging,
        routeSipToGsm,
        routeGsmToSip,
        routeSmsToSmpp,
        routeSmppToSms,
        maxConcurrentCalls,
      ];

  @override
  String toString() {
    return 'GatewayConfig(sipAccount: ${sipAccount.username}, '
        'routeSipToGsm: $routeSipToGsm, routeGsmToSip: $routeGsmToSip, '
        'maxConcurrentCalls: $maxConcurrentCalls)';
  }
}

/// Extension for SipAccount JSON serialization
extension SipAccountJsonExtension on SipAccount {
  /// Convert SipAccount to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'domain': domain,
      'port': port,
      'transport': transport.name.toUpperCase(),
      'registrationTimeout': registrationTimeout,
      'enableKeepAlive': enableKeepAlive,
      'keepAliveInterval': keepAliveInterval,
      'displayName': displayName,
      'isDefault': isDefault,
      'isActive': isActive,
    };
  }

  /// Create SipAccount from JSON
  static SipAccount fromJson(Map<String, dynamic> json) {
    return SipAccount(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      domain: json['domain'] ?? '',
      port: json['port'] ?? 5060,
      transport: SipTransport.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['transport'] ?? 'UDP'),
        orElse: () => SipTransport.udp,
      ),
      registrationTimeout: json['registrationTimeout'] ?? 3600,
      enableKeepAlive: json['enableKeepAlive'] ?? true,
      keepAliveInterval: json['keepAliveInterval'] ?? 30,
      displayName: json['displayName'],
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Extension for SmppConfig JSON serialization
extension SmppConfigJsonExtension on SmppConfig {
  /// Convert SmppConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'server': server,
      'port': port,
      'systemId': systemId,
      'password': password,
      'serviceType': serviceType,
      'addressRange': addressRange,
    };
  }

  /// Create SmppConfig from JSON
  static SmppConfig fromJson(Map<String, dynamic> json) {
    return SmppConfig(
      server: json['server'] ?? '',
      port: json['port'] ?? 2775,
      systemId: json['systemId'] ?? '',
      password: json['password'] ?? '',
      serviceType: json['serviceType'],
      addressRange: json['addressRange'],
    );
  }
}
