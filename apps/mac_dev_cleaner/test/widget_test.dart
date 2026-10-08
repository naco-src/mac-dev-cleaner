import 'package:flutter_test/flutter_test.dart';
import 'package:mac_dev_cleaner/app.dart';
import 'package:mac_dev_cleaner/controller/cleaner_controller.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

ScanItem _fakeItem({
  required String id,
  required RuleGroup group,
  int size = 1024,
}) {
  return ScanItem(
    id: id,
    name: 'Item $id',
    group: group,
    risk: RiskLevel.safe,
    explain: 'Test explain',
    regenerates: RegeneratesKind.automatically,
    sizeBytes: size,
    selectedByDefault: true,
    cleanAction: const CleanAction(
      method: CleanMethod.moveToTrash,
      paths: ['/tmp/test'],
    ),
  );
}

void main() {
  testWidgets('shows scan item from injected controller', (tester) async {
    final controller = CleanerController(
      initialItems: [_fakeItem(id: 'a', group: RuleGroup.macos)],
    );
    await tester.pumpWidget(MacDevCleanerApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Item a'), findsOneWidget);
  });

  testWidgets('treemap shows group labels', (tester) async {
    final controller = CleanerController(
      initialItems: [
        _fakeItem(id: 'x1', group: RuleGroup.xcode, size: 5000),
        _fakeItem(id: 'a1', group: RuleGroup.android, size: 3000),
      ],
    );
    await tester.pumpWidget(MacDevCleanerApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Treemap'));
    await tester.pumpAndSettle();

    expect(find.text('Xcode'), findsWidgets);
    expect(find.text('Android'), findsWidgets);
    expect(find.text('All groups'), findsOneWidget);
  });
}
