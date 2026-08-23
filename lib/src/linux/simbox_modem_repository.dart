import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import '../domain/entities/call_state.dart' show CallDirection, CallState;
import '../domain/entities/modem_call.dart';
import '../domain/entities/modem_device.dart';
import '../domain/exceptions/modem_exceptions.dart';
import '../domain/models/at_command_result.dart';
import '../domain/models/modem_event.dart';
import '../domain/models/network_mode.dart';
import '../domain/models/restart_mode.dart';
import 'simbox_state_mapping.dart';
import '../ffi/simbox_bindings.dart';
import '../ffi/simbox_native_library.dart';

/// Opens a fresh [SimboxBindings] from [path] — called from inside an
/// `Isolate.run`-spawned isolate, never from the main one (which already
/// has its own long-lived [SimboxModemRepository._bindings]). A
/// top-level function so referencing it can't accidentally capture
/// `this`/any [SimboxModemRepository] instance state in the closure sent
/// to the spawned isolate.
SimboxBindings _openBindingsForIsolate(String? path) {
  if (path == null) {
    throw StateError(
      'SimboxModemRepository was constructed with a custom SimboxBindings '
      'and no libraryPath — Isolate.run-wrapped calls need a path to '
      'reopen the library inside the spawned isolate',
    );
  }
  return SimboxBindings(DynamicLibrary.open(path));
}

/// Real Linux modem backend — wraps `libsimbox` (built by
/// `libsCpp/asterisk_chan_simbox`) via `dart:ffi`.
///
/// Not itself a [ModemRepository] implementation (that role stays with
/// `ModemRepositoryImpl`, which wraps `FlutterGsmPlatform` on every
/// platform equally) — `LinuxFlutterGsm` delegates each method to this
/// class one-to-one. Built up method-group by method-group across
/// flows/sdd-flutter_gsm-ffi's Phase 3 tasks; this file covers Tasks 3.1
/// (lifecycle + device listing) and 3.2 (event bridging) — call/SMS/
/// AT-command/power methods are added by later tasks in the same file.
class SimboxModemRepository {
  final SimboxBindings _bindings;
  final Pointer<Void> _handle;

  /// Path `libsimbox` was opened from — needed (in addition to
  /// [_bindings]) because `Isolate.run`'s spawned isolate can't capture
  /// an already-open `DynamicLibrary`/`SimboxBindings` (Dart rejects it
  /// at the isolate-message boundary; confirmed empirically, see
  /// [loadSimboxBindingsWithPath]'s doc comment). Every blocking native
  /// call instead reopens the library fresh, by path, inside the
  /// spawned isolate via [_openBindings]. Null only if a caller
  /// constructs this class with a custom [SimboxBindings] and no
  /// [libraryPath] — in that case every `Isolate.run`-wrapped call
  /// throws a clear [StateError] on first use rather than silently
  /// reusing an unopenable library.
  final String? _libraryPath;

  /// Serial number -> native device handle. Refreshed wholesale on every
  /// [listModems] call, and kept live incrementally between calls by
  /// attach/detach events (see [_onNativeEvent]). `modemId` throughout
  /// this class *is* the serial number — see
  /// flows/sdd-flutter_gsm-ffi/02-specifications.md "Identity Mapping".
  final Map<String, Pointer<Void>> _devicesBySerial = {};

  /// Serial number -> the call currently in flight on that device, if
  /// any. `simbox_api.h` has no separate call handle (calls are
  /// operations *on* a device, and a device has at most one call at a
  /// time) — this cache is what lets `SIMBOX_EVENT_CALL_STATE_CHANGED`
  /// (which only carries old/new state ints, no number/direction)
  /// enrich its `ModemCall` with the number/direction captured when the
  /// call started (`SIMBOX_EVENT_INCOMING_CALL`, or — once Task 3.3
  /// lands — `dial()`).
  final Map<String, ModemCall> _activeCalls = {};

  bool _disposed = false;

