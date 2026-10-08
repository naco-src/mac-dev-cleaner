import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:mac_dev_cleaner_core/src/platform/linux/linux_paths.dart';
import 'package:test/test.dart';

void main() {
  test('LinuxHostPaths resolves Android SDK from env', () {
    final paths = LinuxHostPaths(
      home: '/home/dev',
      environment: {
        'HOME': '/home/dev',
        'ANDROID_SDK_ROOT': '/opt/android-sdk',
      },
    );
    expect(paths.androidSdk, '/opt/android-sdk');
    expect(paths.trash, '/home/dev/.local/share/Trash/files');
    expect(paths.configHome, '/home/dev/.config');
  });

  test('LinuxHostPaths expandUser', () {
    final paths = LinuxHostPaths(
      home: '/home/dev',
      environment: {'HOME': '/home/dev'},
    );
    expect(paths.expandUser('~/Projects/foo'), '/home/dev/Projects/foo');
    expect(paths.expandUser('~'), '/home/dev');
  });

  test('HostPlatform.linux is supported', () {
    expect(HostPlatform.linux.isSupported, isTrue);
    expect(HostPlatform.windows.isSupported, isFalse);
  });
}
