import 'scan_item.dart';

class CleanPlan {
  CleanPlan({required this.items, required this.totalBytes});

  final List<ScanItem> items;
  final int totalBytes;
}

class CleanResult {
  CleanResult({
    required this.succeeded,
    required this.failed,
    required this.bytesReclaimedEstimate,
  });

  final List<CleanResultEntry> succeeded;
  final List<CleanResultEntry> failed;
  final int bytesReclaimedEstimate;
}

class CleanResultEntry {
  CleanResultEntry({
    required this.itemId,
    required this.message,
    this.bytes = 0,
  });

  final String itemId;
  final String message;
  final int bytes;
}