  final _eventsController = StreamController<ModemEvent>.broadcast();
  late final NativeCallable<simbox_event_cbFunction> _eventCallable;

  /// [configDir], if resolved (either passed directly or via
  /// [simboxConfigDirEnvVar]), is handed to `simbox_init()` so
  /// chan_dongle's real config loader can find `dongle.conf` at a
  /// predictable absolute path instead of relying on the process's
  /// current working directory — see
  /// `simbox_config_bridge_set_dir()` (native side) and
  /// flows/sdd-simbox-app-real-driver for why that matters for a
  /// packaged desktop app. Linux-only in effect (native-side config
  /// population is gated behind `#ifdef __linux__`); harmless to pass
  /// on any platform.
  factory SimboxModemRepository({
    SimboxBindings? bindings,
    String? libraryPath,
    String? configDir,
  }) {
    SimboxBindings resolvedBindings;
    var resolvedPath = libraryPath;
    if (bindings != null) {
      resolvedBindings = bindings;
    } else {
      final loaded = loadSimboxBindingsWithPath();
      resolvedBindings = loaded.bindings;
      resolvedPath ??= loaded.path;
    }

    final resolvedConfigDir =
        configDir ?? Platform.environment[simboxConfigDirEnvVar];
    Pointer<simbox_config_t> configPtr = nullptr;
    Pointer<Char> configDirPtr = nullptr;
    if (resolvedConfigDir != null) {
      configDirPtr = resolvedConfigDir.toNativeUtf8().cast<Char>();
      configPtr = simbox_config_t.$allocate(
        calloc,
        config_dir: configDirPtr,
        state_dir: nullptr,
        log_level: 0,
        auto_discovery: false,
        auto_recover_diag: false,
      );
    }

    final handle = resolvedBindings.simbox_init(configPtr);
    // simbox_init() copies config_dir into an internal static buffer
    // synchronously before returning (see simbox_config_bridge_set_dir's
    // doc comment) — safe to free right away, no async handoff like the
    // event-callback ownership-transfer contract.
    if (configPtr != nullptr) {
      calloc.free(configDirPtr);
      calloc.free(configPtr);
    }
    if (handle == nullptr) {
      throw const ModemDriverNotAvailableException();
    }
    return SimboxModemRepository._(resolvedBindings, handle, resolvedPath);
  }

  SimboxModemRepository._(this._bindings, this._handle, this._libraryPath) {
    // NativeCallable.listener is required, not Pointer.fromFunction —
    // libsimbox may invoke this callback from any of its own pthreads
    // (confirmed by reading simbox_api.c: the codebase uses pthread
    // throughout), and only .listener's isolate-safe dispatch is
    // correct to call from a thread the Dart VM doesn't own. See
    // specifications' "Event Bridging".
    _eventCallable = NativeCallable<simbox_event_cbFunction>.listener(
      _onNativeEvent,
    );
    _bindings.simbox_set_event_callback(
      _handle,
      _eventCallable.nativeFunction,
      nullptr,
    );
  }

  /// Stream of modem events — device attach/detach, call state changes,
  /// incoming SMS/USSD, errors. See specifications' event mapping table
  /// for exactly which `simbox_event_type_t` values produce which
  /// [ModemEvent] subtype (two — balance updates, DIAG-programmator
  /// progress — have no matching subtype and are silently dropped, not
  /// a bug).
  Stream<ModemEvent> get modemEvents => _eventsController.stream;

