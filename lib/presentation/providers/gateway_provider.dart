/// Провайдер для управления состоянием шлюза в UI
/// Связывает презентационный слой с доменной логикой
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../core/di/dependency_injection.dart';
import '../../domain/entities/gateway_entity.dart';
import '../../domain/entities/gateway_config_entity.dart';
import '../../domain/entities/sms_entity.dart';
import '../../domain/exceptions/gateway_exceptions.dart';
import '../../domain/usecases/gateway_usecases.dart';

class GatewayProvider extends ChangeNotifier {
  final Logger _logger = Logger();

  // Состояние
  GatewayStatus _status = GatewayStatus(
    state: GatewayState.stopped,
    isConnected: false,
    isRegistered: false,
    lastUpdate: DateTime.now(),
  );

  GatewayConfig? _config;
  List<String> _logs = [];
  List<SmsMessage> _smsMessages = [];
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Геттеры
  GatewayStatus get status => _status;
  GatewayConfig? get config => _config;
  List<String> get logs => _logs;
  List<SmsMessage> get smsMessages => _smsMessages;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Подписки
  StreamSubscription<GatewayStatus>? _statusSubscription;
  StreamSubscription<String>? _logSubscription;

  GatewayProvider() {
    _initialize();
  }

  /// Инициализация провайдера
  Future<void> _initialize() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Загрузка конфигурации
      final getConfigUseCase = getIt<GetGatewayConfigUseCase>();
      _config = await getConfigUseCase.execute();

      // Подписка на обновления статуса
      final getStatusUseCase = getIt<GetGatewayStatusUseCase>();
      _status = await getStatusUseCase.execute();

      // Настройка подписок
      _setupSubscriptions();

      _isInitialized = true;
      _logger.i('Gateway provider initialized successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error initializing gateway provider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Настройка подписок на обновления
  void _setupSubscriptions() {
    // Подписка на статус
    _statusSubscription = getIt<GatewayRepository>().statusStream.listen(
      (status) {
        _status = status;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _logger.e('Status stream error: $error');
        notifyListeners();
      },
    );

    // Подписка на логи
    _logSubscription = getIt<GatewayRepository>().logStream.listen(
      (log) {
        _logs.add(log);
        if (_logs.length > 100) {
          _logs.removeAt(0);
        }
        notifyListeners();
      },
      onError: (error) {
        _logger.e('Log stream error: $error');
      },
    );
  }

  /// Обновление конфигурации
  Future<void> updateConfig(GatewayConfig config) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final saveConfigUseCase = getIt<SaveGatewayConfigUseCase>();
      await saveConfigUseCase.execute(config);
      
      _config = config;
      _logger.i('Configuration updated successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error updating config: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Запуск шлюза
  Future<void> startGateway() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final startGatewayUseCase = getIt<StartGatewayUseCase>();
      await startGatewayUseCase.execute();

      _logger.i('Gateway started successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error starting gateway: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Остановка шлюза
  Future<void> stopGateway() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final stopGatewayUseCase = getIt<StopGatewayUseCase>();
      await stopGatewayUseCase.execute();

      _logger.i('Gateway stopped successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error stopping gateway: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Сделать звонок
  Future<void> makeCall(String number) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final makeCallUseCase = getIt<MakeCallUseCase>();
      await makeCallUseCase.execute(number);

      _logger.i('Call initiated successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error making call: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Ответить на звонок
  Future<void> answerCall(String callId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final answerCallUseCase = getIt<AnswerCallUseCase>();
      await answerCallUseCase.execute(callId);

      _logger.i('Call answered successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error answering call: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Завершить звонок
  Future<void> endCall() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final endCallUseCase = getIt<EndCallUseCase>();
      await endCallUseCase.execute();

      _logger.i('Call ended successfully');
    } catch (e) {
      _error = e.toString();
      _logger.e('Error ending call: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Получить историю звонков
  Future<List<CallInfo>> getCallHistory({int limit = 100}) async {
    try {
      final getCallHistoryUseCase = getIt<GetCallHistoryUseCase>();
      return await getCallHistoryUseCase.execute(limit: limit);
    } catch (e) {
      _logger.e('Error getting call history: $e');
      return [];
    }
  }

  /// Получить информацию об устройстве
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final getDeviceInfoUseCase = getIt<GetDeviceInfoUseCase>();
      return await getDeviceInfoUseCase.execute();
    } catch (e) {
      _logger.e('Error getting device info: $e');
      return {'error': e.toString()};
    }
  }

  /// Очистить логи
  Future<void> clearLogs() async {
    _logs.clear();
    notifyListeners();
  }

  /// Очистить ошибку
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Обновить SMS сообщения
  void updateSmsMessages(List<SmsMessage> messages) {
    _smsMessages = messages;
    notifyListeners();
  }

  /// Добавить SMS сообщение
  void addSmsMessage(SmsMessage message) {
    _smsMessages.insert(0, message);
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _logSubscription?.cancel();
    super.dispose();
  }
}
