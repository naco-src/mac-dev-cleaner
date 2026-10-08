import 'package:mac_dev_cleaner_core/src/util/parallel.dart';
import 'package:test/test.dart';

void main() {
  test('mapConcurrent preserves order', () async {
    final out = await mapConcurrent(List.generate(10, (i) => i), (i) async {
      await Future<void>.delayed(Duration(milliseconds: 10 - i));
      return i * 2;
    }, concurrency: 4);
    expect(out, List.generate(10, (i) => i * 2));
  });

  test('mapConcurrent handles empty input', () async {
    expect(await mapConcurrent<int, int>([], (i) async => i), isEmpty);
  });
}
