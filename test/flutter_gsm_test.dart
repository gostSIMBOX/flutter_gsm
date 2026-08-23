import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsm/flutter_gsm_platform_interface.dart';
import 'package:flutter_gsm/flutter_gsm_method_channel.dart';

void main() {
  test('$MethodChannelFlutterGsm is the default instance', () {
    expect(
      FlutterGsmPlatform.instance,
      isInstanceOf<MethodChannelFlutterGsm>(),
    );
  });
}
