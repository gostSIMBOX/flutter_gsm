/// Сервис шлюза
/// Обеспечивает взаимодействие с Android API и управление состоянием шлюза
import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:flutter_tele/flutter_tele.dart';
import '../../domain/entities/gateway_entity.dart';
import '../../domain/entities/gateway_config_entity.dart';

class GatewayService {
  static final GatewayService _instance = GatewayService._internal();
  factory GatewayService() => _instance;
  GatewayService._internal();

  final Logger _logger = Logger();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final TeleEndpoint _teleEndpoint = TeleEndpoint();
  
  GatewayConfig? _config;
  GatewayStatus _status = GatewayStatus(
    state: GatewayState.stopped,
    isConnected: false,
    isRegistered: false,
    lastUpdate: DateTime.now(),
  );

  final StreamController<GatewayStatus> _statusController = 
      StreamController<GatewayStatus>.broadcast();
  final StreamController<String> _logController = 
      StreamController<String>.broadcast();

  Stream<GatewayStatus> get statusStream => _statusController.stream;
  Stream<String> get logStream => _logController.stream;
  GatewayStatus get currentStatus => _status;

  // Состояния подключения
  bool _sipConnected = false;
  bool _sipRegistered = false;
  bool _gsmConnected = false;
  CallInfo? _currentCall;
  StreamSubscription? _callEventSubscription;
  StreamSubscription? _teleEventSubscription;

  /// Инициализация сервиса
  Future<void> initialize(GatewayConfig config) async {
    _config = config;
    _log('Initializing gateway service...');
    
    try {
      // Инициализация SIP
      await _initializeSip();
      
      // Инициализация GSM
      await _connectGsm();
      
      // Подписка на события звонков
      await _setupCallListeners();
      
      _log('Gateway service initialized successfully');
    } catch (e) {
      _log('Error initializing gateway service: $e');
      rethrow;
    }
  }

  /// Запуск шлюза
  Future<void> start() async {
    try {
      _log('Starting gateway...');
      await _updateStatus(GatewayState.starting);
      
      // Регистрация на SIP сервере
      await _registerSip();
      
      await _updateStatus(GatewayState.running);
      _log('Gateway started successfully');
    } catch (e) {
      await _updateStatus(GatewayState.error, errorMessage: e.toString());
      _log('Error starting gateway: $e');
      rethrow;
    }
  }

  /// Остановка шлюза
  Future<void> stop() async {
    try {
      _log('Stopping gateway...');
      await _updateStatus(GatewayState.stopped);
      
      // Отписка от событий
      await _callEventSubscription?.cancel();
      await _teleEventSubscription?.cancel();
      
      _log('Gateway stopped successfully');
    } catch (e) {
      _log('Error stopping gateway: $e');
      rethrow;
    }
  }

  /// Получение статуса
  Future<GatewayStatus> getStatus() async {
    return _status;
  }

  /// Сделать звонок
  Future<void> makeCall(String number) async {
    try {
      _log('Making call to $number...');
      
      final result = await _teleEndpoint.makeCall(number);
      if (result != null) {
        final callInfo = CallInfo(
          id: result,
          number: number,
          direction: CallDirection.outgoing,
          state: CallState.connecting,
          startTime: DateTime.now(),
        );
        
        _currentCall = callInfo;
        await _updateStatus(GatewayState.callInProgress, currentCall: callInfo);
        _log('Call initiated successfully');
      } else {
        throw Exception('Failed to initiate call');
      }
    } catch (e) {
      _log('Error making call: $e');
      rethrow;
    }
  }

  /// Ответить на звонок
  Future<void> answerCall(String callId) async {
    try {
      _log('Answering call $callId...');
      
      final result = await _teleEndpoint.answerCall();
      if (result) {
        if (_currentCall != null) {
          _currentCall = _currentCall!.copyWith(state: CallState.connected);
          await _updateStatus(GatewayState.callInProgress, currentCall: _currentCall);
        }
        _log('Call answered successfully');
      } else {
        throw Exception('Failed to answer call');
      }
    } catch (e) {
      _log('Error answering call: $e');
      rethrow;
    }
  }

