/// Интерфейс репозитория для работы с шлюзом
/// Определяет контракт для доступа к данным шлюза
import '../entities/gateway_entity.dart';
import '../entities/gateway_config_entity.dart';

abstract class GatewayRepository {
  /// Получить текущий статус шлюза
  Future<GatewayStatus> getStatus();
  
  /// Получить конфигурацию шлюза
  Future<GatewayConfig> getConfig();
  
  /// Сохранить конфигурацию шлюза
  Future<void> saveConfig(GatewayConfig config);
  
  /// Запустить шлюз
  Future<void> startGateway();
  
  /// Остановить шлюз
  Future<void> stopGateway();
  
  /// Сделать звонок
  Future<void> makeCall(String number);
  
  /// Ответить на звонок
  Future<void> answerCall(String callId);
  
  /// Завершить звонок
  Future<void> endCall();
  
  /// Получить историю звонков
  Future<List<CallInfo>> getCallHistory({int limit = 100});
  
  /// Получить информацию об устройстве
  Future<Map<String, dynamic>> getDeviceInfo();
  
  /// Подписаться на обновления статуса
  Stream<GatewayStatus> get statusStream;
  
  /// Подписаться на логи
  Stream<String> get logStream;
}
