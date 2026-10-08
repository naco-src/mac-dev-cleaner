import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../analyzer/android_avd.dart';
import '../analyzer/project_refs.dart';
import '../doctor/doctor_service.dart';
import '../io/process_runner.dart';
import '../io/process_check.dart';
import '../models/clean_action.dart';
import '../models/enums.dart';
import '../models/scan_item.dart';
import '../util/paths.dart';
import 'size_scanner.dart';

class ScanService {
  ScanService({
    required this.fileSystem,
    required this.commandRunner,
    MdcPaths? paths,
  }) : paths = paths ?? MdcPaths(),
       _sizes = SizeScanner(fileSystem);

  final FileSystem fileSystem;
  final ProcessRunner commandRunner;
  final MdcPaths paths;
  final SizeScanner _sizes;

  Future<List<ScanItem>> scanAll() async {
    final items = <ScanItem>[];
    final projectRefs = await ProjectRefs(
      fileSystem,
      roots: paths.projectRoots(),
    ).collect();

    items.addAll(await _safeRules());
    items.addAll(await _conditionalAndroid(projectRefs));
    items.addAll(await _conditionalXcode());
    items.addAll(await _ideAndBrowser());
    items.addAll(await _projectSweeper(projectRefs));
    items.addAll(await _protectedReports());

    items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    return items;
  }

  Future<List<ScanItem>> _safeRules() async {
    final items = <ScanItem>[];

    final derived = paths.xcodeDerivedData;
    if (fileSystem.directory(derived).existsSync()) {
      final children = fileSystem
          .directory(derived)
          .listSync()
          .map((e) => e.path)
          .toList();
      final size = await _sizes.pathsTotal(children);
      items.add(
        ScanItem(
          id: 'xcode-derived-data',
          name: 'Xcode DerivedData',
          group: RuleGroup.xcode,
          risk: RiskLevel.safe,
          explain: 'Build artifacts and indexes Xcode can regenerate.',
          regenerates: RegeneratesKind.onNextBuild,
          sizeBytes: size,
          paths: children,
          selectedByDefault: true,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: children,
          ),
        ),
      );
    }

    items.add(
      ScanItem(
        id: 'xcode-sim-unavailable',
        name: 'Unavailable iOS simulators',
        group: RuleGroup.xcode,
        risk: RiskLevel.safe,
        explain: 'Removes simulator devices marked unavailable.',
        regenerates: RegeneratesKind.notApplicable,
        sizeBytes: 0,
        selectedByDefault: true,
        cleanAction: const CleanAction(
          method: CleanMethod.runCommand,
          command: ['xcrun', 'simctl', 'delete', 'unavailable'],
          commandDescription: 'xcrun simctl delete unavailable',
        ),
      ),
    );

