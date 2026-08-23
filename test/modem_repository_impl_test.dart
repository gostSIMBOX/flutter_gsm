import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm.dart';
import 'package:flutter_gsm/flutter_gsm_platform_interface.dart';

/// Platform stub that behaves like the Linux registration before
/// sdd-asterisk-chan-simbox lands: extending (not implementing)
/// [FlutterGsmPlatform] means every unoverridden modem method inherits
/// the base class's default `throw UnimplementedError(...)` body, matching
/// what a real stub platform (e.g. LinuxFlutterGsm) does today.
class _StubUnimplementedPlatform extends FlutterGsmPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('stub');
}

void main() {
  late ModemRepositoryImpl repository;

  setUp(() {
    repository = ModemRepositoryImpl(platform: _StubUnimplementedPlatform());
  });

  test('listModems() surfaces ModemDriverNotAvailableException, not UnimplementedError', () async {
    expect(
      () => repository.listModems(),
      throwsA(isA<ModemDriverNotAvailableException>()),
    );
  });

  test('modemEvents returns an empty stream instead of throwing', () async {
    final events = await repository.modemEvents.toList();
    expect(events, isEmpty);
  });
}
