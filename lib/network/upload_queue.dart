import 'package:netdrop/config/constants.dart';

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

/// Runs [action] up to [maxAttempts] times with short backoff between failures.
Future<void> retryWithBackoff({
  required Future<void> Function() action,
  int maxAttempts = uploadMaxRetries,
  bool Function()? shouldCancel,
  bool Function(Object error)? shouldRethrow,
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    if (shouldCancel?.call() ?? false) {
      return;
    }
    try {
      await action();
      return;
    } catch (error) {
      if (shouldRethrow?.call(error) ?? false) {
        rethrow;
      }
      lastError = error;
      if (attempt >= maxAttempts) {
        break;
      }
      await Future<void>.delayed(Duration(milliseconds: 150 * attempt));
    }
  }
  Error.throwWithStackTrace(
    lastError!,
    StackTrace.current,
  );
}
