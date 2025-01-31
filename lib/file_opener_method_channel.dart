import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_opener_platform_interface.dart';

/// An implementation of [FileOpenerPlatform] that uses method channels.
class MethodChannelFileOpener extends FileOpenerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('file_opener');

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<void> openFile(String path) {
    return methodChannel.invokeMethod('openFile', {'path': path});
  }
}
