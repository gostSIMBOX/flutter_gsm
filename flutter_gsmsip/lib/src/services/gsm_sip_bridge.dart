/// GSM SIP Bridge Service
/// Main API for the flutter_gsmsip library

class GsmSipBridge {
  static final GsmSipBridge _instance = GsmSipBridge._internal();
  
  factory GsmSipBridge() => _instance;
  
  GsmSipBridge._internal();

  bool _isInitialized = false;

  /// Initialize the GSM SIP bridge
  Future<bool> initialize() async {
    if (!_isInitialized) {
      // TODO: Initialize native platform channel
      _isInitialized = true;
    }
    return _isInitialized;
  }

  /// Check if the bridge is initialized
  bool get isInitialized => _isInitialized;

  /// Make a SIP call
  Future<bool> makeCall(String destination) async {
    if (!_isInitialized) {
      throw StateError('GsmSipBridge not initialized');
    }
    // TODO: Call native platform method
    return true;
  }

  /// Send SMS
  Future<bool> sendSms(String destination, String message) async {
    if (!_isInitialized) {
      throw StateError('GsmSipBridge not initialized');
    }
    // TODO: Call native platform method
    return true;
  }

  /// Get current status
  bool get isRunning => _isInitialized;
}
