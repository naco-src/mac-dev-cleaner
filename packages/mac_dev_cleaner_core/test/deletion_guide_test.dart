import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:test/test.dart';

void main() {
  test('protected item explains report-only', () {
    final item = ScanItem(
      id: 'p',
      name: 'SDK total',
      group: RuleGroup.macos,
      risk: RiskLevel.protected,
      explain: 'context',
      regenerates: RegeneratesKind.never,
      sizeBytes: 1,
    );
    final guide = item.deletionGuide;
    expect(guide.summary, contains('report-only'));
    expect(guide.clipboardText, contains('SDK total'));
  });

  test('runCommand includes terminal step', () {
    final item = ScanItem(
      id: 'brew',
      name: 'Homebrew cleanup',
      group: RuleGroup.homebrew,
      risk: RiskLevel.safe,
      explain: 'old kegs',
      regenerates: RegeneratesKind.notApplicable,
      sizeBytes: 100,
      cleanAction: const CleanAction(
        method: CleanMethod.runCommand,
        command: ['brew', 'cleanup', '-s'],
        commandDescription: 'brew cleanup -s',
      ),
    );
    final guide = item.deletionGuide;
    expect(guide.steps.any((s) => s.title.contains('Terminal')), isTrue);
    expect(guide.clipboardText, contains('brew cleanup -s'));
  });

  test('moveToTrash lists paths for manual step', () {
    final item = ScanItem(
      id: 'gradle',
      name: 'Gradle caches',
      group: RuleGroup.android,
      risk: RiskLevel.safe,
      explain: 'cache',
      regenerates: RegeneratesKind.onNextBuild,
      sizeBytes: 50,
      paths: ['/tmp/gradle/caches'],
      cleanAction: const CleanAction(
        method: CleanMethod.moveToTrash,
        paths: ['/tmp/gradle/caches'],
      ),
    );
    final guide = item.deletionGuide;
    expect(
      guide.steps.singleWhere((s) => s.title == 'Manually').copyText,
      '/tmp/gradle/caches',
    );
  });
}
