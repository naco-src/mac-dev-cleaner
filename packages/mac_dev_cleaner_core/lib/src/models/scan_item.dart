import 'clean_action.dart';
import 'enums.dart';

class ScanItem {
  ScanItem({
    required this.id,
    required this.name,
    required this.group,
    required this.risk,
    required this.explain,
    required this.regenerates,
    required this.sizeBytes,
    this.paths = const [],
    this.cleanAction,
    this.preconditionHint,
    this.preconditionMet = true,
    this.selectedByDefault = false,
    this.detail,
  });

  final String id;
  final String name;
  final RuleGroup group;
  final RiskLevel risk;
  final String explain;
  final RegeneratesKind regenerates;
  final int sizeBytes;
  final List<String> paths;
  final CleanAction? cleanAction;
  final String? preconditionHint;
  final bool preconditionMet;
  final bool selectedByDefault;
  final String? detail;

  bool get cleanable =>
      cleanAction != null && risk != RiskLevel.protected && preconditionMet;

  ScanItem copyWith({
    int? sizeBytes,
    CleanAction? cleanAction,
    bool? preconditionMet,
    bool? selectedByDefault,
    String? detail,
    List<String>? paths,
  }) {
    return ScanItem(
      id: id,
      name: name,
      group: group,
      risk: risk,
      explain: explain,
      regenerates: regenerates,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      paths: paths ?? this.paths,
      cleanAction: cleanAction ?? this.cleanAction,
      preconditionHint: preconditionHint,
      preconditionMet: preconditionMet ?? this.preconditionMet,
      selectedByDefault: selectedByDefault ?? this.selectedByDefault,
      detail: detail ?? this.detail,
    );
  }
}
