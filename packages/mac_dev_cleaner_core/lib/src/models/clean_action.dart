import 'enums.dart';

/// What the executor should do for one scannable item.
class CleanAction {
  const CleanAction({
    required this.method,
    this.paths = const [],
    this.command,
    this.commandDescription,
  }) : assert(
          method != CleanMethod.runCommand || command != null,
          'runCommand requires command',
        );

  final CleanMethod method;
  final List<String> paths;
  final List<String>? command;
  final String? commandDescription;

  CleanAction copyWith({
    CleanMethod? method,
    List<String>? paths,
    List<String>? command,
    String? commandDescription,
  }) {
    return CleanAction(
      method: method ?? this.method,
      paths: paths ?? this.paths,
      command: command ?? this.command,
      commandDescription: commandDescription ?? this.commandDescription,
    );
  }
}