    final cocoapods = p.join(paths.caches, 'CocoaPods');
    final cocoapodsSize = await _sizes.directorySize(cocoapods);
    if (cocoapodsSize > 0) {
      items.add(
        ScanItem(
          id: 'cocoapods-cache',
          name: 'CocoaPods cache',
          group: RuleGroup.xcode,
          risk: RiskLevel.safe,
          explain: 'Downloaded pod specs and caches.',
          regenerates: RegeneratesKind.reDownload,
          sizeBytes: cocoapodsSize,
          paths: [cocoapods],
          selectedByDefault: true,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: [cocoapods],
          ),
        ),
      );
    }

    items.add(
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
    );

    final npmOk = await _npmCacheUsable();
    final npmSize = await _sizes.directorySize(paths.npmCache);
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

    for (final entry in [
      ('pnpm-store', 'pnpm', ['store', 'prune']),
      ('yarn-cache', 'yarn', ['cache', 'clean']),
    ]) {
      items.add(
        ScanItem(
          id: entry.$1,
          name: entry.$1,
          group: RuleGroup.node,
          risk: RiskLevel.safe,
          explain: 'Package manager cache (if installed).',
          regenerates: RegeneratesKind.reDownload,
          sizeBytes: 0,
          selectedByDefault: true,
          cleanAction: CleanAction(
            method: CleanMethod.runCommand,
            command: [entry.$2, ...entry.$3],
            commandDescription: '${entry.$2} ${entry.$3.join(' ')}',
          ),
        ),
      );
    }

    for (final gradlePath in [
      p.join(paths.gradleHome, 'caches'),
      p.join(paths.gradleHome, 'daemon'),
    ]) {
      final size = await _sizes.directorySize(gradlePath);
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
    final abcSize = await _sizes.directorySize(androidBuildCache);
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
          selectedByDefault: true,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: [androidBuildCache],
          ),
        ),
      );
    }

    items.addAll(await _editorCacheRules());
    items.addAll(await _userLogs());

    return items;
  }

  Future<List<ScanItem>> _editorCacheRules() async {
    final editors = [
      ('cursor', 'Cursor', ['Cursor']),
      ('code', 'Visual Studio Code', ['Code', 'Electron']),
      ('antigravity', 'Antigravity', ['Antigravity']),
    ];
    final cacheFolderNames = [
      'Cache',
      'CachedData',
      'Code Cache',
      'GPUCache',
      'CachedExtensionVSIXs',
      'logs',
      'Logs',
    ];
    final items = <ScanItem>[];

    for (final editor in editors) {
      final support = p.join(paths.applicationSupport, editor.$2);
      if (!fileSystem.directory(support).existsSync()) {
        continue;
      }
      final cachePaths = _sizes.existingChildPaths(support, cacheFolderNames);
      final size = await _sizes.pathsTotal(cachePaths);
      if (size == 0) {
        continue;
      }
      final running = await isAnyProcessRunning(commandRunner, editor.$3);
      items.add(
        ScanItem(
          id: '${editor.$1}-caches',
          name: '${editor.$2} caches',
          group: RuleGroup.ide,
          risk: RiskLevel.safe,
          explain: 'Editor cache folders only; settings and extensions stay.',
          regenerates: RegeneratesKind.automatically,
          sizeBytes: size,
          paths: cachePaths,
          selectedByDefault: !running,
          preconditionMet: !running,
          preconditionHint: running
              ? 'Quit ${editor.$2} before cleaning.'
              : null,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: cachePaths,
          ),
        ),
      );
    }
    return items;
  }

  Future<List<ScanItem>> _userLogs() async {
    final logDir = paths.logs;
    if (!fileSystem.directory(logDir).existsSync()) {
      return [];
    }
    final children = fileSystem
        .directory(logDir)
        .listSync()
        .map((e) => e.path)
        .toList();
    final size = await _sizes.pathsTotal(children);
    if (size == 0) {
      return [];
    }
    return [
      ScanItem(
        id: 'user-logs',
        name: 'User Logs',
        group: RuleGroup.macos,
        risk: RiskLevel.safe,
        explain: 'Application logs under ~/Library/Logs.',
        regenerates: RegeneratesKind.automatically,
        sizeBytes: size,
        paths: children,
        selectedByDefault: true,
        cleanAction: CleanAction(
          method: CleanMethod.moveToTrash,
          paths: children,
        ),
      ),
    ];
  }

  Future<List<ScanItem>> _conditionalAndroid(ProjectRefSnapshot refs) async {
    final items = <ScanItem>[];
    final sdk = paths.androidSdk;
    final ndkRoot = p.join(sdk, 'ndk');
    if (fileSystem.directory(ndkRoot).existsSync()) {
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
      final size = await _sizes.pathsTotal(uninstall);
      if (size > 0) {
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
            sizeBytes: size,
            paths: uninstall,
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
      final size = await _sizes.pathsTotal(unused);
      if (size > 0) {
        items.add(
          ScanItem(
            id: 'android-system-images-unused',
            name: 'Android system images (no AVD)',
            group: RuleGroup.android,
            risk: RiskLevel.conditional,
            explain: 'Images not referenced by any AVD config.ini.',
            regenerates: RegeneratesKind.reDownload,
            sizeBytes: size,
            paths: unused,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.moveToTrash,
              paths: unused,
            ),
          ),
        );
      }
    }

    final pubSize = await _sizes.directorySize(paths.pubCache);
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

  Future<List<ScanItem>> _conditionalXcode() async {
    final items = <ScanItem>[];

    final runtimeResult = await commandRunner.run('xcrun', [
      'simctl',
      'runtime',
      'list',
      '-j',
    ]);
    if (runtimeResult.success && runtimeResult.stdout.trim().isNotEmpty) {
      try {
        final json = jsonDecode(runtimeResult.stdout) as Map<String, dynamic>;
        final runtimes = json['runtimes'] as List<dynamic>? ?? [];
        for (final rt in runtimes) {
          final map = rt as Map<String, dynamic>;
          final identifier = map['identifier']?.toString() ?? '';
          final version = map['version']?.toString() ?? identifier;
          var size = (map['size'] as num?)?.toInt() ?? 0;
          final bundlePath = map['bundlePath']?.toString();
          if (size == 0 && bundlePath != null && bundlePath.isNotEmpty) {
            size = await _sizes.directorySize(bundlePath);
          }
          if (identifier.isEmpty) {
            continue;
          }
          items.add(
            ScanItem(
              id: 'ios-runtime-${identifier.replaceAll('.', '-')}',
              name: 'iOS Simulator runtime $version',
              group: RuleGroup.xcode,
              risk: RiskLevel.conditional,
              explain: 'Removed with xcrun simctl runtime delete (never rm).',
              regenerates: RegeneratesKind.reDownload,
              sizeBytes: size,
              selectedByDefault: false,
              cleanAction: CleanAction(
                method: CleanMethod.runCommand,
                command: ['xcrun', 'simctl', 'runtime', 'delete', identifier],
                commandDescription: 'xcrun simctl runtime delete $identifier',
              ),
            ),
          );
        }
      } on FormatException {
        // ignore malformed JSON
      }
    }

    final archivesRoot = paths.xcodeArchives;
    if (fileSystem.directory(archivesRoot).existsSync()) {
      final toRemove = <String>[];
      for (final appEntity in fileSystem.directory(archivesRoot).listSync()) {
        if (!fileSystem.isDirectorySync(appEntity.path)) {
          continue;
        }
        final appDir = fileSystem.directory(appEntity.path);
        final archives =
            appDir
                .listSync()
                .where((e) => fileSystem.isDirectorySync(e.path))
                .toList()
              ..sort((a, b) => b.path.compareTo(a.path));
        if (archives.length <= 2) {
          continue;
        }
        toRemove.addAll(archives.skip(2).map((d) => d.path));
      }
      final size = await _sizes.pathsTotal(toRemove);
      if (size > 0) {
        items.add(
          ScanItem(
            id: 'xcode-archives-old',
            name: 'Xcode Archives (keep 2 newest per app)',
            group: RuleGroup.xcode,
            risk: RiskLevel.conditional,
            explain: 'Older archives may hold dSYMs; newest two per app kept.',
            regenerates: RegeneratesKind.never,
            sizeBytes: size,
            paths: toRemove,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.moveToTrash,
              paths: toRemove,
            ),
          ),
        );
      }
    }

    final deviceSupport = paths.deviceSupport;
    if (fileSystem.directory(deviceSupport).existsSync()) {
      final children = fileSystem
          .directory(deviceSupport)
          .listSync()
          .map((e) => e.path)
          .toList();
      final size = await _sizes.pathsTotal(children);
      if (size > 0) {
        items.add(
          ScanItem(
            id: 'ios-device-support',
            name: 'iOS DeviceSupport',
            group: RuleGroup.xcode,
            risk: RiskLevel.conditional,
            explain: 'Symbols for physical devices; re-download when device connects.',
            regenerates: RegeneratesKind.reDownload,
            sizeBytes: size,
            paths: children,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.moveToTrash,
              paths: children,
            ),
          ),
        );
      }
    }

    return items;
  }

  Future<List<ScanItem>> _ideAndBrowser() async {
    final items = <ScanItem>[];
    final chromeRoot = p.join(paths.applicationSupport, 'Google', 'Chrome');
    if (fileSystem.directory(chromeRoot).existsSync()) {
      final profiles = fileSystem
          .directory(chromeRoot)
          .listSync()
          .where((e) => fileSystem.isDirectorySync(e.path));
      for (final profile in profiles) {
        if (!p.basename(profile.path).startsWith('Profile') &&
            p.basename(profile.path) != 'Default') {
          continue;
        }
        final cachePaths = _sizes.existingChildPaths(profile.path, [
          'Cache',
          'Code Cache',
          p.join('Service Worker', 'CacheStorage'),
        ]);
        final size = await _sizes.pathsTotal(cachePaths);
        if (size == 0) {
          continue;
        }
        final running = await isProcessRunning(commandRunner, 'Google Chrome');
        items.add(
          ScanItem(
            id: 'chrome-cache-${p.basename(profile.path)}',
            name: 'Chrome ${p.basename(profile.path)} caches',
            group: RuleGroup.browser,
            risk: RiskLevel.conditional,
            explain: 'Cache only; cookies and logins untouched.',
            regenerates: RegeneratesKind.automatically,
            sizeBytes: size,
            paths: cachePaths,
            selectedByDefault: false,
            preconditionMet: !running,
            preconditionHint: running ? 'Quit Google Chrome first.' : null,
            cleanAction: CleanAction(
              method: CleanMethod.moveToTrash,
              paths: cachePaths,
            ),
          ),
        );
      }
    }

    final jetbrains = p.join(paths.applicationSupport, 'JetBrains');
    if (fileSystem.directory(jetbrains).existsSync()) {
      final oldIde = <String>[];
      final versions =
          fileSystem
              .directory(jetbrains)
              .listSync()
              .where((e) => fileSystem.isDirectorySync(e.path))
              .toList()
            ..sort((a, b) => b.path.compareTo(a.path));
      if (versions.length > 1) {
        oldIde.addAll(versions.skip(1).map((d) => d.path));
      }
      final size = await _sizes.pathsTotal(oldIde);
      if (size > 0) {
        items.add(
          ScanItem(
            id: 'jetbrains-old-versions',
            name: 'JetBrains old IDE version folders',
            group: RuleGroup.ide,
            risk: RiskLevel.conditional,
            explain: 'Keeps the newest JetBrains config folder only.',
            regenerates: RegeneratesKind.never,
            sizeBytes: size,
            paths: oldIde,
            selectedByDefault: false,
            cleanAction: CleanAction(
              method: CleanMethod.moveToTrash,
              paths: oldIde,
            ),
          ),
        );
      }
    }

    return items;
  }

  Future<List<ScanItem>> _projectSweeper(ProjectRefSnapshot refs) async {
    final items = <ScanItem>[];
    final staleDays = 30;
    final cutoff = DateTime.now().subtract(Duration(days: staleDays));
    final artifactNames = ['build', '.dart_tool', 'node_modules'];

    for (final project in refs.projectPaths) {
      final dir = fileSystem.directory(project);
      if (!dir.existsSync()) {
        continue;
      }
      DateTime? modified;
      try {
        modified = dir.statSync().modified;
      } on FileSystemException {
        continue;
      }
      if (modified.isAfter(cutoff)) {
        continue;
      }
      final paths = <String>[];
      for (final name in artifactNames) {
        final child = p.join(project, name);
        if (fileSystem.directory(child).existsSync()) {
          paths.add(child);
        }
      }
      final iosPods = p.join(project, 'ios', 'Pods');
      if (fileSystem.directory(iosPods).existsSync()) {
        paths.add(iosPods);
      }
      final androidGradle = p.join(project, 'android', '.gradle');
      if (fileSystem.directory(androidGradle).existsSync()) {
        paths.add(androidGradle);
      }
      if (paths.isEmpty) {
        continue;
      }
      final size = await _sizes.pathsTotal(paths);
      if (size == 0) {
        continue;
      }
      final id = 'project-${_hashPath(project)}';
      items.add(
        ScanItem(
          id: id,
          name: 'Stale project artifacts (${p.basename(project)})',
          group: RuleGroup.projects,
          risk: RiskLevel.conditional,
          explain:
              'Project not modified in $staleDays+ days; build outputs only.',
          regenerates: RegeneratesKind.onNextBuild,
          sizeBytes: size,
          paths: paths,
          selectedByDefault: false,
          detail: project,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: paths,
          ),
        ),
      );
    }
    return items;
  }

  Future<List<ScanItem>> _protectedReports() async {
    final reports = [
      (
        'app-support-total',
        'Application Support (report only)',
        paths.applicationSupport,
      ),
      ('android-sdk-total', 'Android SDK (report only)', paths.androidSdk),
    ];
    final items = <ScanItem>[];
    for (final r in reports) {
      final size = await _sizes.directorySize(r.$3);
      if (size == 0) {
        continue;
      }
      items.add(
        ScanItem(
          id: r.$1,
          name: r.$2,
          group: RuleGroup.macos,
          risk: RiskLevel.protected,
          explain: 'Shown for context; never deleted by mdc.',
          regenerates: RegeneratesKind.never,
          sizeBytes: size,
          paths: [r.$3],
          selectedByDefault: false,
        ),
      );
    }
    return items;
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

  Future<bool> _npmCacheUsable() async {
    final doctor = DoctorService(commandRunner: commandRunner, paths: paths);
    final issues = await doctor.checkNpmOwnership();
    return issues.isEmpty;
  }

  String _hashPath(String path) {
    return path.hashCode.toUnsigned(32).toRadixString(16);
  }
}