  /// Places an outgoing call. `simbox_call_originate` itself doesn't
  /// return a call object (see specifications' "Identity Mapping" — a
  /// device has at most one call at a time, so `callId == modemId`);
  /// the returned [ModemCall] is synthesized here and cached in
  /// [_activeCalls] so a later `SIMBOX_EVENT_CALL_STATE_CHANGED` can
  /// enrich itself with this call's number/direction.
  Future<ModemCall> dial(String modemId, String number) async {
    final devHandle = _requireDevice(modemId)!;
    final libraryPath = _libraryPath;
    final numberPtr = number.toNativeUtf8().cast<Char>();
    final devAddr = devHandle.address;
    final numberAddr = numberPtr.address;
    try {
      final result = await Isolate.run(
        () => _openBindingsForIsolate(libraryPath).simbox_call_originate(
          Pointer<Void>.fromAddress(devAddr),
          Pointer<Char>.fromAddress(numberAddr),
        ),
      );
      if (result != 0) {
        throw ModemException(
          'simbox_call_originate failed with code $result',
        );
      }
    } finally {
      calloc.free(numberPtr);
    }

    final call = ModemCall(
      id: modemId,
      modemId: modemId,
      number: number,
      direction: CallDirection.outgoing,
      state: CallState.initiated,
      startTime: DateTime.now(),
    );
    _activeCalls[modemId] = call;
    return call;
  }

  Future<void> hangupCall(String callId) async {
    final devHandle = _requireDevice(callId)!;
    final libraryPath = _libraryPath;
    final devAddr = devHandle.address;
    final result = await Isolate.run(
      () => _openBindingsForIsolate(
        libraryPath,
      ).simbox_call_hangup(Pointer<Void>.fromAddress(devAddr)),
    );
    if (result != 0) {
      throw ModemException('simbox_call_hangup failed with code $result');
    }
    _activeCalls.remove(callId);
  }

  Future<void> answerCall(String callId) async {
    final devHandle = _requireDevice(callId)!;
    final libraryPath = _libraryPath;
    final devAddr = devHandle.address;
    final result = await Isolate.run(
      () => _openBindingsForIsolate(
        libraryPath,
      ).simbox_call_answer(Pointer<Void>.fromAddress(devAddr)),
    );
    if (result != 0) {
      throw ModemException('simbox_call_answer failed with code $result');
    }
    final existing = _activeCalls[callId];
    if (existing != null) {
      _activeCalls[callId] = existing.copyWith(
        state: CallState.active,
        connectTime: DateTime.now(),
      );
    }
  }

  Future<void> sendSms(String modemId, String number, String text) async {
    final devHandle = _requireDevice(modemId)!;
    final libraryPath = _libraryPath;
    final numberPtr = number.toNativeUtf8().cast<Char>();
    final textPtr = text.toNativeUtf8().cast<Char>();
    final devAddr = devHandle.address;
    final numberAddr = numberPtr.address;
    final textAddr = textPtr.address;
    try {
      final result = await Isolate.run(
        () => _openBindingsForIsolate(libraryPath).simbox_sms_send(
          Pointer<Void>.fromAddress(devAddr),
          Pointer<Char>.fromAddress(numberAddr),
          Pointer<Char>.fromAddress(textAddr),
        ),
      );
      if (result != 0) {
        throw ModemException('simbox_sms_send failed with code $result');
      }
    } finally {
      calloc.free(numberPtr);
      calloc.free(textPtr);
    }
  }

  /// `simbox_ussd_send` only enqueues the request (native side, real
  /// AT+CUSD dispatch — response arrives asynchronously via
  /// `SIMBOX_EVENT_USSD_RESPONSE`, now that `sdd-asterisk-chan-simbox`'s
  /// Task 5.8 wired real manager-event dispatch through `BUILD_MANAGER`).
  /// So: enqueue, then await the next [ModemUssdReceived] for this
  /// device on [modemEvents], bounded by [timeout] — matches
  /// specifications' original method-mapping design exactly, this was
  /// just blocked on the native event not existing yet until now.
  Future<String> sendUssd(
    String modemId,
    String code, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final devHandle = _requireDevice(modemId)!;
    final libraryPath = _libraryPath;
    final response = _eventsController.stream
        .where((e) => e is ModemUssdReceived && e.modemId == modemId)
        .cast<ModemUssdReceived>()
        .first
        .timeout(timeout);

    final codePtr = code.toNativeUtf8().cast<Char>();
    final devAddr = devHandle.address;
    final codeAddr = codePtr.address;
    try {
      final result = await Isolate.run(
        () => _openBindingsForIsolate(libraryPath).simbox_ussd_send(
          Pointer<Void>.fromAddress(devAddr),
          Pointer<Char>.fromAddress(codeAddr),
        ),
      );
      if (result != 0) {
        throw ModemException('simbox_ussd_send failed with code $result');
      }
    } finally {
      calloc.free(codePtr);
    }

    final event = await response;
    return event.text;
  }

