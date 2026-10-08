import '../../io/process_runner.dart';
import '../../report/disk_space.dart';
import '../disk_space_provider.dart';

class MacOSDiskSpaceProvider implements DiskSpaceProvider {
  const MacOSDiskSpaceProvider();

  @override
  Future<DataVolumeSpace?> read(ProcessRunner commandRunner) async {
    final result = await commandRunner.run('df', [
      '-k',
      '/System/Volumes/Data',
    ]);
    if (!result.success) {
      return null;
    }
    final lines = result.stdout
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.length < 2) {
      return null;
    }
    final parts = lines[1].split(RegExp(r'\s+'));
    if (parts.length < 4) {
      return null;
    }
    final totalK = int.tryParse(parts[1]) ?? 0;
    final usedK = int.tryParse(parts[2]) ?? 0;
    final availK = int.tryParse(parts[3]) ?? 0;
    const k = 1024;
    return DataVolumeSpace(
      mountPoint: '/System/Volumes/Data',
      totalBytes: totalK * k,
      freeBytes: availK * k,
      usedBytes: usedK * k,
    );
  }
}
