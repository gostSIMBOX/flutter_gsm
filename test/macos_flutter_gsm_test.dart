import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm_platform_interface.dart';
import 'package:flutter_gsm/src/macos/macos_flutter_gsm.dart';

void main() {
  test('registerWith() sets MacosFlutterGsm as the platform instance', () {
    MacosFlutterGsm.registerWith();

    expect(FlutterGsmPlatform.instance, isA<MacosFlutterGsm>());
  });

  test('modem methods throw UnimplementedError pointing at the channel flow', () {
    final platform = MacosFlutterGsm();

    expect(
      () => platform.listModems(),
      throwsA(
        isA<UnimplementedError>().having(
          (e) => e.message,
          'message',
          contains('sdd-asterisk-chan-simbox'),
        ),
      ),
    );
  });

  test('modemEvents is a safe, never-emitting broadcast stream', () async {
    final platform = MacosFlutterGsm();

    final first = await platform.modemEvents.toList();
    final second = await platform.modemEvents.toList();

    expect(first, isEmpty);
    expect(second, isEmpty);
  });
}
