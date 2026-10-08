import 'host_platform.dart';

/// Cross-platform paths for config, dev tool caches, and project discovery.
abstract class HostPaths {
  HostPlatform get platform;

  String get home;

  String get mdcDir;

  String get historyFile;

  /// Recycle location (Trash, etc.) when [CleanMethod.moveToTrash] is used.
  String get trash;

  String get gradleHome;

  String get pubCache;

  String get npmCache;

  String get androidSdk;

  String get androidHome;

  String? get sdkmanagerBin;

  List<String> projectRoots();

  String expandUser(String path);
}
