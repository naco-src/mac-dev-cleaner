import 'package:file/file.dart';
import 'package:path/path.dart' as p;

import '../../analyzer/project_refs.dart';
import '../../io/process_check.dart';
import '../../io/process_runner.dart';
import '../../models/clean_action.dart';
import '../../models/enums.dart';
import '../../models/scan_item.dart';
import '../../scanner/scan_log.dart';
import '../../scanner/shared_scan_phases.dart';
import '../../scanner/size_scanner.dart';
import '../../util/parallel.dart';
import '../scan_engine.dart';
import 'linux_paths.dart';

/// Linux scan rules; macOS uses [ScanService].
class LinuxScanService implements ScanEngine {
  LinuxScanService({
    required this.fileSystem,
    required this.commandRunner,
    LinuxPaths? paths,
    int? scanConcurrency,
  }) : paths = paths ?? LinuxHostPaths(),
       scanConcurrency = scanConcurrency ?? defaultScanConcurrency(),
       _sizes = SizeScanner(
         fileSystem,
         concurrency: scanConcurrency ?? defaultScanConcurrency(),
       );

  final FileSystem fileSystem;
  final ProcessRunner commandRunner;
  final LinuxPaths paths;
  final int scanConcurrency;
  final SizeScanner _sizes;

  SharedScanPhases get _shared => SharedScanPhases(
    fileSystem: fileSystem,
    commandRunner: commandRunner,
    paths: paths,
    sizes: _sizes,
    scanConcurrency: scanConcurrency,
  );

  @override
  Future<List<ScanItem>> scanAll({ScanProgressCallback? onProgress}) async {
    void log(ScanLogLevel level, String message) {
      onProgress?.call(ScanLogEntry(level: level, message: message));
    }

    Future<List<ScanItem>> phase(
      String name,
      Future<List<ScanItem>> Function() run,
    ) async {
      log(ScanLogLevel.info, '→ $name');
      try {
        final result = await run();
        log(ScanLogLevel.info, '✓ $name (${result.length} items)');
        return result;
      } catch (e, st) {
        log(ScanLogLevel.error, '✗ $name: $e');
        if (e is! Exception) {
          log(ScanLogLevel.error, st.toString().split('\n').first);
        }
        return [];
      }
    }

    log(ScanLogLevel.info, 'Scan started');
    log(ScanLogLevel.info, 'Project roots: ${paths.projectRoots().join(', ')}');

    final items = <ScanItem>[];
    ProjectRefSnapshot projectRefs;
    log(ScanLogLevel.info, '→ Index projects (NDK, Gradle refs)');
    try {
      projectRefs = await ProjectRefs(
        fileSystem,
        roots: paths.projectRoots(),
      ).collect();
      log(
        ScanLogLevel.info,
        '✓ Index projects — ${projectRefs.projectPaths.length} project(s), '
        '${projectRefs.ndkVersions.length} NDK version(s)',
      );
    } catch (e) {
      log(ScanLogLevel.error, '✗ Index projects: $e');
      projectRefs = ProjectRefSnapshot(
        ndkVersions: {},
        compileSdks: {},
        gradleWrapperVersions: {},
        projectPaths: [],
      );
    }

    final refs = projectRefs;
    log(
      ScanLogLevel.info,
      'Running scan phases in parallel (concurrency: $scanConcurrency)',
    );
    final phaseResults = await Future.wait([
      phase('Safe cleanup targets', _safeRules),
      phase(
        'Android (NDK, images, pub)',
        () => _shared.conditionalAndroid(refs),
      ),
      phase('IDE & browser caches', _ideAndBrowser),
      phase('Stale project artifacts', () => _shared.projectSweeper(refs)),
      phase('Protected totals (report only)', _protectedReports),
    ]);
    for (final chunk in phaseResults) {
      items.addAll(chunk);
    }

    items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    log(ScanLogLevel.info, 'Scan finished — ${items.length} entries');
    return items;
  }

  Future<List<ScanItem>> _safeRules() async {
    final items = <ScanItem>[];
    items.addAll(await _shared.homebrewCleanupIfAvailable());
    items.addAll(await _shared.packageManagersGradleAndAndroidCache());
    items.addAll(await _editorCacheRules());
    items.addAll(await _userLogs());
    return items;
  }

