import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';
import 'package:test/test.dart';

void main() {
  test('createDevCleanerHost returns Linux host', () {
    final host = createDevCleanerHost(platform: HostPlatform.linux);
    expect(host.platform, HostPlatform.linux);
    expect(host.paths.home, isNotEmpty);
  });
}
