import '../models/enums.dart';
import '../models/plan.dart';
import '../models/scan_item.dart';

class Planner {
  CleanPlan buildPlan(
    List<ScanItem> items, {
    bool safeOnly = false,
    Set<String>? selectedIds,
  }) {
    final chosen = items.where((item) {
      if (!item.cleanable || item.sizeBytes <= 0) {
        return false;
      }
      if (selectedIds != null) {
        return selectedIds.contains(item.id);
      }
      if (safeOnly) {
        return item.risk == RiskLevel.safe && item.selectedByDefault;
      }
      return item.selectedByDefault;
    }).toList();

    final total = chosen.fold<int>(0, (sum, i) => sum + i.sizeBytes);
    return CleanPlan(items: chosen, totalBytes: total);
  }

  CleanPlan planForExplicitSelection(List<ScanItem> all, Set<String> ids) {
    return buildPlan(all, selectedIds: ids);
  }
}