  Future<List<ScanItem>> _editorCacheRules() async {
    final editors = [
      ('cursor', 'Cursor', 'Cursor', ['cursor', 'Cursor']),
      ('code', 'Visual Studio Code', 'Code', ['code', 'Code']),
      (
        'antigravity',
        'Antigravity',
        'Antigravity',
        ['antigravity', 'Antigravity'],
      ),
    ];
    const cacheFolderNames = [
      'Cache',
      'CachedData',
      'Code Cache',
      'GPUCache',
      'CachedExtensionVSIXs',
      'logs',
      'Logs',
      'CachedProfilesData',
    ];
    final editorItems = await mapConcurrent(editors, (editor) async {
      final support = p.join(paths.configHome, editor.$3);
      if (!fileSystem.directory(support).existsSync()) {
        return null;
      }
      final cachePaths = _sizes.existingChildPaths(support, cacheFolderNames);
      final breakdown = await _sizes.pathBreakdown(cachePaths);
      if (breakdown.totalBytes == 0) {
        return null;
      }
      final running = await isAnyProcessRunning(commandRunner, editor.$4);
      return ScanItem(
        id: '${editor.$1}-caches',
        name: '${editor.$2} caches',
        group: RuleGroup.ide,
        risk: RiskLevel.safe,
        explain: 'Editor cache folders only; settings and extensions stay.',
        regenerates: RegeneratesKind.automatically,
        sizeBytes: breakdown.totalBytes,
        paths: cachePaths,
        pathSizes: breakdown.byPath,
        selectedByDefault: !running,
        preconditionMet: !running,
        preconditionHint: running ? 'Quit ${editor.$2} before cleaning.' : null,
        cleanAction: CleanAction(
          method: CleanMethod.moveToTrash,
          paths: cachePaths,
        ),
      );
    }, concurrency: scanConcurrency);
    return editorItems.whereType<ScanItem>().toList();
  }

  Future<List<ScanItem>> _userLogs() async {
    final logDir = paths.stateHome;
    if (!fileSystem.directory(logDir).existsSync()) {
      return [];
    }
    final children = fileSystem
        .directory(logDir)
        .listSync()
        .map((e) => e.path)
        .toList();
    final breakdown = await _sizes.pathBreakdown(children);
    if (breakdown.totalBytes == 0) {
      return [];
    }
    return [
      ScanItem(
        id: 'user-logs',
        name: 'User state logs',
        group: RuleGroup.linux,
        risk: RiskLevel.safe,
        explain: 'Application logs under ~/.local/state.',
        regenerates: RegeneratesKind.automatically,
        sizeBytes: breakdown.totalBytes,
        paths: children,
        pathSizes: breakdown.byPath,
        selectedByDefault: true,
        cleanAction: CleanAction(
          method: CleanMethod.moveToTrash,
          paths: children,
        ),
      ),
    ];
  }

  Future<List<ScanItem>> _ideAndBrowser() async {
    final items = <ScanItem>[];
    final chromeRoot = p.join(paths.configHome, 'google-chrome');
    if (fileSystem.directory(chromeRoot).existsSync()) {
      final profiles = fileSystem
          .directory(chromeRoot)
          .listSync()
          .where((e) => fileSystem.isDirectorySync(e.path));
      final profilePaths = profiles
          .map((e) => e.path)
          .where(
            (path) =>
                p.basename(path).startsWith('Profile') ||
                p.basename(path) == 'Default',
          )
          .toList();
      final chromeRunning = await isAnyProcessRunning(commandRunner, [
        'chrome',
        'google-chrome',
        'chromium',
      ]);
      final profileItems = await mapConcurrent(profilePaths, (
        profilePath,
      ) async {
        final cachePaths = _sizes.existingChildPaths(profilePath, [
          'Cache',
          'Code Cache',
          p.join('Service Worker', 'CacheStorage'),
        ]);
        final breakdown = await _sizes.pathBreakdown(cachePaths);
        if (breakdown.totalBytes == 0) {
          return null;
        }
        return ScanItem(
          id: 'chrome-cache-${p.basename(profilePath)}',
          name: 'Chrome ${p.basename(profilePath)} caches',
          group: RuleGroup.browser,
          risk: RiskLevel.conditional,
          explain: 'Cache only; cookies and logins untouched.',
          regenerates: RegeneratesKind.automatically,
          sizeBytes: breakdown.totalBytes,
          paths: cachePaths,
          pathSizes: breakdown.byPath,
          selectedByDefault: false,
          preconditionMet: !chromeRunning,
          preconditionHint: chromeRunning ? 'Quit Chrome first.' : null,
          cleanAction: CleanAction(
            method: CleanMethod.moveToTrash,
            paths: cachePaths,
          ),
        );
      }, concurrency: scanConcurrency);
      items.addAll(profileItems.whereType<ScanItem>());
    }

    final jetbrains = p.join(paths.configHome, 'JetBrains');
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
      final breakdown = await _sizes.pathBreakdown(oldIde);
      if (breakdown.totalBytes > 0) {
        items.add(
          ScanItem(
            id: 'jetbrains-old-versions',
            name: 'JetBrains old IDE version folders',
            group: RuleGroup.ide,
            risk: RiskLevel.conditional,
            explain: 'Keeps the newest JetBrains config folder only.',
            regenerates: RegeneratesKind.never,
            sizeBytes: breakdown.totalBytes,
            paths: oldIde,
            pathSizes: breakdown.byPath,
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

  Future<List<ScanItem>> _protectedReports() async {
    return _shared.protectedReports([
      ('local-share-total', 'Local share data (report only)', paths.dataHome),
      ('android-sdk-total', 'Android SDK (report only)', paths.androidSdk),
    ], group: RuleGroup.linux);
  }
}
