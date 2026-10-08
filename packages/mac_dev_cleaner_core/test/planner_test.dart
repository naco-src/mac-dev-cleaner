import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:test/test.dart';

ScanItem _item({required String id, required RiskLevel risk, bool selected = true}) {
  return ScanItem(
    id: id,
    name: id,
    group: RuleGroup.macos,
    risk: risk,
    explain: 'test',
    regenerates: RegeneratesKind.automatically,
    sizeBytes: 1000,
    selectedByDefault: selected,
    cleanAction: const CleanAction(method: CleanMethod.moveToTrash, paths: ['/tmp/x']),
  );
}

void main() {
  test('plan safe only', () {
    final planner = Planner();
    final plan = planner.buildPlan(
      [
        _item(id: 'a', risk: RiskLevel.safe),
        _item(id: 'b', risk: RiskLevel.conditional),
      ],
      safeOnly: true,
    );
    expect(plan.items.map((e) => e.id), ['a']);
  });

  test('plan explicit ids', () {
    final planner = Planner();
    final plan = planner.buildPlan(
      [
        _item(id: 'a', risk: RiskLevel.safe),
        _item(id: 'b', risk: RiskLevel.conditional, selected: false),
      ],
      selectedIds: {'b'},
    );
    expect(plan.items.single.id, 'b');
  });
}
