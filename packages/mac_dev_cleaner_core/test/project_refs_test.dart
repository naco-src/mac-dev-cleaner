import 'package:file/memory.dart';
import 'package:mac_dev_cleaner_core/src/analyzer/project_refs.dart';
import 'package:test/test.dart';

void main() {
  test('collects Android SDK and Gradle wrapper references', () async {
    final fs = MemoryFileSystem();
    const root = '/home/dev/Projects';
    const project = '$root/sample';
    fs.directory(project).createSync(recursive: true);
    fs.file('$project/build.gradle.kts')
      ..createSync()
      ..writeAsStringSync('''
android {
  ndkVersion = "27.0.12077973"
  compileSdk = 35
  buildToolsVersion = "35.0.0"
}
''');
    fs.file('$project/gradle/wrapper/gradle-wrapper.properties')
      ..createSync(recursive: true)
      ..writeAsStringSync(
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.10-bin.zip',
      );

    final refs = await ProjectRefs(fs, roots: const [root]).collect();

    expect(refs.ndkVersions, contains('27.0.12077973'));
    expect(refs.compileSdks, contains('35'));
    expect(refs.buildToolsVersions, contains('35.0.0'));
    expect(refs.gradleWrapperVersions, contains('8.10'));
  });
}
