import 'package:flutter_test/flutter_test.dart';
import 'package:file_opener/file_opener.dart';
import 'package:file_opener/file_opener_platform_interface.dart';
import 'package:file_opener/file_opener_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFileOpenerPlatform
    with MockPlatformInterfaceMixin
    implements FileOpenerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<void> openFile(String path) => Future.value();
}

void main() {
  final FileOpenerPlatform initialPlatform = FileOpenerPlatform.instance;

  test('$MethodChannelFileOpener is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFileOpener>());
  });

  test('getPlatformVersion', () async {
    MockFileOpenerPlatform fakePlatform = MockFileOpenerPlatform();
    FileOpenerPlatform.instance = fakePlatform;

    expect(await FileOpener.getPlatformVersion(), '42');
  });
}
