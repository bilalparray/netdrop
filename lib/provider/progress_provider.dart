import 'package:refena/refena.dart';

class FileProgressEntry {
  const FileProgressEntry({
    required this.fileId,
    required this.fileName,
    this.fileType = 'application/octet-stream',
    this.size = 0,
    this.progress = 0,
    this.completed = false,
    this.failed = false,
    this.savedPath,
  });

  final String fileId;
  final String fileName;
  final String fileType;
  final int size;
  final double progress;
  final bool completed;
  final bool failed;
  final String? savedPath;

  FileProgressEntry copyWith({
    double? progress,
    bool? completed,
    bool? failed,
    String? savedPath,
    String? fileType,
    int? size,
  }) {
    return FileProgressEntry(
      fileId: fileId,
      fileName: fileName,
      fileType: fileType ?? this.fileType,
      size: size ?? this.size,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
      failed: failed ?? this.failed,
      savedPath: savedPath ?? this.savedPath,
    );
  }
}

class ProgressState {
  const ProgressState({
    this.files = const {},
    this.overall = 0,
    this.active = false,
  });

  final Map<String, FileProgressEntry> files;
  final double overall;
  final bool active;

  ProgressState copyWith({
    Map<String, FileProgressEntry>? files,
    double? overall,
    bool? active,
  }) {
    return ProgressState(
      files: files ?? this.files,
      overall: overall ?? this.overall,
      active: active ?? this.active,
    );
  }
}

class ProgressService extends Notifier<ProgressState> {
  @override
  ProgressState init() => const ProgressState();

  void startSession(List<({String id, String name, String type, int size})> fileDescriptors) {
    final files = {
      for (final file in fileDescriptors)
        file.id: FileProgressEntry(
          fileId: file.id,
          fileName: file.name,
          fileType: file.type,
          size: file.size,
        ),
    };
    state = ProgressState(files: files, active: true);
  }

  void updateFile(String fileId, double progress) {
    final entry = state.files[fileId];
    if (entry == null) {
      return;
    }
    final files = {...state.files, fileId: entry.copyWith(progress: progress)};
    state = state.copyWith(files: files, overall: _calculateOverall(files));
  }

  void completeFile(
    String fileId, {
    String? savedPath,
    String? fileType,
    int? size,
  }) {
    final entry = state.files[fileId];
    if (entry == null) {
      return;
    }
    final files = {
      ...state.files,
      fileId: entry.copyWith(
        progress: 1,
        completed: true,
        savedPath: savedPath,
        fileType: fileType,
        size: size,
      ),
    };
    state = state.copyWith(files: files, overall: _calculateOverall(files));
  }

  void finishSession() {
    state = state.copyWith(active: false, overall: 1);
  }

  /// Marks the session done. Incomplete files become completed or failed.
  void finalizeSession({required bool success}) {
    if (state.files.isEmpty) {
      state = const ProgressState();
      return;
    }

    final files = <String, FileProgressEntry>{};
    for (final entry in state.files.entries) {
      if (entry.value.completed || entry.value.failed) {
        files[entry.key] = entry.value;
      } else if (success) {
        files[entry.key] = entry.value.copyWith(progress: 1, completed: true);
      } else {
        files[entry.key] = entry.value.copyWith(failed: true);
      }
    }

    state = ProgressState(
      files: files,
      active: false,
      overall: success ? 1 : _calculateOverall(files),
    );
  }

  void failFile(String fileId) {
    final entry = state.files[fileId];
    if (entry == null) {
      return;
    }
    final files = {...state.files, fileId: entry.copyWith(failed: true)};
    state = state.copyWith(files: files);
  }

  void clear() {
    state = const ProgressState();
  }

  double _calculateOverall(Map<String, FileProgressEntry> files) {
    if (files.isEmpty) {
      return 0;
    }
    final total = files.values.fold<double>(0, (sum, entry) => sum + entry.progress);
    return total / files.length;
  }
}

final progressProvider = NotifierProvider<ProgressService, ProgressState>(
  (ref) => ProgressService(),
);