  /// Blocks for up to ~3s on Linux — `libsimbox`'s `simbox_at_command`
  /// is a real synchronous wait on the AT response (via a
  /// `pthread_cond_t`, see `sdd-asterisk-chan-simbox`'s Task 5.8), not
  /// the old instant fake `"OK\r\n"`. The native call itself runs via
  /// `Isolate.run` (Task 4.1 — see specifications' "Threading") so this
  /// doesn't freeze the caller's isolate; `.timeout()` still enforces
  /// [timeout] Dart-side since `simbox_at_command`'s own ~3s deadline
  /// has no parameter to shorten it per-call.
  Future<AtCommandResult> sendAtCommand(
    String modemId,
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final devHandle = _requireDevice(modemId)!;
    final libraryPath = _libraryPath;
    final commandPtr = command.toNativeUtf8().cast<Char>();
    const bufferSize = 4096;
    final responseBuf = calloc<Char>(bufferSize);
    final stopwatch = Stopwatch()..start();
    final devAddr = devHandle.address;
    final commandAddr = commandPtr.address;
    final responseAddr = responseBuf.address;

    final native = Isolate.run(
      () => _openBindingsForIsolate(libraryPath).simbox_at_command(
        Pointer<Void>.fromAddress(devAddr),
        Pointer<Char>.fromAddress(commandAddr),
        Pointer<Char>.fromAddress(responseAddr),
        bufferSize,
      ),
    );

    try {
      final result = await native.timeout(timeout);
      // Free right here, in the same continuation that reads the
      // buffer — `native` has genuinely completed by this point, so
      // this is race-free. (A previous version freed via a second,
      // separately-attached listener on `native`; that listener's
      // microtask ran *before* this continuation resumed on normal
      // completion, freeing the buffer before it was read — a real
      // use-after-free caught by a failing test, not a hypothetical.)
      final raw = responseBuf.cast<Utf8>().toDartString();
      calloc.free(commandPtr);
      calloc.free(responseBuf);
      return AtCommandResult(
        raw: raw,
        ok: result == 0,
        error: result == 0 ? null : 'simbox_at_command failed with code $result',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } on TimeoutException {
      // Don't free yet: `simbox_at_command` may still be inside its own
      // ~3s internal wait when a shorter [timeout] fires, and freeing
      // now would race a real native write into `responseBuf`. Free
      // once `native` actually finishes, whenever that is.
      unawaited(
        native.then(
          (_) {
            calloc.free(commandPtr);
            calloc.free(responseBuf);
          },
          onError: (_) {
            calloc.free(commandPtr);
            calloc.free(responseBuf);
          },
        ),
      );
      return AtCommandResult(
        raw: '',
        ok: false,
        error: 'sendAtCommand timed out after $timeout',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// AT+CFUN=1,1 confirmed from chan_svistok source
  /// (`at_command.c`'s `at_enque_reset`, and README.txt's "reset
  /// dongle" entry). `on: false` (AT+CFUN=0) is standard 3GPP but
  /// **not** independently confirmed against real hardware in this
  /// codebase — see specifications' method-mapping table.
  Future<void> setPower(String modemId, {required bool on}) async {
    final result = await sendAtCommand(
      modemId,
      on ? 'AT+CFUN=1,1\r' : 'AT+CFUN=0\r',
    );
    if (!result.ok) {
      throw ModemException('setPower($on) failed: ${result.error}');
    }
  }

  /// `mode` has no AT-level equivalent — `now` issues the reset
  /// immediately; `graceful`/`whenConvenient` wait for the current call
  /// (if any) to end first, bounded by a timeout, rather than
  /// interrupting it.
  Future<void> restartModem(
    String modemId, {
    RestartMode mode = RestartMode.now,
  }) async {
    if (mode != RestartMode.now && _activeCalls.containsKey(modemId)) {
      await _eventsController.stream
          .where(
            (e) =>
                e is ModemCallStateChanged &&
                e.modemId == modemId &&
                (e.call.state == CallState.terminated ||
                    e.call.state == CallState.failed),
          )
          .first
          .timeout(const Duration(seconds: 30), onTimeout: () => throw TimeoutException(
                'restartModem($mode): call did not end within 30s',
              ));
    }
    final result = await sendAtCommand(modemId, 'AT+CFUN=1,1\r');
    if (!result.ok) {
      throw ModemException('restartModem failed: ${result.error}');
    }
  }

  /// Only `NetworkMode.gsmOnly` (`AT^SYSCFG=13,...`) is confirmed from
  /// chan_svistok's own `README.txt`. `auto`/`wcdmaOnly` mode codes are
  /// not documented anywhere in the reference source — throwing rather
  /// than guessing a code that could lock a real modem to an
  /// unreachable network, per specifications' explicit design decision.
  Future<void> setNetworkMode(String modemId, NetworkMode mode) async {
    if (mode != NetworkMode.gsmOnly) {
      throw UnsupportedError(
        'setNetworkMode($mode): AT^SYSCFG code not confirmed against '
        'real hardware/vendor AT reference — only gsmOnly is wired',
      );
    }
    final result = await sendAtCommand(modemId, 'AT^SYSCFG=13,0,3FFFFFFF,0,3\r');
    if (!result.ok) {
      throw ModemException('setNetworkMode failed: ${result.error}');
    }
  }

  /// Pure Dart-side local state — `groupId` is an app-level
  /// organizational concept chan_svistok/`libsimbox` has never modeled
  /// (no native call). In-memory only (lost on process restart) per
  /// specifications' resolution — no `shared_preferences` dependency
  /// added without being asked for one.
  final Map<String, String> _groupByModemId = {};

  Future<void> setGroup(String modemId, String groupId) async {
    _requireDevice(modemId); // validates modemId is tracked, throws if not
    _groupByModemId[modemId] = groupId;
  }

  /// `enabled: true` only — `simbox_prog_open`/`simbox_prog_set_diagmode`
  /// (Qualcomm DIAG-mode switch) have no corresponding "exit diag mode"
  /// function in `simbox_api.h`. `enabled: false` throws, matching the
  /// AT-command/firmware "no equivalent exists" convention already used
  /// elsewhere in this package rather than silently no-op'ing.
  Future<void> setDiagMode(String modemId, bool enabled) async {
    if (!enabled) {
      throw UnsupportedError(
        'setDiagMode(false): no "exit diag mode" function exists in '
        'libsimbox',
      );
    }
    final devHandle = _requireDevice(modemId)!;
    final libraryPath = _libraryPath;
    final device = _readDevice(devHandle);
    final portPath = device.portPath;
    if (portPath == null) {
      throw ModemException('setDiagMode: device $modemId has no tty port');
    }
    final portPtr = portPath.toNativeUtf8().cast<Char>();
    final portAddr = portPtr.address;
    try {
      await Isolate.run(() {
        final bindings = _openBindingsForIsolate(libraryPath);
        final prog = bindings.simbox_prog_open(
          Pointer<Char>.fromAddress(portAddr),
        );
        if (prog == nullptr) {
          throw ModemException('simbox_prog_open failed for $modemId');
        }
        try {
          final result = bindings.simbox_prog_set_diagmode(prog);
          if (result != 0) {
            throw ModemException(
              'simbox_prog_set_diagmode failed with code $result',
            );
          }
        } finally {
          bindings.simbox_prog_close(prog);
        }
      });
    } finally {
      calloc.free(portPtr);
    }
  }

  /// **Genuinely blocked, not guessed around**: `ttyprog_changeimei`
  /// (chan_dongle.c's real IMEI-change path) is called in three places
  /// across chan_svistok but defined nowhere in the checked-in source —
  /// a real, pre-existing chan_svistok gap (see
  /// `sdd-asterisk-chan-simbox`'s Task 5.7). `simbox_change_imei`
  /// always returns -1 on `SIMBOX_DEV_REAL`; this surfaces that as a
  /// clear typed exception rather than a silent no-op or a fabricated
  /// success.
  Future<void> changeImei(String modemId, String imei) async {
    final devHandle = _requireDevice(modemId)!;
    final libraryPath = _libraryPath;
    final imeiPtr = imei.toNativeUtf8().cast<Char>();
    final devAddr = devHandle.address;
    final imeiAddr = imeiPtr.address;
    try {
      final result = await Isolate.run(
        () => _openBindingsForIsolate(libraryPath).simbox_change_imei(
          Pointer<Void>.fromAddress(devAddr),
          Pointer<Char>.fromAddress(imeiAddr),
        ),
      );
      if (result != 0) {
        throw const ModemException(
          'changeImei is not available: ttyprog_changeimei is called by '
          'chan_svistok but not defined anywhere in its source (a '
          'pre-existing upstream gap, not fixable from this package)',
        );
      }
    } finally {
      calloc.free(imeiPtr);
    }
  }

  Future<List<ModemDevice>> listModems() async {
    final count = _bindings.simbox_device_count(_handle);
    final devices = <ModemDevice>[];
    _devicesBySerial.clear();

    for (var i = 0; i < count; i++) {
      final devHandle = _bindings.simbox_device_get_by_index(_handle, i);
      if (devHandle == nullptr) continue;
      final device = _readDevice(devHandle);
      _devicesBySerial[device.id] = devHandle;
      devices.add(device);
    }

    return devices;
  }

  Future<ModemDevice?> getModem(String modemId) async {
    final devHandle = _requireDevice(modemId, orNull: true);
    if (devHandle == null) return null;
    return _readDevice(devHandle);
  }

  /// Looks up a tracked device handle by serial number.
  ///
  /// With [orNull] false (the default — used by every call/SMS/AT-
  /// command method added in later tasks), throws
  /// [ModemNotFoundException] if `modemId` isn't currently tracked
  /// (i.e. wasn't present in the most recent [listModems] — or, once
  /// Task 3.2 lands, was removed by a disconnect event). With [orNull]
  /// true (used by [getModem]), returns null instead.
  Pointer<Void>? _requireDevice(String modemId, {bool orNull = false}) {
    final handle = _devicesBySerial[modemId];
    if (handle == null) {
      if (orNull) return null;
      throw ModemNotFoundException(modemId);
    }
    return handle;
  }

  ModemDevice _readDevice(Pointer<Void> devHandle) {
    final infoPtr = calloc<simbox_device_info_t>();
    try {
      final result = _bindings.simbox_device_get_info(devHandle, infoPtr);
      if (result != 0) {
        throw ModemException(
          'simbox_device_get_info failed with code $result',
        );
      }

      final info = infoPtr.ref;
      final tty = _charArrayToString(info.tty_data, 128);
      final name = _charArrayToString(info.name, 64);
      final model = _charArrayToString(info.model, 64);
      final imei = _charArrayToString(info.imei, 32);
      final imsi = _charArrayToString(info.imsi, 32);

      return ModemDevice(
        id: _charArrayToString(info.sn, 64),
        portPath: tty.isEmpty ? null : tty,
        displayName: name.isEmpty ? null : name,
        model: model.isEmpty ? null : model,
        imei: imei.isEmpty ? null : imei,
        imsi: imsi.isEmpty ? null : imsi,
        state: simboxDeviceStateToModemState(info.state),
        signal: info.rssi,
        registration: simboxDeviceStateToRegistrationState(info.state),
      );
    } finally {
      calloc.free(infoPtr);
    }
  }

  /// Reads a fixed-size, NUL-terminated (or truncated) C char array
  /// field out of a `Struct` (`simbox_device_info_t`'s `sn`/`imei`/etc.
  /// are `char[N]`, not `char *` — `ffigen` exposes these as
  /// `Array<Char>`, which has no built-in string conversion).
  static String _charArrayToString(Array<Char> array, int maxLen) {
    final codeUnits = <int>[];
    for (var i = 0; i < maxLen; i++) {
      final c = array[i];
      if (c == 0) break;
      codeUnits.add(c);
    }
    return String.fromCharCodes(codeUnits);
  }

  /// Dispatches one native event onto [modemEvents], per specifications'
  /// event mapping table. Runs on whatever thread `libsimbox` fired the
  /// callback from — `NativeCallable.listener`'s whole purpose is
  /// making that safe to do (it hands off to the owning isolate
  /// internally), so no additional thread-hopping is needed here.
  ///
  /// **Ownership**: `eventPtr` is heap-allocated by the native side and
  /// ownership transfers to this callback (see `simbox_event_cb`'s doc
  /// comment in `simbox_types.h` — required because listener callbacks
  /// are asynchronous, so a stack-local struct would already be
  /// out-of-scope by the time this runs). Freed in the `finally` below
  /// no matter which case runs or returns early.
  void _onNativeEvent(Pointer<simbox_event_t> eventPtr, Pointer<Void> _) {
    try {
      _dispatchNativeEvent(eventPtr.ref);
    } finally {
      calloc.free(eventPtr);
    }
  }

  void _dispatchNativeEvent(simbox_event_t event) {
    final modemId = _nullableCString(event.device_sn) ?? '';
    final timestamp = DateTime.now();

    switch (event.type) {
      case simbox_event_type_t.SIMBOX_EVENT_DEVICE_CONNECTED:
        final devHandle = _bindings.simbox_device_get_by_sn(
          _handle,
          event.device_sn,
        );
        if (devHandle == nullptr) return;
        final device = _readDevice(devHandle);
        _devicesBySerial[device.id] = devHandle;
        _eventsController.add(
          ModemAttached(modemId: modemId, timestamp: timestamp, device: device),
        );

      case simbox_event_type_t.SIMBOX_EVENT_DEVICE_DISCONNECTED:
        _devicesBySerial.remove(modemId);
        _activeCalls.remove(modemId);
        _eventsController.add(
          ModemDetached(modemId: modemId, timestamp: timestamp),
        );

      case simbox_event_type_t.SIMBOX_EVENT_INCOMING_CALL:
        final caller = _nullableCString(event.data.incoming_call.caller) ?? '';
        final call = ModemCall(
          id: modemId,
          modemId: modemId,
          number: caller,
          direction: CallDirection.incoming,
          state: CallState.incoming,
          startTime: timestamp,
        );
        _activeCalls[modemId] = call;
        _eventsController.add(
          ModemCallStateChanged(modemId: modemId, timestamp: timestamp, call: call),
        );

      case simbox_event_type_t.SIMBOX_EVENT_CALL_STATE_CHANGED:
        final nativeState = simbox_device_state_t.fromValue(
          event.data.call_state.new_state,
        );
        final callState = simboxDeviceStateToCallState(nativeState);
        if (callState == null) return; // not a real call-state transition

        final existing = _activeCalls[modemId];
        final call = (existing ??
                ModemCall(
                  id: modemId,
                  modemId: modemId,
                  number: '', // no prior INCOMING_CALL/dial() seen for this call
                  direction: CallDirection.outgoing,
                  startTime: timestamp,
                ))
            .copyWith(
          state: callState,
          connectTime: callState == CallState.active
              ? (existing?.connectTime ?? timestamp)
              : existing?.connectTime,
          endTime: callState == CallState.terminated ? timestamp : null,
        );

        if (callState == CallState.terminated || callState == CallState.failed) {
          _activeCalls.remove(modemId);
        } else {
          _activeCalls[modemId] = call;
        }
        _eventsController.add(
          ModemCallStateChanged(modemId: modemId, timestamp: timestamp, call: call),
        );

      case simbox_event_type_t.SIMBOX_EVENT_INCOMING_SMS:
        final from = _nullableCString(event.data.incoming_sms.sender) ?? '';
        final text = _nullableCString(event.data.incoming_sms.text) ?? '';
        _eventsController.add(
          ModemSmsReceived(
            modemId: modemId,
            timestamp: timestamp,
            from: from,
            text: text,
            receivedAt: timestamp,
          ),
        );

      case simbox_event_type_t.SIMBOX_EVENT_USSD_RESPONSE:
        final response = _nullableCString(event.data.ussd.response) ?? '';
        _eventsController.add(
          ModemUssdReceived(modemId: modemId, timestamp: timestamp, text: response),
        );

      case simbox_event_type_t.SIMBOX_EVENT_BALANCE_UPDATE:
        // No ModemEvent subtype exists for balance — dropped, per
        // specifications (not tracked on ModemDevice either).
        break;

      case simbox_event_type_t.SIMBOX_EVENT_DEVICE_ERROR:
        final message = _nullableCString(event.data.error.message) ?? '';
        _eventsController.add(
          ModemErrorOccurred(
            modemId: modemId,
            timestamp: timestamp,
            code: event.data.error.error_code.toString(),
            message: message,
          ),
        );

      case simbox_event_type_t.SIMBOX_EVENT_PROG_PROGRESS:
        // DIAG-programmator progress — out of scope, ModemRepository
        // has no programmator concept.
        break;
    }
  }

  /// `Pointer<Char>` -> `String?`, null-safe (native code may pass a
  /// NULL string pointer for an absent field, e.g. `device_sn` isn't
  /// guaranteed non-null by every event type).
  static String? _nullableCString(Pointer<Char> ptr) {
    if (ptr == nullptr) return null;
    return ptr.cast<Utf8>().toDartString();
  }

  /// Idempotent — safe to call more than once (e.g. a caller that both
  /// explicitly disposes and relies on a framework's teardown hook).
  /// A second call is a no-op rather than a double-free: `libsimbox`'s
  /// `simbox_shutdown` and `NativeCallable.close` are not themselves
  /// guaranteed safe to call twice on the same handle.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _eventCallable.close();
    _eventsController.close();
    _devicesBySerial.clear();
    _activeCalls.clear();
    _bindings.simbox_shutdown(_handle);
  }

  /// **Test-only.** Registers a fabricated device via
  /// `simbox_device_register` — the same native call the discovery
  /// pipeline uses (Task 1.1) — fires a real
  /// `SIMBOX_EVENT_DEVICE_CONNECTED` through the real event-callback
  /// path this class wires up in its constructor. Exists because
  /// `_handle`/`_bindings` are otherwise private to this file, so tests
  /// have no other way to exercise [_onNativeEvent] against a genuine
  /// native event rather than hand-calling private methods. Not part of
  /// the public modem API — do not call from production code.
  void debugRegisterDiscoveredDevice({
    required String serialNumber,
    String imei = '',
    String name = '',
    String dataPort = '',
    String audioPort = '',
  }) {
    final discovered = calloc<simbox_discovered_device_t>();
    try {
      _writeCString(discovered.ref.serial_number, serialNumber, 64);
      _writeCString(discovered.ref.imei, imei, 32);
      _writeCString(discovered.ref.dev_name, name, 64);
      _writeCString(discovered.ref.data_port, dataPort, 128);
      _writeCString(discovered.ref.audio_port, audioPort, 128);
      _bindings.simbox_device_register(_handle, discovered);
    } finally {
      calloc.free(discovered);
    }
  }

  static void _writeCString(Array<Char> array, String value, int maxLen) {
    final codeUnits = value.codeUnits;
    final writable = codeUnits.length < maxLen ? codeUnits.length : maxLen - 1;
    for (var i = 0; i < writable; i++) {
      array[i] = codeUnits[i];
    }
    array[writable] = 0;
  }
}
