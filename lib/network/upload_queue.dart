const uploadConcurrency = 2;

Future<void> runWithConcurrency<T>({
  required List<T> items,
  required Future<void> Function(T item) worker,
  required int maxConcurrent,
  bool Function()? shouldCancel,
}) async {
  if (items.isEmpty) {
    return;
  }

  var nextIndex = 0;

  Future<void> runWorker() async {
    while (true) {
      if (shouldCancel?.call() ?? false) {
        return;
      }
      final index = nextIndex++;
      if (index >= items.length) {
        return;
      }
      await worker(items[index]);
    }
  }

  final workers = <Future<void>>[];
  for (var i = 0; i < maxConcurrent && i < items.length; i++) {
    workers.add(runWorker());
  }
  await Future.wait(workers);
}
