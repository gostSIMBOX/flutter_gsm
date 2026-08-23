import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_gsm_platform_interface.dart';
import 'src/domain/entities/modem_device.dart';
import 'src/domain/entities/modem_call.dart';
import 'src/domain/models/modem_event.dart';
import 'src/domain/models/at_command_result.dart';
import 'src/domain/models/network_mode.dart';
import 'src/domain/models/restart_mode.dart';

/// An implementation of [FlutterGsmPlatform] that uses method channels.
///
/// This is the Android implementation. AT-command modems are a desktop
/// concept, not something Android phones expose directly, so the
/// AT-command/diagnostic/firmware surface here throws [UnsupportedError].
/// Calls/SMS route through `flutter_dialer`/`flutter_tele` instead — see
/// `AndroidFlutterGsm` (lib/src/android/) for the real implementation.
/// This class remains the platform-channel fallback for
/// `getPlatformVersion()` and any future method-channel-based Android
/// native code.
class MethodChannelFlutterGsm extends FlutterGsmPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_gsm');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  Never _notSupportedOnAndroid(String method) {
    throw UnsupportedError(
      '$method: not available via the method channel — use AndroidFlutterGsm (flutter_dialer/flutter_tele) or the Dongle/SIP path',
    );
  }

  @override
  Future<List<ModemDevice>> listModems() async => const [];

  @override
  Future<ModemDevice?> getModem(String modemId) async => null;

  @override
  Stream<ModemEvent> get modemEvents => const Stream.empty();

  @override
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _notSupportedOnAndroid('sendAtCommand');

  @override
  Future<void> setDiagMode(String modemId, bool enabled) =>
      _notSupportedOnAndroid('setDiagMode');

  @override
  Future<void> setPower(String modemId, {required bool on}) =>
      _notSupportedOnAndroid('setPower');

  @override
  Future<void> restartModem(String modemId, {RestartMode mode = RestartMode.now}) =>
      _notSupportedOnAndroid('restartModem');

  @override
  Future<void> changeImei(String modemId, String imei) =>
      _notSupportedOnAndroid('changeImei');

  @override
  Future<void> setNetworkMode(String modemId, NetworkMode mode) =>
      _notSupportedOnAndroid('setNetworkMode');

  @override
  Future<void> setGroup(String modemId, String groupId) =>
      _notSupportedOnAndroid('setGroup');

  @override
  Future<ModemCall> dial(String modemId, String number) =>
      _notSupportedOnAndroid('dial');

  @override
  Future<void> hangupCall(String callId) => _notSupportedOnAndroid('hangupCall');

  @override
  Future<void> answerCall(String callId) => _notSupportedOnAndroid('answerCall');

  @override
  Future<void> sendSms(String modemId, String number, String text) =>
      _notSupportedOnAndroid('sendSms');

  @override
  Future<String> sendUssd(String modemId, String code) =>
      _notSupportedOnAndroid('sendUssd');
}
