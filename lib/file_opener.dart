import 'file_opener_platform_interface.dart';

class FileOpener {
  Future<String?> getPlatformVersion() {
    return FileOpenerPlatform.instance.getPlatformVersion();
  }

  Future<void> openFile(String path) {
    return FileOpenerPlatform.instance.openFile(path);
  }
}
