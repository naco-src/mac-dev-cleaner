import 'dart:io' show Platform;

enum HostPlatform {
  macos,
  linux,
  windows,
  unknown;

  bool get isSupported => this == HostPlatform.macos;
}

HostPlatform currentHostPlatform() {
  if (Platform.isMacOS) {
    return HostPlatform.macos;
  }
  if (Platform.isLinux) {
    return HostPlatform.linux;
  }
  if (Platform.isWindows) {
    return HostPlatform.windows;
  }
  return HostPlatform.unknown;
}
