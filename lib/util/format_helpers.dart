String formatFileSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

String formatHistoryTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final time =
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

  if (date == today) {
    return 'Today $time';
  }
  if (date == today.subtract(const Duration(days: 1))) {
    return 'Yesterday $time';
  }
  return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-'
      '${timestamp.day.toString().padLeft(2, '0')} $time';
}
