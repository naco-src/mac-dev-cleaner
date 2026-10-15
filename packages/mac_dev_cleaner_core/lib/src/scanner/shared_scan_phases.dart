import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../analyzer/android_avd.dart';
import '../analyzer/project_refs.dart';
import '../doctor/npm_checks.dart';
import '../io/process_runner.dart';
import '../models/clean_action.dart';
import '../models/enums.dart';
import '../models/scan_item.dart';
import '../platform/host_paths.dart';
import '../util/parallel.dart';
import 'size_scanner.dart';

/// Scan rules shared by macOS and Linux [ScanEngine] implementations.
class SharedScanPhases {
  SharedScanPhases({
    required this.fileSystem,
    required this.commandRunner,
    required this.paths,
    required this.sizes,
    required this.scanConcurrency,
  });

  final FileSystem fileSystem;
  final ProcessRunner commandRunner;
  final HostPaths paths;
  final SizeScanner sizes;
  final int scanConcurrency;

  Future<List<ScanItem>> packageManagersGradleAndAndroidCache() async {
    final items = <ScanItem>[];

    final npmOk = await isNpmCacheUsable(commandRunner, paths);
    final npmSize = await sizes.directorySize(paths.npmCache);
    items.add(
      ScanItem(
        id: 'npm-cache',
        name: 'npm cache',
        group: RuleGroup.node,
        risk: RiskLevel.safe,
        explain: 'Cached package tarballs; re-downloaded on install.',
        regenerates: RegeneratesKind.reDownload,
        sizeBytes: npmSize,
        paths: [paths.npmCache],
        pathSizes: {paths.npmCache: npmSize},
        selectedByDefault: npmOk && npmSize > 0,
        preconditionMet: npmOk,
        preconditionHint: npmOk
            ? null
            : 'Fix ownership first (see mdc doctor); npm cache clean may fail.',
        cleanAction: const CleanAction(
          method: CleanMethod.runCommand,
          command: ['npm', 'cache', 'clean', '--force'],
          commandDescription: 'npm cache clean --force',
        ),
      ),
    );

    final pnpmStores = [
      p.join(paths.home, '.local', 'share', 'pnpm', 'store'),
      p.join(paths.home, 'Library', 'pnpm', 'store'),
      p.join(paths.home, '.pnpm-store'),
    ];
    final yarnCaches = [
      p.join(paths.home, '.cache', 'yarn'),
      p.join(paths.home, 'Library', 'Caches', 'Yarn'),
      p.join(paths.home, '.yarn', 'berry', 'cache'),
    ];
    for (final (tool, args, candidates) in [
      ('pnpm', ['store', 'path'], pnpmStores),
      ('yarn', ['cache', 'dir'], yarnCaches),
    ]) {
      final result = await commandRunner.run(tool, args);
      final reported = result.success ? result.stdout.trim() : '';
      candidates
        ..clear()
        ..addAll(reported.isEmpty ? const <String>[] : [reported]);
    }
    final existingPnpmStores = pnpmStores
        .where((path) => fileSystem.directory(path).existsSync())
        .toSet()
        .toList();
    final existingYarnCaches = yarnCaches
        .where((path) => fileSystem.directory(path).existsSync())
        .toSet()
        .toList();
    for (final entry in [
      ('pnpm-store', 'pnpm', ['store', 'prune'], existingPnpmStores),
      ('yarn-cache', 'yarn', ['cache', 'clean'], existingYarnCaches),
    ]) {
      final breakdown = await sizes.pathBreakdown(entry.$4);
      final size = breakdown.totalBytes;
      items.add(
        ScanItem(
          id: entry.$1,
          name: entry.$2 == 'pnpm' ? 'pnpm store' : 'Yarn cache',
          group: RuleGroup.node,
          risk: RiskLevel.safe,
          explain: 'Package manager cache (if installed).',
          regenerates: RegeneratesKind.reDownload,
          sizeBytes: size,
          paths: size > 0 ? entry.$4 : const [],
          pathSizes: breakdown.byPath,
          selectedByDefault: size > 0,
          cleanAction: CleanAction(
            method: CleanMethod.runCommand,
            command: [entry.$2, ...entry.$3],
            commandDescription: '${entry.$2} ${entry.$3.join(' ')}',
          ),
        ),
      );
    }

    final gradlePaths = [
      p.join(paths.gradleHome, 'caches'),
      p.join(paths.gradleHome, 'daemon'),
    ];
    final gradleSizes = await mapConcurrent(
      gradlePaths,
      (gradlePath) async => (gradlePath, await sizes.directorySize(gradlePath)),
      concurrency: scanConcurrency,
    );
    for (final (gradlePath, size) in gradleSizes) {
      if (size > 0) {
        items.add(
          ScanItem(
            id: 'gradle-${p.basename(gradlePath)}',
            name: 'Gradle ${p.basename(gradlePath)}',
            group: RuleGroup.android,
            risk: RiskLevel.safe,
            explain: 'Gradle download and daemon caches; rebuilt on next sync.',
            regenerates: RegeneratesKind.onNextBuild,
            sizeBytes: size,
            paths: [gradlePath],
            pathSizes: {gradlePath: size},
            selectedByDefault: true,
            cleanAction: CleanAction(
              method: CleanMethod.moveToTrash,
              paths: [gradlePath],
            ),
          ),
        );
      }
    }

    final androidBuildCache = p.join(paths.androidHome, 'build-cache');
    final abcSize = await sizes.directorySize(androidBuildCache);
    if (abcSize > 0) {
      items.add(
        ScanItem(
          id: 'android-build-cache',
          name: 'Android build cache',
          group: RuleGroup.android,
          risk: RiskLevel.safe,
          explain: 'Legacy Android build cache under ~/.android.',
          regenerates: RegeneratesKind.onNextBuild,
          sizeBytes: abcSize,
          paths: [androidBuildCache],
          pathSizes: {androidBuildCache: abcSize},
          selectedByDefault: true,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: [androidBuildCache],
          ),
        ),
      );
    }

