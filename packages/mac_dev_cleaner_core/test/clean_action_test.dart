import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:test/test.dart';

void main() {
  group('CleanAction.copyableCommand', () {
    test('prefers commandDescription', () {
      const action = CleanAction(
        method: CleanMethod.runCommand,
        command: ['brew', 'cleanup', '-s'],
        commandDescription: 'brew cleanup -s',
      );
      expect(action.copyableCommand, 'brew cleanup -s');
    });

    test('falls back to joined argv', () {
      const action = CleanAction(
        method: CleanMethod.runCommand,
        command: ['xcrun', 'simctl', 'delete', 'unavailable'],
      );
      expect(action.copyableCommand, 'xcrun simctl delete unavailable');
    });

    test('null for moveToTrash without description', () {
      const action = CleanAction(
        method: CleanMethod.moveToTrash,
        paths: ['/tmp/foo'],
      );
      expect(action.copyableCommand, isNull);
    });
  });
}
