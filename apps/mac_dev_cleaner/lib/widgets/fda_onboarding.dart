import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _kFdaSeenKey = 'mdc_fda_onboarding_seen';

Future<bool> shouldShowFdaOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kFdaSeenKey) ?? false);
}

Future<void> markFdaOnboardingSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kFdaSeenKey, true);
}

Future<void> resetFdaOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_kFdaSeenKey);
}

Future<void> openFullDiskAccessSettings() async {
  const urls = [
    'x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles',
    'x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles',
  ];
  for (final url in urls) {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
  }
}

Future<void> showFdaOnboardingSheet(
  BuildContext context, {
  required VoidCallback onDismiss,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Disk Access',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Mac Dev Cleaner needs Full Disk Access to measure and clean caches under '
              'your home folder (Xcode, Android SDK, IDE caches, etc.).',
            ),
            const SizedBox(height: 12),
            const Text(
              '1. Open System Settings → Privacy & Security → Full Disk Access',
            ),
            const Text(
              '2. Enable “Mac Dev Cleaner” (or Terminal while developing)',
            ),
            const Text('3. Restart the app if sizes look too small'),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await openFullDiskAccessSettings();
                  },
                  child: const Text('Open Settings'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    await markFdaOnboardingSeen();
                    if (context.mounted) {
                      Navigator.pop(context);
                      onDismiss();
                    }
                  },
                  child: const Text('Got it'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
