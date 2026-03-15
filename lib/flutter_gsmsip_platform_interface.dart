import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_gsmsip_method_channel.dart';

abstract class FlutterGsmsipPlatform extends PlatformInterface {
  /// Constructs a FlutterGsmsipPlatform.
  FlutterGsmsipPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterGsmsipPlatform _instance = MethodChannelFlutterGsmsip();

  /// The default instance of [FlutterGsmsipPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterGsmsip].
  static FlutterGsmsipPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterGsmsipPlatform] when
  /// they register themselves.
  static set instance(FlutterGsmsipPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
