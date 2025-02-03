import 'dart:convert';

import 'package:file_opener/src/models/open_result_model.dart';
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
  Future<OpenResult> openFile(
    String path, {
    String? type,
    String? uti,
  }) async {
    final result = await methodChannel.invokeMethod('openFile', {
      'path': path,
      "type": type,
      "uti": uti,
    });
    final resultMap = json.decode(result) as Map<String, dynamic>;
    return OpenResult.fromJson(resultMap);
  }
}
