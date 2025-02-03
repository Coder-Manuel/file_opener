import 'package:file_opener/src/models/open_result_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_opener/src/file_opener.dart';
import 'package:file_opener/src/platform/file_opener_platform_interface.dart';
import 'package:file_opener/src/platform/file_opener_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFileOpenerPlatform
    with MockPlatformInterfaceMixin
    implements FileOpenerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<OpenResult> openFile(String path) => Future.value(OpenResult());
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

  test('openFile', () async {
    MockFileOpenerPlatform fakePlatform = MockFileOpenerPlatform();
    FileOpenerPlatform.instance = fakePlatform;
    final result = await FileOpener.openFile('');

    expect(result.type, ResultType.done);
  });
}
