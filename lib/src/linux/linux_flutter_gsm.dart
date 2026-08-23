import 'dart:io';

import '../../flutter_gsm_platform_interface.dart';
import '../domain/entities/modem_device.dart';
import '../domain/entities/modem_call.dart';
import '../domain/exceptions/modem_exceptions.dart';
import '../domain/models/modem_event.dart';
import '../domain/models/at_command_result.dart';
import '../domain/models/network_mode.dart';
import '../domain/models/restart_mode.dart';
import 'simbox_modem_repository.dart';

/// Linux platform implementation of [FlutterGsmPlatform].
///
/// Registered via `dartPluginClass` (pure-Dart plugin registration, no
/// native CMake/C++ scaffold) — see pubspec.yaml. Every modem method
/// delegates one-to-one to [SimboxModemRepository], which wraps
/// `libsimbox` (built by sdd-asterisk-chan-simbox,
/// `libsCpp/asterisk_chan_simbox`) via `dart:ffi` — see
/// flows/sdd-flutter_gsm-ffi.
class LinuxFlutterGsm extends FlutterGsmPlatform {
  /// Registers this class as the default instance of [FlutterGsmPlatform].
  static void registerWith() {
    FlutterGsmPlatform.instance = LinuxFlutterGsm();
  }

  /// Test-only injection seam — pass a real `SimboxModemRepository`
  /// constructed against a fake/stub `SimboxBindings` (see that class's
  /// `bindings`/`libraryPath` constructor params) to exercise this
  /// class's delegation without touching a real `libsimbox`. Production
  /// code should never pass this; the default (null) lazily constructs
  /// the real repository on first use.
  LinuxFlutterGsm({SimboxModemRepository? repository})
      : _injectedRepository = repository;

  final SimboxModemRepository? _injectedRepository;
  SimboxModemRepository? _lazyRepository;

  /// Lazily constructs (once) the real [SimboxModemRepository] — not at
  /// construction/registration time, so `libsimbox` being absent on this
  /// dev machine doesn't crash app startup (matches specifications'
  /// "Edge Cases": `SimboxNativeLibrary` throws
  /// [ModemDriverNotAvailableException] at first use). Every method
  /// below except [modemEvents] lets that exception propagate as-is —
  /// [ModemRepositoryImpl] only guards [UnimplementedError], but
  /// [ModemDriverNotAvailableException] is already the exact type
  /// callers expect, so no wrapping is needed.
  SimboxModemRepository get _repo =>
      _injectedRepository ?? (_lazyRepository ??= SimboxModemRepository());

  @override
  Future<String?> getPlatformVersion() async {
    try {
      final osRelease = File('/etc/os-release');
      if (await osRelease.exists()) {
        final content = await osRelease.readAsString();
        final match = RegExp(r'PRETTY_NAME="?([^"\n]+)"?').firstMatch(content);
        if (match != null) return match.group(1);
      }
    } catch (_) {
      // fall through to generic version string below
    }
    return 'Linux ${Platform.operatingSystemVersion}';
  }

  @override
  Future<List<ModemDevice>> listModems() => _repo.listModems();

  @override
  Future<ModemDevice?> getModem(String modemId) => _repo.getModem(modemId);

  /// Unlike every other method here, this must not throw even if
  /// `libsimbox` is unavailable (see [FlutterGsmPlatform.modemEvents]'s
  /// doc comment: "must not throw if no native event source exists") —
  /// so [ModemDriverNotAvailableException] is caught here specifically,
  /// not left to propagate like the rest of this class.
  @override
  Stream<ModemEvent> get modemEvents {
    try {
      return _repo.modemEvents;
    } on ModemDriverNotAvailableException {
      return const Stream.empty();
    }
  }

  @override
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) =>
      _repo.sendAtCommand(modemId, command, timeout: timeout);

  @override
  Future<void> setDiagMode(String modemId, bool enabled) =>
      _repo.setDiagMode(modemId, enabled);

  @override
  Future<void> setPower(String modemId, {required bool on}) =>
      _repo.setPower(modemId, on: on);

  @override
  Future<void> restartModem(String modemId, {RestartMode mode = RestartMode.now}) =>
      _repo.restartModem(modemId, mode: mode);

  @override
  Future<void> changeImei(String modemId, String imei) =>
      _repo.changeImei(modemId, imei);

  @override
  Future<void> setNetworkMode(String modemId, NetworkMode mode) =>
      _repo.setNetworkMode(modemId, mode);

  @override
  Future<void> setGroup(String modemId, String groupId) =>
      _repo.setGroup(modemId, groupId);

  @override
  Future<ModemCall> dial(String modemId, String number) =>
      _repo.dial(modemId, number);

  @override
  Future<void> hangupCall(String callId) => _repo.hangupCall(callId);

  @override
  Future<void> answerCall(String callId) => _repo.answerCall(callId);

  @override
  Future<void> sendSms(String modemId, String number, String text) =>
      _repo.sendSms(modemId, number, text);

  @override
  Future<String> sendUssd(String modemId, String code) =>
      _repo.sendUssd(modemId, code);
}
