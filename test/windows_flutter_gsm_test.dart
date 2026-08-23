import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm_platform_interface.dart';
import 'package:flutter_gsm/src/windows/windows_flutter_gsm.dart';

void main() {
  test('registerWith() sets WindowsFlutterGsm as the platform instance', () {
    WindowsFlutterGsm.registerWith();

    expect(FlutterGsmPlatform.instance, isA<WindowsFlutterGsm>());
  });

  test('modem methods throw UnimplementedError pointing at the channel flow', () {
    final platform = WindowsFlutterGsm();

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
    final platform = WindowsFlutterGsm();

    final first = await platform.modemEvents.toList();
    final second = await platform.modemEvents.toList();

    expect(first, isEmpty);
    expect(second, isEmpty);
  });
}
