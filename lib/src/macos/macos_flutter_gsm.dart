import 'dart:io';

import '../../flutter_gsm_platform_interface.dart';
import '../domain/entities/modem_device.dart';
import '../domain/entities/modem_call.dart';
import '../domain/models/modem_event.dart';
import '../domain/models/at_command_result.dart';
import '../domain/models/network_mode.dart';
import '../domain/models/restart_mode.dart';

/// macOS platform implementation of [FlutterGsmPlatform]
///
/// Mirrors [LinuxFlutterGsm]'s stub-first approach per
/// flows/sdd-flutter_gsm/02-specifications.md §2.4: `dartPluginClass`
/// registration, every modem method stubbed until
/// sdd-asterisk-chan-simbox provides a real driver (`/dev/tty.*` serial
/// on macOS).
class MacosFlutterGsm extends FlutterGsmPlatform {
  static void registerWith() {
    FlutterGsmPlatform.instance = MacosFlutterGsm();
  }

  @override
  Future<String?> getPlatformVersion() async {
    return 'macOS ${Platform.operatingSystemVersion}';
  }

  Never _notImplemented(String method) {
    throw UnimplementedError(
      '$method: implemented by sdd-asterisk-chan-simbox',
    );
  }

  @override
  Future<List<ModemDevice>> listModems() => _notImplemented('listModems');

  @override
  Future<ModemDevice?> getModem(String modemId) => _notImplemented('getModem');

  @override
  Stream<ModemEvent> get modemEvents => const Stream.empty();

  @override
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _notImplemented('sendAtCommand');

  @override
  Future<void> setDiagMode(String modemId, bool enabled) =>
      _notImplemented('setDiagMode');

  @override
  Future<void> setPower(String modemId, {required bool on}) =>
      _notImplemented('setPower');

  @override
  Future<void> restartModem(String modemId, {RestartMode mode = RestartMode.now}) =>
      _notImplemented('restartModem');

  @override
  Future<void> changeImei(String modemId, String imei) =>
      _notImplemented('changeImei');

  @override
  Future<void> setNetworkMode(String modemId, NetworkMode mode) =>
      _notImplemented('setNetworkMode');

  @override
  Future<void> setGroup(String modemId, String groupId) =>
      _notImplemented('setGroup');

  @override
  Future<ModemCall> dial(String modemId, String number) => _notImplemented('dial');

  @override
  Future<void> hangupCall(String callId) => _notImplemented('hangupCall');

  @override
  Future<void> answerCall(String callId) => _notImplemented('answerCall');

  @override
  Future<void> sendSms(String modemId, String number, String text) =>
      _notImplemented('sendSms');

  @override
  Future<String> sendUssd(String modemId, String code) =>
      _notImplemented('sendUssd');
}