  /// Завершить звонок
  Future<void> endCall() async {
    try {
      _log('Ending call...');
      
      final result = await _teleEndpoint.endCall();
      if (result) {
        if (_currentCall != null) {
          _currentCall = _currentCall!.copyWith(
            state: CallState.disconnected,
            endTime: DateTime.now(),
          );
          
          // Добавляем в историю звонков
          final recentCalls = List<CallInfo>.from(_status.recentCalls);
          recentCalls.insert(0, _currentCall!);
          if (recentCalls.length > 100) {
            recentCalls.removeLast();
          }
          
          await _updateStatus(
            _sipConnected ? GatewayState.running : GatewayState.stopped,
            recentCalls: recentCalls,
          );
        }
        _currentCall = null;
        _log('Call ended successfully');
      } else {
        throw Exception('Failed to end call');
      }
    } catch (e) {
      _log('Error ending call: $e');
      rethrow;
    }
  }

  /// Получить историю звонков
  Future<List<CallInfo>> getCallHistory({int limit = 100}) async {
    return _status.recentCalls.take(limit).toList();
  }

  /// Получить информацию об устройстве
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'osVersion': androidInfo.version.release,
          'hasRoot': await _checkRootAccess(),
          'radioFirmware': 'Unknown',
          'serialNumber': androidInfo.id,
          'supports2G': true,
          'supports3G': true,
          'supports4G': true,
          'supports5G': false,
          'supportsVoLTE': true,
          'supportsVoWiFi': false,
          'maxActiveLines': 1,
          'maxPassiveLines': 1,
          'maxWaitingCalls': 1,
          'maxTransferCalls': 1,
          'physicalSimSlots': 1,
          'eSimProfiles': 0,
          'supportsRemoteSim': false,
        };
      }
      return {'error': 'Unsupported platform'};
    } catch (e) {
      _log('Error getting device info: $e');
      return {'error': e.toString()};
    }
  }

  /// Инициализация SIP
  Future<void> _initializeSip() async {
    _log('Initializing SIP endpoint...');
    
    try {
      if (_config == null) {
        throw Exception('Gateway configuration not set');
      }

      // Инициализируем SIP endpoint с конфигурацией
      await _teleEndpoint.initialize(
        server: _config!.sipServer,
        port: _config!.sipPort,
        username: _config!.sipUsername,
        password: _config!.sipPassword,
        transport: _config!.sipTransport,
        useTls: _config!.sipUseTls,
      );

      _sipConnected = true;
      _log('SIP endpoint initialized successfully');
    } catch (e) {
      _log('Failed to initialize SIP endpoint: $e');
      _sipConnected = false;
      rethrow;
    }
  }

  /// Регистрация на SIP сервере
  Future<void> _registerSip() async {
    _log('Registering with SIP server...');
    
    try {
      if (!_sipConnected) {
        throw Exception('SIP endpoint not initialized');
      }

      if (_config == null) {
        throw Exception('Gateway configuration not set');
      }

      // Регистрируемся на SIP сервере
      await _teleEndpoint.register(
        domain: _config!.sipDomain,
        username: _config!.sipUsername,
        password: _config!.sipPassword,
        displayName: _config!.sipDisplayName,
      );

      _sipRegistered = true;
      _log('SIP registration successful');
    } catch (e) {
      _log('Failed to register with SIP server: $e');
      _sipRegistered = false;
      rethrow;
    }
  }

  /// Подключение к GSM сети
  Future<void> _connectGsm() async {
    _log('Connecting to GSM network...');
    
    try {
      // Проверяем доступность GSM сети
      final networkInfo = await _teleEndpoint.getNetworkInfo();
      if (networkInfo == null) {
        throw Exception('GSM network not available');
      }

      // Подключаемся к GSM сети
      await _teleEndpoint.connectGsm();
      
      _gsmConnected = true;
      _log('GSM connection established successfully');
    } catch (e) {
      _log('Failed to connect to GSM network: $e');
      _gsmConnected = false;
      rethrow;
    }
  }

  /// Настройка слушателей событий звонков
  Future<void> _setupCallListeners() async {
    try {
      _callEventSubscription = _teleEndpoint.callStateStream.listen((event) {
        _log('Call event: $event');
        
        // Обрабатываем события звонков
        switch (event.state) {
          case CallState.incoming:
            _log('Incoming call from ${event.remoteNumber}');
            _handleIncomingCall(event);
            break;
          case CallState.connected:
            _log('Call connected');
            _handleCallConnected(event);
            break;
          case CallState.ended:
            _log('Call ended');
            _handleCallEnded(event);
            break;
          case CallState.failed:
            _log('Call failed: ${event.error}');
            _handleCallFailed(event);
            break;
          default:
            _log('Call state changed to: ${event.state}');
        }
      });

      _teleEventSubscription = _teleEndpoint.teleEventStream.listen((event) {
        _log('Tele event: $event');
        
        // Обрабатываем телесобытия
        switch (event.type) {
          case TeleEventType.networkChanged:
            _log('Network changed: ${event.data}');
            _handleNetworkChanged(event);
            break;
          case TeleEventType.signalStrengthChanged:
            _log('Signal strength changed: ${event.data}');
            _handleSignalStrengthChanged(event);
            break;
          case TeleEventType.simStateChanged:
            _log('SIM state changed: ${event.data}');
            _handleSimStateChanged(event);
            break;
          case TeleEventType.smsReceived:
            _log('SMS received: ${event.data}');
            _handleSmsReceived(event);
            break;
          default:
            _log('Tele event: ${event.type} - ${event.data}');
        }
      });
    } catch (e) {
      _log('Error setting up call listeners: $e');
    }
  }

  /// Обновление статуса
  Future<void> _updateStatus(
    GatewayState state, {
    String? errorMessage,
    CallInfo? currentCall,
    List<CallInfo>? recentCalls,
  }) async {
    _status = _status.copyWith(
      state: state,
      isConnected: _sipConnected || _gsmConnected,
      isRegistered: _sipRegistered,
      errorMessage: errorMessage,
      currentCall: currentCall ?? _status.currentCall,
      recentCalls: recentCalls ?? _status.recentCalls,
      lastUpdate: DateTime.now(),
    );
    
    _statusController.add(_status);
  }

  /// Логирование
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _logger.i(logMessage);
    _logController.add(logMessage);
  }

  /// Освобождение ресурсов
  void dispose() {
    _statusController.close();
    _logController.close();
    _callEventSubscription?.cancel();
    _teleEventSubscription?.cancel();
  }

  /// Проверка наличия root доступа
  Future<bool> _checkRootAccess() async {
    try {
      // Проверяем наличие файлов, указывающих на root
      final rootIndicators = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
      ];

      for (final indicator in rootIndicators) {
        final file = File(indicator);
        if (await file.exists()) {
          return true;
        }
      }

      // Проверяем переменные окружения
      final suPath = Platform.environment['PATH']?.contains('su') ?? false;
      if (suPath) {
        return true;
      }

      return false;
    } catch (e) {
      _log('Error checking root access: $e');
      return false;
    }
  }

  /// Обработка входящего звонка
  void _handleIncomingCall(dynamic event) {
    // Здесь можно добавить логику для обработки входящих звонков
    // Например, показать уведомление или автоматически ответить
    _log('Handling incoming call from ${event.remoteNumber}');
  }

  /// Обработка подключенного звонка
  void _handleCallConnected(dynamic event) {
    _log('Call connected successfully');
    // Обновляем статус активного звонка
    _updateStatus();
  }

  /// Обработка завершенного звонка
  void _handleCallEnded(dynamic event) {
    _log('Call ended');
    // Очищаем статус активного звонка
    _updateStatus();
  }

  /// Обработка неудачного звонка
  void _handleCallFailed(dynamic event) {
    _log('Call failed: ${event.error}');
    // Обрабатываем ошибку звонка
  }

  /// Обработка изменения сети
  void _handleNetworkChanged(dynamic event) {
    _log('Network changed: ${event.data}');
    // Обновляем информацию о сети
    _updateStatus();
  }

  /// Обработка изменения силы сигнала
  void _handleSignalStrengthChanged(dynamic event) {
    _log('Signal strength changed: ${event.data}');
    // Обновляем информацию о сигнале
    _updateStatus();
  }

  /// Обработка изменения состояния SIM
  void _handleSimStateChanged(dynamic event) {
    _log('SIM state changed: ${event.data}');
    // Обновляем информацию о SIM-карте
    _updateStatus();
  }

  /// Обработка полученного SMS
  void _handleSmsReceived(dynamic event) {
    _log('SMS received: ${event.data}');
    // Обрабатываем полученное SMS
  }
}
