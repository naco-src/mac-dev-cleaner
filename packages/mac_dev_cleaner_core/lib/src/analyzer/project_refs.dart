import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:path/path.dart' as p;

final _ndkVersionPattern = RegExp(
  '''ndkVersion\\s*[= ]+\\s*["']([^"']+)["']''',
);

/// Finds SDK/NDK/Gradle references in project trees.
class ProjectRefs {
  ProjectRefs(this.fileSystem, {required this.roots});

  final FileSystem fileSystem;
  final List<String> roots;

  Future<ProjectRefSnapshot> collect() async {
    final ndkVersions = <String>{};
    final compileSdks = <String>{};
    final gradleWrapperVersions = <String>{};
    final projectPaths = <String>[];

    for (final root in roots) {
      final rootDir = fileSystem.directory(root);
      if (!rootDir.existsSync()) {
        continue;
      }
      await _walkProjects(root, (projectDir) {
        projectPaths.add(projectDir);
        _scanGradleFiles(projectDir, ndkVersions, compileSdks);
        _scanGradleWrapper(projectDir, gradleWrapperVersions);
      });
    }

    return ProjectRefSnapshot(
      ndkVersions: ndkVersions,
      compileSdks: compileSdks,
      gradleWrapperVersions: gradleWrapperVersions,
      projectPaths: projectPaths,
    );
  }

  Future<void> _walkProjects(
    String root,
    void Function(String dir) onProject,
  ) async {
    final dir = io.Directory(root);
    if (!dir.existsSync()) {
      return;
    }
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! io.Directory) {
        continue;
      }
      final path = entity.path;
      final name = p.basename(path);
      if (name == 'node_modules' ||
          name == 'build' ||
          name == '.git' ||
          name == 'Pods' ||
          name.startsWith('.')) {
        continue;
      }
      if (fileSystem.file(p.join(path, 'pubspec.yaml')).existsSync() ||
          fileSystem.file(p.join(path, 'package.json')).existsSync() ||
          fileSystem.file(p.join(path, 'build.gradle')).existsSync() ||
          fileSystem.file(p.join(path, 'build.gradle.kts')).existsSync()) {
        onProject(path);
      }
    }
  }

  void _scanGradleFiles(
    String projectDir,
    Set<String> ndkVersions,
    Set<String> compileSdks,
  ) {
    for (final name in ['build.gradle', 'build.gradle.kts']) {
      final file = fileSystem.file(p.join(projectDir, name));
      if (!file.existsSync()) {
        continue;
      }
      final content = file.readAsStringSync();
      for (final match in _ndkVersionPattern.allMatches(content)) {
        ndkVersions.add(match.group(1)!);
      }
      for (final match in RegExp(
        r'compileSdk\s*[= ]+\s*(\d+)',
      ).allMatches(content)) {
        compileSdks.add(match.group(1)!);
      }
      for (final match in RegExp(
        r'compileSdkVersion\s*[= ]+\s*(\d+)',
      ).allMatches(content)) {
        compileSdks.add(match.group(1)!);
      }
    }
    final androidDir = fileSystem.directory(p.join(projectDir, 'android'));
    if (androidDir.existsSync()) {
      for (final name in ['build.gradle', 'build.gradle.kts']) {
        final file = fileSystem.file(p.join(androidDir.path, name));
        if (!file.existsSync()) {
          continue;
        }
        final content = file.readAsStringSync();
        for (final match in _ndkVersionPattern.allMatches(content)) {
          ndkVersions.add(match.group(1)!);
        }
        for (final match in RegExp(
          r'compileSdk\s*[= ]+\s*(\d+)',
        ).allMatches(content)) {
          compileSdks.add(match.group(1)!);
        }
      }
    }
  }

  void _scanGradleWrapper(
    String projectDir,
    Set<String> gradleWrapperVersions,
  ) {
    final props = fileSystem.file(
      p.join(
        projectDir,
        'android',
        'gradle',
        'wrapper',
        'gradle-wrapper.properties',
      ),
    );
    if (!props.existsSync()) {
      final alt = fileSystem.file(
        p.join(projectDir, 'gradle', 'wrapper', 'gradle-wrapper.properties'),
      );
      if (!alt.existsSync()) {
        return;
      }
      _parseWrapper(alt, gradleWrapperVersions);
      return;
    }
    _parseWrapper(props, gradleWrapperVersions);
  }

  void _parseWrapper(File props, Set<String> gradleWrapperVersions) {
    final content = props.readAsStringSync();
    final match = RegExp(r'gradle-([\d.]+)-').firstMatch(content);
    if (match != null) {
      gradleWrapperVersions.add(match.group(1)!);
    }
  }
}

class ProjectRefSnapshot {
  ProjectRefSnapshot({
    required this.ndkVersions,
    required this.compileSdks,
    required this.gradleWrapperVersions,
    required this.projectPaths,
  });

  final Set<String> ndkVersions;
  final Set<String> compileSdks;
  final Set<String> gradleWrapperVersions;
  final List<String> projectPaths;
}
