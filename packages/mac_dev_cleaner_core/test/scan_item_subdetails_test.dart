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
}
