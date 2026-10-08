import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:test/test.dart';

ScanItem _item(CleanAction action, {List<String> paths = const []}) {
  return ScanItem(
    id: 'test',
    name: 'Test item',
    group: RuleGroup.android,
    risk: RiskLevel.conditional,
    explain: 'explain',
    regenerates: RegeneratesKind.reDownload,
    sizeBytes: 100,
    paths: paths,
    cleanAction: action,
  );
}

void main() {
  group('copyCommandPartsFor', () {
    test('single runCommand yields one part', () {
      final item = _item(
        const CleanAction(
          method: CleanMethod.runCommand,
          command: ['brew', 'cleanup', '-s'],
          commandDescription: 'brew cleanup -s',
        ),
      );
      expect(item.copyCommandParts, hasLength(1));
      expect(item.copyCommandParts.first.command, 'brew cleanup -s');
    });

    test('sdkmanager multi-uninstall yields one part per package', () {
      final item = _item(
        const CleanAction(
          method: CleanMethod.runCommand,
          command: ['/sdkmanager', '--uninstall', 'ndk;21.0.0', 'ndk;23.0.0'],
          commandDescription: 'ignored when argv has multiple packages',
        ),
        paths: ['/sdk/ndk/21.0.0', '/sdk/ndk/23.0.0'],
      );
      final parts = item.copyCommandParts;
      expect(parts, hasLength(2));
      expect(parts[0].label, 'NDK 21.0.0');
      expect(parts[0].command, '/sdkmanager --uninstall "ndk;21.0.0"');
      expect(parts[1].command, contains('23.0.0'));
    });

    test('multi-path trash yields one part per path', () {
      final item = _item(
        const CleanAction(
          method: CleanMethod.moveToTrash,
          paths: ['/a/foo', '/b/bar'],
        ),
        paths: ['/a/foo', '/b/bar'],
      );
      expect(item.copyCommandParts, hasLength(2));
      expect(item.copyCommandParts.map((p) => p.command), ['/a/foo', '/b/bar']);
    });
  });
}
