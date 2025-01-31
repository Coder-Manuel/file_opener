import 'file_opener_platform_interface.dart';

class FileOpener {
  static Future<String?> getPlatformVersion() {
    return FileOpenerPlatform.instance.getPlatformVersion();
  }

  static Future<void> openFile(String path) {
    return FileOpenerPlatform.instance.openFile(path);
  }
}
