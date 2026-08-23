import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_dialer/flutter_dialer.dart';
import 'package:flutter_smsussd/flutter_smsussd.dart';
import 'package:flutter_tele/flutter_tele.dart';

import '../../flutter_gsm_platform_interface.dart';
import '../domain/entities/modem_call.dart';
import '../domain/entities/modem_device.dart';
import '../domain/entities/call_state.dart' show CallDirection, CallState;
import '../domain/exceptions/modem_exceptions.dart';
import '../domain/models/at_command_result.dart';
import '../domain/models/modem_event.dart';
import '../domain/models/modem_state.dart';
import '../domain/models/network_mode.dart';
import '../domain/models/restart_mode.dart';

/// Android platform implementation of [FlutterGsmPlatform]
///
/// Backs calling/SMS with `flutter_dialer` + `flutter_tele` +
/// `flutter_smsussd` (see flows/sdd-flutter_gsm/02-specifications.md §2.2
/// and 04-implementation-log.md Task 4-5 for the design/investigation
/// behind this). AT-command/firmware/diagnostic methods correctly stay
/// unsupported — there's no Android equivalent for raw AT commands to a
/// ttyUSB modem; the phone's own radio is controlled via the telecom
/// stack, not AT commands.
///
/// Registered via `dartPluginClass` **alongside** the existing
/// `pluginClass: FlutterGsmPlugin` (both are valid together: `pluginClass`
/// provides the native `MethodChannel`/`FlutterPlugin` lifecycle,
/// `dartPluginClass` auto-sets [FlutterGsmPlatform.instance] on the Dart
/// side) — see pubspec.yaml.
class AndroidFlutterGsm extends FlutterGsmPlatform {
  static const MethodChannel _channel = MethodChannel('flutter_gsm');

  final TeleEndpoint _tele = TeleEndpoint();
  final FlutterSmsussd _sms = FlutterSmsussd();

  final Map<String, TeleCall> _callsByModemCallId = {};
  final Map<int, String> _modemCallIdByTeleCallId = {};
  int _nextCallSeq = 0;

  StreamController<ModemEvent>? _eventsController;
  StreamSubscription<dynamic>? _teleCallChangedSub;
  StreamSubscription<dynamic>? _teleCallReceivedSub;
  StreamSubscription<dynamic>? _teleCallTerminatedSub;
  StreamSubscription<dynamic>? _teleCallErrorSub;

  /// Registers this class as the default instance of [FlutterGsmPlatform].
  static void registerWith() {
    FlutterGsmPlatform.instance = AndroidFlutterGsm();
  }

  @override
  Future<String?> getPlatformVersion() async {
    return _channel.invokeMethod<String>('getPlatformVersion');
  }

  // --- Discovery & state ---

  @override
  Future<List<ModemDevice>> listModems() async {
    final raw = await _channel.invokeListMethod<dynamic>('getActiveSims') ?? const [];
    return [
      for (final entry in raw)
        if (entry is Map) _modemDeviceFromSimMap(entry),
    ];
  }

  ModemDevice _modemDeviceFromSimMap(Map entry) {
    final slotIndex = entry['slotIndex'] as int? ?? 0;
    return ModemDevice(
      id: 'sim-$slotIndex',
      displayName: entry['displayName'] as String? ?? entry['carrierName'] as String?,
      manufacturer: entry['carrierName'] as String?,
      state: ModemState.registered,
      registration: RegistrationState.registered,
    );
  }

  @override
  Future<ModemDevice?> getModem(String modemId) async {
    final devices = await listModems();
    for (final device in devices) {
      if (device.id == modemId) return device;
    }
    return null;
  }

  @override
  Stream<ModemEvent> get modemEvents {
    _eventsController ??= _createEventsController();
    return _eventsController!.stream;
  }

  StreamController<ModemEvent> _createEventsController() {
    late final StreamController<ModemEvent> controller;
    controller = StreamController<ModemEvent>.broadcast(
      onListen: _startTeleEventBridge,
      onCancel: _stopTeleEventBridge,
    );
    return controller;
  }

  void _startTeleEventBridge() {
    _teleCallChangedSub = _tele.on('call_changed').listen(_onTeleCallEvent);
    _teleCallReceivedSub = _tele.on('call_received').listen(_onTeleCallEvent);
    _teleCallTerminatedSub = _tele.on('call_terminated').listen(_onTeleCallEvent);
    _teleCallErrorSub = _tele.on('call_error').listen(_onTeleErrorEvent);
  }

  void _stopTeleEventBridge() {
    _teleCallChangedSub?.cancel();
    _teleCallReceivedSub?.cancel();
    _teleCallTerminatedSub?.cancel();
    _teleCallErrorSub?.cancel();
  }

