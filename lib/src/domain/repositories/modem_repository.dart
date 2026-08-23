import '../entities/modem_device.dart';
import '../entities/modem_call.dart';
import '../models/modem_event.dart';
import '../models/at_command_result.dart';
import '../models/network_mode.dart';
import '../models/restart_mode.dart';

/// Repository for GSM/UMTS modem devices reachable over a serial/
/// AT-command interface (chan_svistok-style), independent of any specific
/// transport (Linux ttyUSB today, Windows/macOS serial later).
///
/// Mirrors `FlutterGsmPlatform`'s modem API one-to-one, but is the
/// interface application code should depend on — not the platform
/// interface directly. Implementations wrap platform-channel failures
/// (`UnimplementedError` on stub platforms) into typed `ModemException`s.
abstract class ModemRepository {
  // Discovery & state
  Future<List<ModemDevice>> listModems();
  Future<ModemDevice?> getModem(String modemId);
  Stream<ModemEvent> get modemEvents;

  // Raw / diagnostics
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  });
  Future<void> setDiagMode(String modemId, bool enabled);

  // Power / lifecycle
  Future<void> setPower(String modemId, {required bool on});
  Future<void> restartModem(String modemId, {RestartMode mode = RestartMode.now});

  // Identity / network
  Future<void> changeImei(String modemId, String imei);
  Future<void> setNetworkMode(String modemId, NetworkMode mode);
  Future<void> setGroup(String modemId, String groupId);

  // Calling
  Future<ModemCall> dial(String modemId, String number);
  Future<void> hangupCall(String callId);
  Future<void> answerCall(String callId);

  // SMS / USSD
  Future<void> sendSms(String modemId, String number, String text);
  Future<String> sendUssd(String modemId, String code);
}
