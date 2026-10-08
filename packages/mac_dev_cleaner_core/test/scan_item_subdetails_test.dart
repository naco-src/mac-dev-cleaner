import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:test/test.dart';

void main() {
  test('subdetails from paths when no clean action', () {
    final item = ScanItem(
      id: 'report',
      name: 'Report',
      group: RuleGroup.macos,
      risk: RiskLevel.protected,
      explain: 'context',
      regenerates: RegeneratesKind.never,
      sizeBytes: 1,
      paths: ['/Users/me/Library/Foo'],
    );
    expect(item.subdetails, hasLength(1));
    expect(item.subdetails.first.value, '/Users/me/Library/Foo');
  });

  test('subdetails include per-path sizes from pathSizes', () {
    final item = ScanItem(
      id: 'multi',
      name: 'Multi',
      group: RuleGroup.xcode,
      risk: RiskLevel.safe,
      explain: 'explain',
      regenerates: RegeneratesKind.onNextBuild,
      sizeBytes: 300,
      paths: ['/a', '/b'],
      pathSizes: {'/a': 100, '/b': 200},
      cleanAction: const CleanAction(
        method: CleanMethod.moveToTrash,
        paths: ['/a', '/b'],
      ),
    );
    expect(item.subdetails[0].sizeBytes, 100);
    expect(item.subdetails[1].sizeBytes, 200);
  });
}
