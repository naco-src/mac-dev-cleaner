import 'dart:io' show Platform;

/// Default worker count for disk-bound scan work.
int defaultScanConcurrency() {
  try {
    return Platform.numberOfProcessors.clamp(2, 12);
  } catch (_) {
    return 6;
  }
}

/// Runs [action] for each element with at most [concurrency] in flight.
Future<List<R>> mapConcurrent<E, R>(
  Iterable<E> elements,
  Future<R> Function(E element) action, {
  int concurrency = 6,
}) async {
  final items = elements.toList();
  if (items.isEmpty) {
    return <R>[];
  }
  final workers = concurrency.clamp(1, items.length);
  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final i = nextIndex;
      nextIndex = i + 1;
      if (i >= items.length) {
        return;
      }
      results[i] = await action(items[i]);
    }
  }

  await Future.wait(List.generate(workers, (_) => worker()));
  return results.cast<R>();
}
