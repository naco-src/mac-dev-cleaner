/// User-facing steps to remove or clean one scan item outside the app UI.
class DeletionGuide {
  const DeletionGuide({
    required this.summary,
    this.beforeYouStart = const [],
    this.steps = const [],
    this.notes = const [],
  });

  final String summary;
  final List<String> beforeYouStart;
  final List<DeletionGuideStep> steps;
  final List<String> notes;

  String get clipboardText {
    final buf = StringBuffer()..writeln(summary);
    if (beforeYouStart.isNotEmpty) {
      buf.writeln();
      buf.writeln('Before you start');
      for (final line in beforeYouStart) {
        buf.writeln('• $line');
      }
    }
    for (var i = 0; i < steps.length; i++) {
      buf.writeln();
      buf.writeln('${i + 1}. ${steps[i].title}');
      buf.writeln(steps[i].body);
      final copy = steps[i].copyText;
      if (copy != null && copy.isNotEmpty) {
        buf.writeln(copy);
      }
    }
    if (notes.isNotEmpty) {
      buf.writeln();
      buf.writeln('Notes');
      for (final note in notes) {
        buf.writeln('• $note');
      }
    }
    return buf.toString().trimRight();
  }
}

class DeletionGuideStep {
  const DeletionGuideStep({
    required this.title,
    required this.body,
    this.copyText,
  });

  final String title;
  final String body;
  final String? copyText;
}
