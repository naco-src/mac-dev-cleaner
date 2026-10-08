import 'package:flutter/foundation.dart';
import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

import '../isolate/scan_isolate.dart';

enum ScanPhase { idle, scanning, done, error }

class CleanerController extends ChangeNotifier {
  CleanerController({MacDevCleaner? cleaner, List<ScanItem>? initialItems})
    : _cleaner = cleaner ?? MacDevCleaner() {
    if (initialItems != null) {
      items = initialItems;
      scanPhase = ScanPhase.done;
    }
  }

  final MacDevCleaner _cleaner;

  ScanPhase scanPhase = ScanPhase.idle;
  String? scanError;
  List<ScanItem> items = [];
  DataVolumeSpace? diskSpace;

  final Set<String> selectedIds = {};
  RuleGroup? groupFilter;
  bool safeOnlyFilter = false;
  String searchQuery = '';

  List<DoctorIssue> doctorIssues = [];
  bool doctorLoading = false;

  List<Map<String, dynamic>> historyEntries = [];
  bool historyLoading = false;

  bool cleanInProgress = false;
  CleanResult? lastCleanResult;

  List<ScanItem> get visibleItems {
    var list = items;
    if (groupFilter != null) {
      list = list.where((i) => i.group == groupFilter).toList();
    }
    if (safeOnlyFilter) {
      list = list.where((i) => i.risk == RiskLevel.safe).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (i) =>
                i.name.toLowerCase().contains(q) ||
                i.id.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  CleanPlan get currentPlan {
    if (selectedIds.isEmpty) {
      return CleanPlan(items: [], totalBytes: 0);
    }
    return _cleaner.plan(items, selectedIds: selectedIds);
  }

  Future<void> refreshDiskSpace() async {
    diskSpace = await _cleaner.dataVolumeSpace();
    notifyListeners();
  }

  Future<void> runScan() async {
    scanPhase = ScanPhase.scanning;
    scanError = null;
    notifyListeners();
    try {
      items = await runScanOffMainThread();
      selectedIds.clear();
      for (final item in items) {
        if (item.cleanable && item.selectedByDefault && item.preconditionMet) {
          selectedIds.add(item.id);
        }
      }
      await refreshDiskSpace();
      scanPhase = ScanPhase.done;
    } catch (e, st) {
      scanError = e.toString();
      scanPhase = ScanPhase.error;
      if (kDebugMode) {
        // ignore: avoid_print
        print(st);
      }
    }
    notifyListeners();
  }

  void toggleSelection(String id, bool? value) {
    if (value == true) {
      selectedIds.add(id);
    } else {
      selectedIds.remove(id);
    }
    notifyListeners();
  }

  void selectAllVisible(bool selected) {
    for (final item in visibleItems) {
      if (!item.cleanable || !item.preconditionMet) {
        continue;
      }
      if (selected) {
        selectedIds.add(item.id);
      } else {
        selectedIds.remove(item.id);
      }
    }
    notifyListeners();
  }

  void setGroupFilter(RuleGroup? group) {
    groupFilter = group;
    notifyListeners();
  }

  void setSafeOnlyFilter(bool value) {
    safeOnlyFilter = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  Future<CleanResult> runClean({required bool permanentDelete}) async {
    final plan = currentPlan;
    cleanInProgress = true;
    lastCleanResult = null;
    notifyListeners();
    try {
      final result = await _cleaner.clean(
        plan,
        yes: true,
        permanentDelete: permanentDelete,
      );
      lastCleanResult = result;
      await refreshDiskSpace();
      await runScan();
      return result;
    } finally {
      cleanInProgress = false;
      notifyListeners();
    }
  }

  Future<void> loadDoctor() async {
    doctorLoading = true;
    notifyListeners();
    try {
      doctorIssues = await _cleaner.doctorCheck();
    } finally {
      doctorLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    historyLoading = true;
    notifyListeners();
    try {
      historyEntries = await _cleaner.history(limit: 50);
    } finally {
      historyLoading = false;
      notifyListeners();
    }
  }

  String get historyFilePath => _cleaner.paths.historyFile;
}
