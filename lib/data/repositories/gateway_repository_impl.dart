/// Реализация репозитория шлюза
/// Связывает доменный слой с источниками данных
import 'dart:async';
import '../../domain/entities/gateway_entity.dart';
import '../../domain/entities/gateway_config_entity.dart';
import '../../domain/repositories/gateway_repository.dart';
import '../../domain/exceptions/gateway_exceptions.dart';
import '../datasources/local_storage_datasource.dart';
import '../models/gateway_config_model.dart';
import '../services/gateway_service.dart';

class GatewayRepositoryImpl implements GatewayRepository {
  final LocalStorageDataSource _localStorage;
  final GatewayService _gatewayService;

  GatewayRepositoryImpl(this._localStorage, this._gatewayService);

  @override
  Future<GatewayStatus> getStatus() async {
    try {
      return await _gatewayService.getStatus();
    } catch (e) {
      throw GatewayException('Failed to get gateway status: $e');
    }
  }

  @override
  Future<GatewayConfig> getConfig() async {
    try {
      final configModel = await _localStorage.getConfig();
      if (configModel == null) {
        // Возвращаем конфигурацию по умолчанию
        return _getDefaultConfig();
      }
      return configModel.toEntity();
    } catch (e) {
      throw ConfigurationException('Failed to get gateway config: $e');
    }
  }

  @override
  Future<void> saveConfig(GatewayConfig config) async {
    try {
      final configModel = GatewayConfigModel.fromEntity(config);
      await _localStorage.saveConfig(configModel);
    } catch (e) {
      throw ConfigurationException('Failed to save gateway config: $e');
    }
  }

  @override
  Future<void> startGateway() async {
    try {
      final config = await getConfig();
      await _gatewayService.initialize(config);
      await _gatewayService.start();
    } catch (e) {
      throw ConnectionException('Failed to start gateway: $e');
    }
  }

  @override
  Future<void> stopGateway() async {
    try {
      await _gatewayService.stop();
    } catch (e) {
      throw ConnectionException('Failed to stop gateway: $e');
    }
  }

  @override
  Future<void> makeCall(String number) async {
    try {
      await _gatewayService.makeCall(number);
    } catch (e) {
      throw CallException('Failed to make call: $e');
    }
  }

  @override
  Future<void> answerCall(String callId) async {
    try {
      await _gatewayService.answerCall(callId);
    } catch (e) {
      throw CallException('Failed to answer call: $e');
    }
  }

  @override
  Future<void> endCall() async {
    try {
      await _gatewayService.endCall();
    } catch (e) {
      throw CallException('Failed to end call: $e');
    }
  }

  @override
  Future<List<CallInfo>> getCallHistory({int limit = 100}) async {
    try {
      return await _gatewayService.getCallHistory(limit: limit);
    } catch (e) {
      throw GatewayException('Failed to get call history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      return await _gatewayService.getDeviceInfo();
    } catch (e) {
      throw DeviceException('Failed to get device info: $e');
    }
  }

  @override
  Stream<GatewayStatus> get statusStream => _gatewayService.statusStream;

  @override
  Stream<String> get logStream => _gatewayService.logStream;

  /// Получить конфигурацию по умолчанию
  GatewayConfig _getDefaultConfig() {
    return const GatewayConfig(
      id: 'default',
      name: 'GOSTsimbox Gateway',
      sipConfig: SipConfig(
        server: '',
        port: 5060,
        username: '',
        password: '',
        transport: 'UDP',
        registrationTimeout: 3600,
        enableKeepAlive: true,
        keepAliveInterval: 30,
      ),
      gsmConfig: GsmConfig(
        enableAutoAnswer: false,
        callTimeout: 300,
        enableCallForwarding: false,
        enableCallRecording: false,
        recordingPath: '/storage/recordings',
        blacklistNumbers: [],
        whitelistNumbers: [],
        emergencyNumbers: ['112', '911', '999'],
      ),
      enableSms: true,
      enableCallLog: true,
      enableStatistics: true,
      logLevel: 'INFO',
      maxLogEntries: 1000,
    );
  }
}
