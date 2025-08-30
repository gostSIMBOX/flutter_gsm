/// Use cases для работы с шлюзом
class GatewayUseCases {
  final GatewayRepository _repository;

  GatewayUseCases(this._repository);

  /// Получение конфигурации шлюза
  Future<Map<String, dynamic>?> getGatewayConfig() async {
    return await _repository.getGatewayConfig();
  }

  /// Сохранение конфигурации шлюза
  Future<bool> saveGatewayConfig(Map<String, dynamic> config) async {
    return await _repository.saveGatewayConfig(config);
  }

  /// Получение статуса шлюза
  Future<Map<String, dynamic>?> getGatewayStatus() async {
    return await _repository.getGatewayStatus();
  }

  /// Обновление статуса шлюза
  Future<bool> updateGatewayStatus(Map<String, dynamic> status) async {
    return await _repository.updateGatewayStatus(status);
  }

  /// Получение статистики шлюза
  Future<Map<String, dynamic>?> getGatewayStats() async {
    return await _repository.getGatewayStats();
  }

  /// Очистка данных шлюза
  Future<bool> clearGatewayData() async {
    return await _repository.clearGatewayData();
  }
}
