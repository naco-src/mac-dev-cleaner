import 'dart:io';

import 'package:desktop_updater/desktop_updater.dart';
import 'package:path_provider/path_provider.dart';

import 'json_file_update_recovery_store.dart';

/// Update feed on the repo `updates` branch (see desktop_updater.yaml).
const kDesktopUpdaterAppArchiveUrl =
    'https://raw.githubusercontent.com/naco-src/mac-dev-cleaner/updates/app-archive.json';

const kMacOsPackageId = 'io.github.nguyenhoangvannha.macDevCleaner';

/// Ed25519 release keys from `dart run desktop_updater:release keygen`.
const trustedReleasePublicKeys = <String, String>{
  'release-09d9f482daf8fe781a793efc':
      '8FnYXiG2KS2sWe0ktzAgvi4XpRpI/tknsZuPZYxVkmQ=',
};

Uri desktopUpdaterAppArchiveUrl() {
  final override = Platform.environment['DESKTOP_UPDATER_APP_ARCHIVE_URL'];
  if (override != null && override.trim().isNotEmpty) {
    return Uri.parse(override.trim());
  }
  return Uri.parse(kDesktopUpdaterAppArchiveUrl);
}

Future<JsonFileUpdateRecoveryStore> createUpdateRecoveryStore() async {
  final appSupportDirectory = await getApplicationSupportDirectory();
  final separator = Platform.pathSeparator;
  return JsonFileUpdateRecoveryStore(
    File(
      '${appSupportDirectory.path}${separator}desktop_updater'
      '${separator}pending-install-stable.json',
    ),
  );
}

Future<DesktopUpdaterController> createDesktopUpdaterController() async {
  final recoveryStore = await createUpdateRecoveryStore();
  return DesktopUpdaterController(
    appArchiveUrl: desktopUpdaterAppArchiveUrl(),
    expectedPackageId: kMacOsPackageId,
    trustedReleasePublicKeys: trustedReleasePublicKeys,
    recoveryStore: recoveryStore,
    // Optional updates: user checks from the app bar; feed defaults to non-mandatory.
    skipInitialVersionCheck: true,
  );
}
