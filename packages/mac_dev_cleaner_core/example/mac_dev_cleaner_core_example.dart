import 'package:mac_dev_cleaner_core/mac_dev_cleaner_core.dart';

Future<void> main() async {
  final mdc = MacDevCleaner();
  final items = await mdc.scan();
  for (final item in items.take(10)) {
    // ignore: avoid_print
    print('${formatBytes(item.sizeBytes)} ${item.risk.label} ${item.name}');
  }
}
