import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm_platform_interface.dart';
import 'package:flutter_gsm/src/linux/linux_flutter_gsm.dart';
import 'package:flutter_gsm/src/linux/simbox_modem_repository.dart';
import 'package:flutter_gsm/src/domain/exceptions/modem_exceptions.dart';
import 'package:flutter_gsm/src/domain/models/network_mode.dart';

/// `LinuxFlutterGsm` is a thin one-to-one delegation layer onto
/// [SimboxModemRepository] (see that class's own test file for the real
/// behavior being delegated to) — these tests exercise the delegation
/// itself, injecting a real `SimboxModemRepository` via the constructor's
/// test-only seam rather than hitting `libsimbox` through the default
/// lazy path. Skips (doesn't fail) if `libsimbox` isn't built/
/// discoverable in the current environment, same as
/// `simbox_modem_repository_test.dart`.
void main() {
  SimboxModemRepository? tryCreateRepository() {
    try {
      return SimboxModemRepository();
    } on ModemDriverNotAvailableException {
      return null;
    }
  }

  Future<void> withPlatform(
    Future<void> Function(LinuxFlutterGsm platform) body,
  ) async {
    final repository = tryCreateRepository();
    if (repository == null) {
      markTestSkipped('libsimbox not built/discoverable in this environment');
      return;
    }
    addTearDown(repository.dispose);
    await body(LinuxFlutterGsm(repository: repository));
  }

  test('registerWith() sets LinuxFlutterGsm as the platform instance', () {
    LinuxFlutterGsm.registerWith();

    expect(FlutterGsmPlatform.instance, isA<LinuxFlutterGsm>());
  });

  test('listModems() delegates to SimboxModemRepository', () {
    return withPlatform((platform) async {
      final modems = await platform.listModems();
      expect(modems, isEmpty);
    });
  });

  test('dial() delegates and surfaces ModemNotFoundException for an unknown modem', () {
    return withPlatform((platform) async {
      expect(
        () => platform.dial('NO_SUCH_MODEM', '+1234567890'),
        throwsA(isA<ModemNotFoundException>()),
      );
    });
  });

  test('setNetworkMode(auto) delegates and surfaces UnsupportedError', () {
    return withPlatform((platform) async {
      expect(
        () => platform.setNetworkMode('NO_SUCH_MODEM', NetworkMode.auto),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  test(
    'modemEvents does not throw when libsimbox is unavailable (default lazy path)',
    () async {
      // Deliberately not using withPlatform()/an injected repository —
      // this exercises the *default* constructor's lazy-init path with
      // no libsimbox guarantee either way, matching modemEvents' "must
      // not throw" contract (FlutterGsmPlatform's doc comment)
      // regardless of driver availability.
      final platform = LinuxFlutterGsm();
      final events = await platform.modemEvents.timeout(
        const Duration(milliseconds: 50),
        onTimeout: (sink) => sink.close(),
      ).toList();
      expect(events, isEmpty);
    },
  );
}
