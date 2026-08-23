import '../../../flutter_gsm_platform_interface.dart';
import '../../domain/entities/modem_device.dart';
import '../../domain/entities/modem_call.dart';
import '../../domain/exceptions/modem_exceptions.dart';
import '../../domain/models/modem_event.dart';
import '../../domain/models/at_command_result.dart';
import '../../domain/models/network_mode.dart';
import '../../domain/models/restart_mode.dart';
import '../../domain/repositories/modem_repository.dart';

/// Default [ModemRepository] implementation — delegates every call to
/// [FlutterGsmPlatform.instance] and converts a platform-not-implemented
/// state into a typed [ModemDriverNotAvailableException] so callers never
/// need to catch [UnimplementedError] directly.
class ModemRepositoryImpl implements ModemRepository {
  final FlutterGsmPlatform _platform;

  ModemRepositoryImpl({FlutterGsmPlatform? platform})
      : _platform = platform ?? FlutterGsmPlatform.instance;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on UnimplementedError catch (_) {
      throw const ModemDriverNotAvailableException();
    }
  }

  @override
  Future<List<ModemDevice>> listModems() => _guard(_platform.listModems);

  @override
  Future<ModemDevice?> getModem(String modemId) =>
      _guard(() => _platform.getModem(modemId));

  @override
  Stream<ModemEvent> get modemEvents {
    try {
      return _platform.modemEvents;
    } on UnimplementedError catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _guard(() => _platform.sendAtCommand(modemId, command, timeout: timeout));

  @override
  Future<void> setDiagMode(String modemId, bool enabled) =>
      _guard(() => _platform.setDiagMode(modemId, enabled));

  @override
  Future<void> setPower(String modemId, {required bool on}) =>
      _guard(() => _platform.setPower(modemId, on: on));

  @override
  Future<void> restartModem(String modemId, {RestartMode mode = RestartMode.now}) =>
      _guard(() => _platform.restartModem(modemId, mode: mode));

  @override
  Future<void> changeImei(String modemId, String imei) =>
      _guard(() => _platform.changeImei(modemId, imei));

  @override
  Future<void> setNetworkMode(String modemId, NetworkMode mode) =>
      _guard(() => _platform.setNetworkMode(modemId, mode));

  @override
  Future<void> setGroup(String modemId, String groupId) =>
      _guard(() => _platform.setGroup(modemId, groupId));

  @override
  Future<ModemCall> dial(String modemId, String number) =>
      _guard(() => _platform.dial(modemId, number));

  @override
  Future<void> hangupCall(String callId) => _guard(() => _platform.hangupCall(callId));

  @override
  Future<void> answerCall(String callId) => _guard(() => _platform.answerCall(callId));

  @override
  Future<void> sendSms(String modemId, String number, String text) =>
      _guard(() => _platform.sendSms(modemId, number, text));

  @override
  Future<String> sendUssd(String modemId, String code) =>
      _guard(() => _platform.sendUssd(modemId, code));
}
