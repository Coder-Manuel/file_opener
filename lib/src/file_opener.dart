import 'package:file_opener/src/models/open_result_model.dart';

import 'platform/file_opener_platform_interface.dart';

class FileOpener {
  static Future<String?> getPlatformVersion() {
    return FileOpenerPlatform.instance.getPlatformVersion();
  }

  static Future<OpenResult> openFile(String path) {
    return FileOpenerPlatform.instance.openFile(path);
  }
}
