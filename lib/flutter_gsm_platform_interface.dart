import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_gsm_method_channel.dart';
import 'src/domain/entities/modem_device.dart';
import 'src/domain/entities/modem_call.dart';
import 'src/domain/models/modem_event.dart';
import 'src/domain/models/at_command_result.dart';
import 'src/domain/models/network_mode.dart';
import 'src/domain/models/restart_mode.dart';

abstract class FlutterGsmPlatform extends PlatformInterface {
  /// Constructs a FlutterGsmPlatform.
  FlutterGsmPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterGsmPlatform _instance = MethodChannelFlutterGsm();

  /// The default instance of [FlutterGsmPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterGsm].
  static FlutterGsmPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterGsmPlatform] when
  /// they register themselves.
  static set instance(FlutterGsmPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  // --- Modem API (see sdd-flutter_gsmsip-interface, sdd-flutter_gsm) ---
  //
  // Models GSM/UMTS modem devices reachable over a serial/AT-command
  // interface (chan_svistok-style) on desktop, or native telephony on
  // Android. On Android, most of this surface throws [UnsupportedError]
  // (AT commands aren't an Android concept); calls/SMS route through
  // flutter_dialer/flutter_tele instead — see AndroidFlutterGsm. On
  // Linux, [LinuxFlutterGsm] throws [UnimplementedError] until
  // sdd-asterisk-chan-simbox provides a real driver.

  /// Discovery & state
  Future<List<ModemDevice>> listModems() {
    throw UnimplementedError('listModems() has not been implemented.');
  }

  Future<ModemDevice?> getModem(String modemId) {
    throw UnimplementedError('getModem() has not been implemented.');
  }

  /// Push-style modem/call/SMS/USSD events. Must be safe to have zero or
  /// many listeners, and must not throw if no native event source exists.
  Stream<ModemEvent> get modemEvents {
    throw UnimplementedError('modemEvents has not been implemented.');
  }

  /// Raw / diagnostics
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    throw UnimplementedError('sendAtCommand() has not been implemented.');
  }

  Future<void> setDiagMode(String modemId, bool enabled) {
    throw UnimplementedError('setDiagMode() has not been implemented.');
  }

  /// Power / lifecycle
  Future<void> setPower(String modemId, {required bool on}) {
    throw UnimplementedError('setPower() has not been implemented.');
  }

  Future<void> restartModem(String modemId, {RestartMode mode = RestartMode.now}) {
    throw UnimplementedError('restartModem() has not been implemented.');
  }

  /// Identity / network
  Future<void> changeImei(String modemId, String imei) {
    throw UnimplementedError('changeImei() has not been implemented.');
  }

  Future<void> setNetworkMode(String modemId, NetworkMode mode) {
    throw UnimplementedError('setNetworkMode() has not been implemented.');
  }

  Future<void> setGroup(String modemId, String groupId) {
    throw UnimplementedError('setGroup() has not been implemented.');
  }

  /// Calling
  Future<ModemCall> dial(String modemId, String number) {
    throw UnimplementedError('dial() has not been implemented.');
  }

  Future<void> hangupCall(String callId) {
    throw UnimplementedError('hangupCall() has not been implemented.');
  }

  Future<void> answerCall(String callId) {
    throw UnimplementedError('answerCall() has not been implemented.');
  }

  /// SMS / USSD
  Future<void> sendSms(String modemId, String number, String text) {
    throw UnimplementedError('sendSms() has not been implemented.');
  }

  Future<String> sendUssd(String modemId, String code) {
    throw UnimplementedError('sendUssd() has not been implemented.');
  }
}
