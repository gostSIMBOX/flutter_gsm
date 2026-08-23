import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/src/linux/simbox_modem_repository.dart';
import 'package:flutter_gsm/src/domain/exceptions/modem_exceptions.dart';
import 'package:flutter_gsm/src/domain/models/modem_event.dart';
import 'package:flutter_gsm/src/domain/models/network_mode.dart';
import 'package:flutter_gsm/src/domain/models/restart_mode.dart';

/// Exercises `SimboxModemRepository` against the real `libsimbox`
/// (loaded via the default env-var/monorepo-relative fallback chain —
/// see `simbox_native_library.dart`), relying only on the deterministic
/// "no devices registered yet" baseline state `libsimbox`'s own
/// `tests/test_simbox.c` (`test_lifecycle`) already asserts, plus
/// `debugRegisterDiscoveredDevice` (a test-only hook onto the real
/// `simbox_device_register` native call, see that method's doc comment)
/// for event-dispatch tests — not on any real hardware being attached.
/// Skips (doesn't fail) if `libsimbox` isn't built/discoverable in the
/// current environment, matching this task's plan note.
void main() {
  SimboxModemRepository? tryCreate() {
    try {
      return SimboxModemRepository();
    } on ModemDriverNotAvailableException {
      return null;
    }
  }

  /// Runs [body] with a fresh repo, skipping (not failing) the test if
  /// `libsimbox` isn't available. Centralizes the skip boilerplate every
  /// test below would otherwise repeat.
  Future<void> withRepo(Future<void> Function(SimboxModemRepository) body) async {
    final repo = tryCreate();
    if (repo == null) {
      markTestSkipped('libsimbox not built/discoverable in this environment');
      return;
    }
    addTearDown(repo.dispose);
    await body(repo);
  }

  // sdd-simbox-app-real-driver: proves the `configDir` plumbing doesn't
  // break construction/basic operation. Honestly scoped per that
  // flow's specifications — this only shows the plumbing is harmless
  // on this non-Linux/simulated dev machine (config-driven device
  // population is gated behind #ifdef __linux__ natively, so a
  // configDir has zero observable effect here either way); it does
  // NOT prove real chan_dongle discovery works, which needs a real
  // Linux host with hardware attached — see that flow's Constraints.
  test('SimboxModemRepository(configDir: ...) constructs and works normally', () {
    final tempDir = Directory.systemTemp.createTempSync('simbox_configdir_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    SimboxModemRepository repo;
    try {
      repo = SimboxModemRepository(configDir: tempDir.path);
    } on ModemDriverNotAvailableException {
      markTestSkipped('libsimbox not built/discoverable in this environment');
      return Future<void>.value();
    }
    addTearDown(repo.dispose);
    return repo.listModems().then((modems) => expect(modems, isEmpty));
  });

  test('listModems() returns empty list against a fresh libsimbox instance', () {
    return withRepo((repo) async {
      final modems = await repo.listModems();
      expect(modems, isEmpty);
    });
  });

  test('getModem() returns null for an unknown serial', () {
    return withRepo((repo) async {
      await repo.listModems();
      final modem = await repo.getModem('NO_SUCH_SERIAL');
      expect(modem, isNull);
    });
  });

  test('dispose() is idempotent — safe to call twice', () {
    // withRepo() already registers addTearDown(repo.dispose) — calling
    // it again here deliberately exercises the double-dispose path
    // (found the hard way: this used to SIGABRT before dispose() was
    // made idempotent, since simbox_shutdown()/NativeCallable.close()
    // aren't themselves safe to call twice on the same handle).
    return withRepo((repo) async {
      await repo.listModems();
      expect(repo.dispose, returnsNormally);
    });
  });

  test(
    'registering a device fires a real ModemAttached event and makes it listable',
    () {
      return withRepo((repo) async {
        final events = <ModemEvent>[];
        final sub = repo.modemEvents.listen(events.add);
        addTearDown(sub.cancel);

        repo.debugRegisterDiscoveredDevice(
          serialNumber: 'EVT_TEST_SN_001',
          dataPort: '/dev/ttyUSB0',
        );

        // The event callback fires asynchronously (NativeCallable.listener
        // hands off across the native->Dart boundary) — pump the event
        // loop until it arrives rather than asserting synchronously.
        await _pumpUntil(() => events.isNotEmpty);

        expect(events, hasLength(1));
        final event = events.single;
        expect(event, isA<ModemAttached>());
        expect(event.modemId, 'EVT_TEST_SN_001');
        expect(
          (event as ModemAttached).device.portPath,
          '/dev/ttyUSB0',
        );

        final modems = await repo.listModems();
        expect(modems.map((m) => m.id), contains('EVT_TEST_SN_001'));
      });
    },
  );

  test('re-registering the same device does not fire a second event', () {
    return withRepo((repo) async {
      final events = <ModemEvent>[];
      final sub = repo.modemEvents.listen(events.add);
      addTearDown(sub.cancel);

      repo.debugRegisterDiscoveredDevice(serialNumber: 'EVT_TEST_SN_002');
      await _pumpUntil(() => events.isNotEmpty);
      expect(events, hasLength(1));

      repo.debugRegisterDiscoveredDevice(serialNumber: 'EVT_TEST_SN_002');
      // Give a second event a chance to arrive if (incorrectly) fired.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(events, hasLength(1));
    });
  });

  test('dial() succeeds against a registered device and tracks the call', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'CALL_TEST_SN_001');
      await repo.listModems();

      final call = await repo.dial('CALL_TEST_SN_001', '+1234567890');
      expect(call.id, 'CALL_TEST_SN_001');
      expect(call.modemId, 'CALL_TEST_SN_001');
      expect(call.number, '+1234567890');
    });
  });

  test('dial() against an unknown modemId throws ModemNotFoundException', () {
    return withRepo((repo) async {
      expect(
        () => repo.dial('NO_SUCH_MODEM', '+1234567890'),
        throwsA(isA<ModemNotFoundException>()),
      );
    });
  });

  test('answerCall() then hangupCall() complete without error', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'CALL_TEST_SN_002');
      await repo.listModems();
      await repo.dial('CALL_TEST_SN_002', '+1234567890');

      await expectLater(repo.answerCall('CALL_TEST_SN_002'), completes);
      await expectLater(repo.hangupCall('CALL_TEST_SN_002'), completes);
    });
  });

  test('hangupCall() against an unknown callId throws ModemNotFoundException', () {
    return withRepo((repo) async {
      expect(
        () => repo.hangupCall('NO_SUCH_CALL'),
        throwsA(isA<ModemNotFoundException>()),
      );
    });
  });

  test('sendSms() completes against a registered device', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'SMS_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.sendSms('SMS_TEST_SN_001', '+1234567890', 'hello'),
        completes,
      );
    });
  });

  // simbox's non-Linux (simulated) `simbox_ussd_send` never fires
  // `SIMBOX_EVENT_USSD_RESPONSE` (that only happens for real
  // BUILD_MANAGER-driven devices on Linux — see
  // sdd-asterisk-chan-simbox's Task 5.8), so on this dev machine
  // sendUssd() is expected to time out waiting for a response that
  // never arrives — this is the "simulated-timeout case" called out by
  // this task's own verification note in 03-plan.md.
  test('sendUssd() times out when no response event arrives (simulated path)', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'USSD_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.sendUssd(
          'USSD_TEST_SN_001',
          '*100#',
          timeout: const Duration(milliseconds: 200),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  test('sendAtCommand() succeeds against a registered device', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'AT_TEST_SN_001');
      await repo.listModems();
      final result = await repo.sendAtCommand('AT_TEST_SN_001', 'AT+CSQ');
      expect(result.ok, isTrue);
      expect(result.raw, contains('OK'));
    });
  });

  // Task 4.1's threading design (specifications' "Threading") wraps every
  // blocking native call in Isolate.run so it can't freeze this
  // isolate's event loop. A Timer-tick-counting version of this test was
  // tried and dropped: on the non-Linux/simulated path exercised here,
  // simbox_at_command returns fast enough that a real OS Timer
  // (coarser-grained than Dart's microtask queue) sometimes doesn't fire
  // even once before it returns regardless of which isolate ran the
  // call — flaky, not a meaningful signal at this call's actual speed.
  // Verified instead via a standalone repro (spawn Isolate.run, pass a
  // calloc'd buffer's raw address across, call simbox_at_command from
  // the spawned isolate, read the result back from the original one)
  // confirming cross-isolate native writes are visible as expected —
  // see flows/sdd-flutter_gsm-ffi/04-implementation-log.md Task 4.1.

  test('changeImei() succeeds on the simulated (non-Linux) path', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'IMEI_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.changeImei('IMEI_TEST_SN_001', '123456789012345'),
        completes,
      );
      final modem = await repo.getModem('IMEI_TEST_SN_001');
      expect(modem?.imei, '123456789012345');
    });
  });

  test('setDiagMode(false) throws UnsupportedError', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'DIAG_TEST_SN_001');
      await repo.listModems();
      expect(
        () => repo.setDiagMode('DIAG_TEST_SN_001', false),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  test('setDiagMode(true) against a device with no tty port throws ModemException', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'DIAG_TEST_SN_002');
      await repo.listModems();
      expect(
        () => repo.setDiagMode('DIAG_TEST_SN_002', true),
        throwsA(isA<ModemException>()),
      );
    });
  });

  test('setPower() completes against a registered device', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'POWER_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.setPower('POWER_TEST_SN_001', on: true),
        completes,
      );
    });
  });

  test('restartModem() with no active call completes immediately', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'RESTART_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.restartModem('RESTART_TEST_SN_001', mode: RestartMode.graceful),
        completes,
      );
    });
  });

  test('setNetworkMode(gsmOnly) completes against a registered device', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'NETMODE_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.setNetworkMode('NETMODE_TEST_SN_001', NetworkMode.gsmOnly),
        completes,
      );
    });
  });

  test('setNetworkMode(auto) throws UnsupportedError (unconfirmed AT^SYSCFG code)', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'NETMODE_TEST_SN_002');
      await repo.listModems();
      expect(
        () => repo.setNetworkMode('NETMODE_TEST_SN_002', NetworkMode.auto),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  test('setGroup() stores group id for a known device', () {
    return withRepo((repo) async {
      repo.debugRegisterDiscoveredDevice(serialNumber: 'GROUP_TEST_SN_001');
      await repo.listModems();
      await expectLater(
        repo.setGroup('GROUP_TEST_SN_001', 'group-a'),
        completes,
      );
    });
  });

  test('setGroup() against an unknown modemId throws ModemNotFoundException', () {
    return withRepo((repo) async {
      expect(
        () => repo.setGroup('NO_SUCH_MODEM', 'group-a'),
        throwsA(isA<ModemNotFoundException>()),
      );
    });
  });
}

Future<void> _pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