    return items;
  }

  Future<List<ScanItem>> homebrewCleanupIfAvailable() async {
    final which = await commandRunner.run('which', ['brew']);
    if (!which.success || which.stdout.trim().isEmpty) {
      return [];
    }
    return [
      ScanItem(
        id: 'homebrew-cleanup',
        name: 'Homebrew old versions',
        group: RuleGroup.homebrew,
        risk: RiskLevel.safe,
        explain: 'Runs brew cleanup to remove outdated kegs and downloads.',
        regenerates: RegeneratesKind.notApplicable,
        sizeBytes: await _brewReclaimEstimate(),
        selectedByDefault: true,
        cleanAction: const CleanAction(
          method: CleanMethod.runCommand,
          command: ['brew', 'cleanup', '-s'],
          commandDescription: 'brew cleanup -s',
        ),
      ),
    ];
  }

  Future<List<ScanItem>> conditionalAndroid(ProjectRefSnapshot refs) async {
    final items = <ScanItem>[];
    final sdk = paths.androidSdk;
    final ndkRoot = p.join(sdk, 'ndk');
    if (fileSystem.directory(ndkRoot).existsSync() &&
        refs.ndkVersions.isNotEmpty) {
      final keep = refs.ndkVersions;
      final uninstall = <String>[];
      for (final entity in fileSystem.directory(ndkRoot).listSync()) {
        if (!fileSystem.isDirectorySync(entity.path)) {
          continue;
        }
        final ver = p.basename(entity.path);
        if (keep.contains(ver)) {
          continue;
        }
        uninstall.add(entity.path);
      }
      final breakdown = await sizes.pathBreakdown(uninstall);
      if (breakdown.totalBytes > 0) {
        final sdkmanager = paths.sdkmanagerBin ?? 'sdkmanager';
        final commands = uninstall
            .map((path) => '$sdkmanager --uninstall "ndk;${p.basename(path)}"')
            .join('; ');
        items.add(
          ScanItem(
            id: 'android-ndk-unused',
            name: 'Android NDK (not referenced by projects)',
            group: RuleGroup.android,
            risk: RiskLevel.conditional,
            explain: 'Keeps NDK versions from ndkVersion in Gradle files under project roots.',
            regenerates: RegeneratesKind.reDownload,
            sizeBytes: breakdown.totalBytes,
            paths: uninstall,
            pathSizes: breakdown.byPath,
            selectedByDefault: false,
            detail: keep.isEmpty
                ? 'No ndkVersion found in projects; review before deleting.'
                : 'Keeping: ${keep.join(', ')}',
            cleanAction: CleanAction(
              method: CleanMethod.runCommand,
              command: [
                sdkmanager,
                '--uninstall',
                ...uninstall.map((path) => 'ndk;${p.basename(path)}'),
              ],
              commandDescription: commands,
            ),
          ),
        );
      }
    }

    final sysImages = p.join(sdk, 'system-images');
    if (fileSystem.directory(sysImages).existsSync()) {
      final used = AndroidAvdAnalyzer(
        fileSystem,
        androidHome: paths.androidHome,
      ).usedSystemImageSysdirs();
      final unused = <String>[];
      for (final platform in fileSystem.directory(sysImages).listSync()) {
        if (!fileSystem.isDirectorySync(platform.path)) {
          continue;
        }
        for (final vendor in io.Directory(platform.path).listSync()) {
          if (vendor is! io.Directory) {
            continue;
          }
          for (final abi in io.Directory(vendor.path).listSync()) {
            if (abi is! io.Directory) {
              continue;
            }
            final rel = p.relative(abi.path, from: sdk).replaceAll('\\', '/');
            final isUsed = used.any((u) {
              final normalized = u
                  .replaceAll('\\', '/')
                  .replaceAll(RegExp(r'/+$'), '');
              return normalized == rel || rel.startsWith('$normalized/');
            });
            if (!isUsed) {
              unused.add(abi.path);
            }
          }
        }
      }
      final breakdown = await sizes.pathBreakdown(unused);
      if (breakdown.totalBytes > 0) {
        items.add(
          ScanItem(
            id: 'android-system-images-unused',
            name: 'Android system images (no AVD)',
            group: RuleGroup.android,
            risk: RiskLevel.conditional,
            explain: 'Images not referenced by any AVD config.ini.',
            regenerates: RegeneratesKind.reDownload,
            sizeBytes: breakdown.totalBytes,
            paths: unused,
            pathSizes: breakdown.byPath,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.runCommand,
              command: [
                paths.sdkmanagerBin ?? 'sdkmanager',
                '--uninstall',
                ...unused.map((path) => 'platforms;${p.basename(path)}'),
              ],
              commandDescription:
                  '${paths.sdkmanagerBin ?? 'sdkmanager'} --uninstall ${unused.map((path) => '"platforms;${p.basename(path)}"').join(' ')}',
            ),
          ),
        );
      }
    }

    // Platform/build-tools versions are safe candidates only when projects
    // reference a known compileSdk; retain all versions when indexing found none.
    final platforms = p.join(sdk, 'platforms');
    if (refs.compileSdks.isNotEmpty &&
        fileSystem.directory(platforms).existsSync()) {
      final unused = fileSystem
          .directory(platforms)
          .listSync()
          .where((e) => fileSystem.isDirectorySync(e.path))
          .where(
            (e) => !refs.compileSdks.contains(
              p.basename(e.path).replaceFirst('android-', ''),
            ),
          )
          .map((e) => e.path)
          .toList();
      final breakdown = await sizes.pathBreakdown(unused);
      if (breakdown.totalBytes > 0) {
        items.add(
          ScanItem(
            id: 'android-platforms-unused',
            name: 'Android platforms (not referenced)',
            group: RuleGroup.android,
            risk: RiskLevel.conditional,
            explain:
                'Android SDK platforms not referenced by indexed projects.',
            regenerates: RegeneratesKind.reDownload,
            sizeBytes: breakdown.totalBytes,
            paths: unused,
            pathSizes: breakdown.byPath,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.runCommand,
              command: [
                paths.sdkmanagerBin ?? 'sdkmanager',
                '--uninstall',
                ...unused.map((path) => 'platforms;${p.basename(path)}'),
              ],
              commandDescription:
                  '${paths.sdkmanagerBin ?? 'sdkmanager'} --uninstall ${unused.map((path) => '"platforms;${p.basename(path)}"').join(' ')}',
            ),
          ),
        );
      }
    }

    final buildTools = p.join(sdk, 'build-tools');
    if (refs.buildToolsVersions.isNotEmpty &&
        fileSystem.directory(buildTools).existsSync()) {
      final versions =
          fileSystem
              .directory(buildTools)
              .listSync()
              .where((e) => fileSystem.isDirectorySync(e.path))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));
      final keep = {
        ...refs.buildToolsVersions,
        if (versions.isNotEmpty) p.basename(versions.first.path),
      };
      final unused = versions
          .where((e) => !keep.contains(p.basename(e.path)))
          .map((e) => e.path)
          .toList();
      final breakdown = await sizes.pathBreakdown(unused);
      if (breakdown.totalBytes > 0) {
        items.add(
          ScanItem(
            id: 'android-build-tools-old',
            name: 'Older Android build-tools',
            group: RuleGroup.android,
            risk: RiskLevel.conditional,
            explain: 'Keeps the newest build-tools version; older versions may be needed by unindexed projects.',
            regenerates: RegeneratesKind.reDownload,
            sizeBytes: breakdown.totalBytes,
            paths: unused,
            pathSizes: breakdown.byPath,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.runCommand,
              command: [
                paths.sdkmanagerBin ?? 'sdkmanager',
                '--uninstall',
                ...unused.map((path) => 'build-tools;${p.basename(path)}'),
              ],
              commandDescription:
                  '${paths.sdkmanagerBin ?? 'sdkmanager'} --uninstall ${unused.map((path) => '"build-tools;${p.basename(path)}"').join(' ')}',
            ),
          ),
        );
      }
    }

    final pubSize = await sizes.directorySize(paths.pubCache);
    if (pubSize > 500 * 1024 * 1024) {
      items.add(
        ScanItem(
          id: 'pub-cache',
          name: 'Dart pub cache',
          group: RuleGroup.flutter,
          risk: RiskLevel.conditional,
          explain: 'All pub packages re-download on next flutter pub get.',
          regenerates: RegeneratesKind.reDownload,
          sizeBytes: pubSize,
          paths: [paths.pubCache],
          pathSizes: {paths.pubCache: pubSize},
          selectedByDefault: false,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: [paths.pubCache],
          ),
        ),
      );
    }

    return items;
  }

  Future<List<ScanItem>> projectSweeper(ProjectRefSnapshot refs) async {
    const staleDays = 30;
    final cutoff = DateTime.now().subtract(const Duration(days: staleDays));
    const artifactNames = ['build', '.dart_tool', 'node_modules'];

    final projectItems = await mapConcurrent(refs.projectPaths, (
      project,
    ) async {
      final dir = fileSystem.directory(project);
      if (!dir.existsSync()) {
        return null;
      }
      DateTime modified;
      try {
        modified = dir.statSync().modified;
      } on FileSystemException {
        return null;
      }
      if (modified.isAfter(cutoff)) {
        return null;
      }
      final artifactPaths = <String>[];
      for (final name in artifactNames) {
        final child = p.join(project, name);
        if (fileSystem.directory(child).existsSync()) {
          artifactPaths.add(child);
        }
      }
      final iosPods = p.join(project, 'ios', 'Pods');
      if (fileSystem.directory(iosPods).existsSync()) {
        artifactPaths.add(iosPods);
      }
      final androidGradle = p.join(project, 'android', '.gradle');
      if (fileSystem.directory(androidGradle).existsSync()) {
        artifactPaths.add(androidGradle);
      }
      if (artifactPaths.isEmpty) {
        return null;
      }
      final breakdown = await sizes.pathBreakdown(artifactPaths);
      if (breakdown.totalBytes == 0) {
        return null;
      }
      final id = 'project-${_hashPath(project)}';
      return ScanItem(
        id: id,
        name: 'Stale project artifacts (${p.basename(project)})',
        group: RuleGroup.projects,
        risk: RiskLevel.conditional,
        explain:
            'Project not modified in $staleDays+ days; build outputs only.',
        regenerates: RegeneratesKind.onNextBuild,
        sizeBytes: breakdown.totalBytes,
        paths: artifactPaths,
        pathSizes: breakdown.byPath,
        selectedByDefault: false,
        detail: project,
        cleanAction: CleanAction(
          method: CleanMethod.moveToTrash,
          paths: artifactPaths,
        ),
      );
    }, concurrency: scanConcurrency);
    return projectItems.whereType<ScanItem>().toList();
  }

  Future<List<ScanItem>> protectedReports(
    List<(String id, String name, String root)> reports, {
    required RuleGroup group,
  }) async {
    final built = await mapConcurrent(
      reports,
      (r) async => protectedReportItem(r.$1, r.$2, r.$3, group: group),
      concurrency: scanConcurrency,
    );
    return built.whereType<ScanItem>().toList();
  }

  Future<ScanItem?> protectedReportItem(
    String id,
    String name,
    String root, {
    required RuleGroup group,
  }) async {
    final dir = fileSystem.directory(root);
    if (!dir.existsSync()) {
      return null;
    }

    final children = dir.listSync().map((e) => e.path).toList();
    if (children.isEmpty) {
      final size = await sizes.directorySize(root);
      if (size == 0) {
        return null;
      }
      return ScanItem(
        id: id,
        name: name,
        group: group,
        risk: RiskLevel.protected,
        explain: 'Aggregate context total; may include separately listed cleanable items. Never deleted by mdc.',
        regenerates: RegeneratesKind.never,
        sizeBytes: size,
        paths: [root],
        pathSizes: {root: size},
        selectedByDefault: false,
      );
    }

    final breakdown = await sizes.pathBreakdown(children);
    if (breakdown.totalBytes == 0) {
      return null;
    }

    return ScanItem(
      id: id,
      name: name,
      group: group,
      risk: RiskLevel.protected,
      explain: 'Aggregate context total; may include separately listed cleanable items. Never deleted by mdc.',
      regenerates: RegeneratesKind.never,
      sizeBytes: breakdown.totalBytes,
      paths: children,
      pathSizes: breakdown.byPath,
      selectedByDefault: false,
    );
  }

  Future<int> _brewReclaimEstimate() async {
    final preview = await commandRunner.run('brew', ['cleanup', '-n']);
    if (!preview.success) {
      return 0;
    }
    final match = RegExp(r'Would remove: .* \(([^)]+)\)')
        .firstMatch(preview.stdout);
    if (match == null) {
      return 0;
    }
    return _parseHumanSize(match.group(1)!);
  }

  int _parseHumanSize(String text) {
    final m = RegExp(r'([\d.]+)\s*([KMGTP]?B?)').firstMatch(text.trim());
    if (m == null) {
      return 0;
    }
    final value = double.tryParse(m.group(1)!) ?? 0;
    final unit = m.group(2)!.toUpperCase();
    const mult = {
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
    };
    for (final entry in mult.entries) {
      if (unit.startsWith(entry.key.replaceAll('B', '')) || unit == entry.key) {
        return (value * entry.value).round();
      }
    }
    return value.round();
  }

  String _hashPath(String path) {
    return path.hashCode.toUnsigned(32).toRadixString(16);
  }
}
