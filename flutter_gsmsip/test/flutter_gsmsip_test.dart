import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gsmsip/flutter_gsmsip.dart';
import 'package:flutter_gsmsip/flutter_gsmsip_platform_interface.dart';
import 'package:flutter_gsmsip/flutter_gsmsip_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterGsmsipPlatform
    with MockPlatformInterfaceMixin
    implements FlutterGsmsipPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterGsmsipPlatform initialPlatform = FlutterGsmsipPlatform.instance;

  test('$MethodChannelFlutterGsmsip is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterGsmsip>());
  });

  test('getPlatformVersion', () async {
    FlutterGsmsip flutterGsmsipPlugin = FlutterGsmsip();
    MockFlutterGsmsipPlatform fakePlatform = MockFlutterGsmsipPlatform();
    FlutterGsmsipPlatform.instance = fakePlatform;

    expect(await flutterGsmsipPlugin.getPlatformVersion(), '42');
  });
}
