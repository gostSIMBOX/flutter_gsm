import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_gsmsip_platform_interface.dart';

/// An implementation of [FlutterGsmsipPlatform] that uses method channels.
class MethodChannelFlutterGsmsip extends FlutterGsmsipPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_gsmsip');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
