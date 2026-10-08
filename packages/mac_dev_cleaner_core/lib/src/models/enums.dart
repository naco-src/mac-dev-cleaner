enum RuleGroup {
  xcode('Xcode'),
  android('Android'),
  flutter('Flutter'),
  node('Node'),
  homebrew('Homebrew'),
  ide('IDE'),
  browser('Browser'),
  projects('Projects'),
  macos('macOS'),
  linux('Linux');

  const RuleGroup(this.label);
  final String label;
}

enum RiskLevel {
  safe('Safe'),
  conditional('Conditional'),
  protected('Protected');

  const RiskLevel(this.label);
  final String label;
}

enum CleanMethod {
  deleteContents,
  moveToTrash,
  runCommand,
}

enum RegeneratesKind {
  automatically('automatically'),
  onNextBuild('on next build'),
  reDownload('re-download'),
  never('never (user data)'),
  notApplicable('n/a');

  const RegeneratesKind(this.label);
  final String label;
}
