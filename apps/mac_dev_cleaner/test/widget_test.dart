import 'package:flutter_test/flutter_test.dart';
import 'package:mac_dev_cleaner/app.dart';
import 'package:mac_dev_cleaner/controller/cleaner_controller.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

ScanItem _fakeItem() {
  return ScanItem(
    id: 'test-item',
    name: 'Test cache',
    group: RuleGroup.macos,
    risk: RiskLevel.safe,
    explain: 'Test explain',
    regenerates: RegeneratesKind.automatically,
    sizeBytes: 1024,
    selectedByDefault: true,
    cleanAction: const CleanAction(
      method: CleanMethod.moveToTrash,
      paths: ['/tmp/test'],
    ),
  );
}

void main() {
  testWidgets('shows scan item from injected controller', (tester) async {
    final controller = CleanerController(initialItems: [_fakeItem()]);
    await tester.pumpWidget(MacDevCleanerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Test cache'), findsOneWidget);
    expect(
      find.text('Tap Scan to find reclaimable developer caches.'),
      findsNothing,
    );
  });
}