  /// Defensive parsing — `flutter_tele`'s event payloads are loosely-typed
  /// `Map`s with no schema validation on its side (confirmed by reading
  /// its source: permissive `Map` handling throughout, not
  /// exceptions-on-malformed-input), so this must not assume shape.
  void _onTeleCallEvent(dynamic raw) {
    if (raw is! Map) return;
    try {
      final teleCall = TeleCall.fromMap(Map<String, dynamic>.from(raw));
      final modemCallId = _modemIdForTeleCall(teleCall);
      _callsByModemCallId[modemCallId] = teleCall;

      final call = _toModemCall(modemCallId, teleCall);
      _eventsController?.add(ModemCallStateChanged(
        modemId: 'sim-${teleCall.simSlot ?? 1}',
        timestamp: DateTime.now(),
        call: call,
      ));

      if (call.state == CallState.terminated) {
        _callsByModemCallId.remove(modemCallId);
        _modemCallIdByTeleCallId.remove(teleCall.id);
      }
    } catch (_) {
      // Malformed event payload — drop it rather than crash the stream.
    }
  }

  void _onTeleErrorEvent(dynamic raw) {
    if (raw is! Map) return;
    _eventsController?.add(ModemErrorOccurred(
      modemId: 'unknown',
      timestamp: DateTime.now(),
      code: raw['code']?.toString() ?? 'UNKNOWN',
      message: raw['message']?.toString() ?? raw.toString(),
    ));
  }

  String _modemIdForTeleCall(TeleCall teleCall) {
    final existing = _modemCallIdByTeleCallId[teleCall.id];
    if (existing != null) return existing;
    final generated = 'call-${_nextCallSeq++}';
    _modemCallIdByTeleCallId[teleCall.id] = generated;
    return generated;
  }

  ModemCall _toModemCall(String modemCallId, TeleCall teleCall) {
    return ModemCall(
      id: modemCallId,
      modemId: 'sim-${teleCall.simSlot ?? 1}',
      number: teleCall.remoteNumber ?? '',
      direction: (teleCall.direction == 'incoming')
          ? CallDirection.incoming
          : CallDirection.outgoing,
      state: _teleStateToCallState(teleCall.state),
      isOnHold: teleCall.held ?? false,
    );
  }

  CallState _teleStateToCallState(String? teleState) {
    switch (teleState) {
      case 'PJSIP_INV_STATE_CALLING':
      case 'INITIATING':
        return CallState.initiated;
      case 'PJSIP_INV_STATE_INCOMING':
        return CallState.incoming;
      case 'PJSIP_INV_STATE_CONFIRMED':
      case 'PJSIP_INV_STATE_EARLY':
      case 'PJSIP_INV_STATE_CONNECTING':
        return CallState.active;
      case 'PJSIP_INV_STATE_DISCONNECTED':
        return CallState.terminated;
      default:
        return CallState.initiated;
    }
  }

  // --- Raw / diagnostics: no Android equivalent ---

  Never _notSupportedOnAndroid(String method) {
    throw UnsupportedError(
      '$method: AT commands / modem hardware operations are not available on Android — '
      'the phone radio is controlled via the telecom stack, not AT commands',
    );
  }

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

  // --- Calling ---
  //
  // Dialing uses a plain Intent.ACTION_CALL (no default-dialer status
  // needed). Answering/holding/muting/hanging up go through flutter_tele's
  // managed call state, which does need default-dialer status — see
  // 04-implementation-log.md Task 4.

  @override
  Future<ModemCall> dial(String modemId, String number) async {
    final simSlot = _simSlotFromModemId(modemId);
    final teleCall = await _tele.makeCall(simSlot, number, null, null);
    final modemCallId = _modemIdForTeleCall(teleCall);
    _callsByModemCallId[modemCallId] = teleCall;
    return _toModemCall(modemCallId, teleCall);
  }

  Future<void> _requireDefaultDialer() async {
    if (!await FlutterDialer.isDefaultDialer()) {
      throw const ModemNotDefaultDialerException();
    }
  }

  TeleCall _requireTeleCall(String callId) {
    final call = _callsByModemCallId[callId];
    if (call == null) throw ModemCallNotFoundException(callId);
    return call;
  }

  int _simSlotFromModemId(String modemId) {
    final match = RegExp(r'^sim-(\d+)$').firstMatch(modemId);
    return match != null ? int.parse(match.group(1)!) : 1;
  }

  @override
  Future<void> hangupCall(String callId) async {
    await _requireDefaultDialer();
    await _tele.hangupCall(_requireTeleCall(callId));
  }

  @override
  Future<void> answerCall(String callId) async {
    await _requireDefaultDialer();
    await _tele.answerCall(_requireTeleCall(callId));
  }

  // --- SMS / USSD ---

  @override
  Future<void> sendSms(String modemId, String number, String text) async {
    final ok = await _sms.sendSms(phoneNumber: number, message: text);
    if (!ok) {
      throw ModemException('sendSms failed for $number');
    }
  }

  @override
  Future<String> sendUssd(String modemId, String code) =>
      _notSupportedOnAndroid('sendUssd');
}
