import 'package:logger/logger.dart';
import '../datasources/local/local_data_source.dart';
import '../datasources/remote/remote_data_source.dart';

/// Репозиторий для работы с шлюзом
class GatewayRepository {
  final LocalDataSource _localDataSource;
  final RemoteDataSource _remoteDataSource;
  final Logger _logger;

  GatewayRepository(
    this._localDataSource,
    this._remoteDataSource,
    this._logger,
  );

  /// Получение конфигурации шлюза
  Future<Map<String, dynamic>?> getGatewayConfig() async {
    try {
      _logger.d('Getting gateway config...');
      
      // Сначала пробуем получить из локального хранилища
      final localData = _localDataSource.getData('gateway_config');
      if (localData != null) {
        _logger.d('Gateway config found in local storage');
        return localData;
      }

      // Если нет в локальном хранилище, пробуем с сервера
      if (_remoteDataSource.isNetworkAvailable) {
        final remoteData = await _remoteDataSource.getData('/api/gateway/config');
        if (remoteData != null) {
          // Сохраняем в локальное хранилище
          await _localDataSource.saveData('gateway_config', remoteData);
          _logger.d('Gateway config retrieved from remote and saved locally');
          return remoteData;
        }
      }

      _logger.w('Gateway config not found');
      return null;
    } catch (e) {
      _logger.e('Failed to get gateway config', error: e);
      return null;
    }
  }

  /// Сохранение конфигурации шлюза
  Future<bool> saveGatewayConfig(Map<String, dynamic> config) async {
    try {
      _logger.d('Saving gateway config...');
      
      bool success = true;

      // Сохраняем локально
      final localSuccess = await _localDataSource.saveData('gateway_config', config);
      if (!localSuccess) {
        _logger.w('Failed to save gateway config locally');
        success = false;
      }

      // Отправляем на сервер, если есть сеть
      if (_remoteDataSource.isNetworkAvailable) {
        final remoteSuccess = await _remoteDataSource.postData('/api/gateway/config', config);
        if (remoteSuccess == null) {
          _logger.w('Failed to save gateway config remotely');
          success = false;
        }
      } else {
        _logger.w('Network not available, skipping remote save');
      }

      return success;
    } catch (e) {
      _logger.e('Failed to save gateway config', error: e);
      return false;
    }
  }

  /// Получение статуса шлюза
  Future<Map<String, dynamic>?> getGatewayStatus() async {
    try {
      _logger.d('Getting gateway status...');
      
      if (_remoteDataSource.isNetworkAvailable) {
        final status = await _remoteDataSource.getData('/api/gateway/status');
        if (status != null) {
          _logger.d('Gateway status retrieved from remote');
          return status;
        }
      }

      // Если нет сети, возвращаем локальный статус
      final localStatus = _localDataSource.getData('gateway_status');
      if (localStatus != null) {
        _logger.d('Gateway status found in local storage');
        return localStatus;
      }

      _logger.w('Gateway status not found');
      return null;
    } catch (e) {
      _logger.e('Failed to get gateway status', error: e);
      return null;
    }
  }

  /// Обновление статуса шлюза
  Future<bool> updateGatewayStatus(Map<String, dynamic> status) async {
    try {
      _logger.d('Updating gateway status...');
      
      bool success = true;

      // Сохраняем локально
      final localSuccess = await _localDataSource.saveData('gateway_status', status);
      if (!localSuccess) {
        _logger.w('Failed to save gateway status locally');
        success = false;
      }

      // Отправляем на сервер, если есть сеть
      if (_remoteDataSource.isNetworkAvailable) {
        final remoteSuccess = await _remoteDataSource.putData('/api/gateway/status', status);
        if (remoteSuccess == null) {
          _logger.w('Failed to update gateway status remotely');
          success = false;
        }
      } else {
        _logger.w('Network not available, skipping remote update');
      }

      return success;
    } catch (e) {
      _logger.e('Failed to update gateway status', error: e);
      return false;
    }
  }

  /// Получение статистики шлюза
  Future<Map<String, dynamic>?> getGatewayStats() async {
    try {
      _logger.d('Getting gateway stats...');
      
      if (_remoteDataSource.isNetworkAvailable) {
        final stats = await _remoteDataSource.getData('/api/gateway/stats');
        if (stats != null) {
          _logger.d('Gateway stats retrieved from remote');
          return stats;
        }
      }

      _logger.w('Gateway stats not available');
      return null;
    } catch (e) {
      _logger.e('Failed to get gateway stats', error: e);
      return null;
    }
  }

  /// Очистка данных шлюза
  Future<bool> clearGatewayData() async {
    try {
      _logger.d('Clearing gateway data...');
      
      final success = await _localDataSource.clearAllData();
      if (success) {
        _logger.d('Gateway data cleared successfully');
      } else {
        _logger.w('Failed to clear gateway data');
      }
      
      return success;
    } catch (e) {
      _logger.e('Failed to clear gateway data', error: e);
      return false;
    }
  }
}
