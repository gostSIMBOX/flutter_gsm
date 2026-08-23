import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm_platform_interface.dart';
import 'package:flutter_gsm/src/android/android_flutter_gsm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const gsmChannel = MethodChannel('flutter_gsm');
  const dialerChannel = MethodChannel('flutter_dialer');
  const teleChannel = MethodChannel('flutter_tele');
  const teleEventChannel = MethodChannel('flutter_tele_events');
  const smsChannel = MethodChannel('flutter_smsussd');

  late AndroidFlutterGsm platform;

  setUp(() {
    platform = AndroidFlutterGsm();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gsmChannel, (call) async {
      switch (call.method) {
        case 'getPlatformVersion':
          return 'Android 14';
        case 'getActiveSims':
          return [
            {
              'slotIndex': 0,
              'subscriptionId': 1,
              'carrierName': 'Test Carrier',
              'displayName': 'SIM 1',
              'number': '+10000000000',
            },
          ];
        default:
          return null;
      }
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dialerChannel, (call) async {
      if (call.method == 'isDefaultDialer') return false;
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(teleChannel, (call) async => null);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(smsChannel, (call) async {
      if (call.method == 'sendSms') return true;
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(teleEventChannel.name, null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(gsmChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(dialerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(teleChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(smsChannel, null);
  });

  test('registerWith() sets AndroidFlutterGsm as the platform instance', () {
    AndroidFlutterGsm.registerWith();

    expect(FlutterGsmPlatform.instance, isA<AndroidFlutterGsm>());
  });

  test('getPlatformVersion delegates to the flutter_gsm channel', () async {
    expect(await platform.getPlatformVersion(), 'Android 14');
  });

  test('listModems() maps getActiveSims() results to ModemDevice', () async {
    final devices = await platform.listModems();

    expect(devices, hasLength(1));
    expect(devices.first.id, 'sim-0');
    expect(devices.first.displayName, 'SIM 1');
  });

  test('getModem() looks up by id from listModems()', () async {
    final device = await platform.getModem('sim-0');
    expect(device, isNotNull);
    expect(device!.id, 'sim-0');

    final missing = await platform.getModem('sim-99');
    expect(missing, isNull);
  });

  test('sendSms() delegates to flutter_smsussd', () async {
    await platform.sendSms('sim-0', '+10000000000', 'hello');
    // Completes without throwing == the mocked channel returned true.
  });

  test('AT-command/firmware methods are correctly unsupported on Android', () {
    expect(() => platform.sendAtCommand('sim-0', 'AT'), throwsUnsupportedError);
    expect(() => platform.setPower('sim-0', on: true), throwsUnsupportedError);
    expect(() => platform.changeImei('sim-0', '123'), throwsUnsupportedError);
    expect(() => platform.sendUssd('sim-0', '*100#'), throwsUnsupportedError);
  });

  test('hangupCall() requires default-dialer status', () async {
    // Mocked isDefaultDialer() returns false.
    await expectLater(
      platform.hangupCall('call-0'),
      throwsA(isA<Exception>()),
    );
  });
}
