import 'package:file_opener/src/models/open_result_model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'file_opener_method_channel.dart';

abstract class FileOpenerPlatform extends PlatformInterface {
  /// Constructs a FileOpenerPlatform.
  FileOpenerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FileOpenerPlatform _instance = MethodChannelFileOpener();

  /// The default instance of [FileOpenerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFileOpener].
  static FileOpenerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FileOpenerPlatform] when
  /// they register themselves.
  static set instance(FileOpenerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<OpenResult> openFile(String path) {
    throw UnimplementedError('openFile() has not been implemented.');
  }
}
