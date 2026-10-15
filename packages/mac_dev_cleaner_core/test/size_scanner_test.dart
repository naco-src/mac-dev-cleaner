import 'package:file/memory.dart';
import 'package:mac_dev_cleaner_core/src/scanner/size_scanner.dart';
import 'package:test/test.dart';

void main() {
  test('reuses path sizes within a scan and refreshes between scans', () async {
    final fs = MemoryFileSystem();
    const root = '/cache';
    fs.directory(root).createSync();
    final file = fs.file('$root/item');
    file.createSync();
    file.writeAsStringSync('abc');
    final scanner = SizeScanner(fs);

    expect(await scanner.directorySize(root), 3);
    file.writeAsStringSync('abcdef');
    expect(await scanner.directorySize(root), 3);

    scanner.clearCache();
    expect(await scanner.directorySize(root), 6);
  });
}
