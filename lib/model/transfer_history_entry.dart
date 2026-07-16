enum TransferDirection {
  sent,
  received;

  String toJson() => name;

  static TransferDirection fromJson(String value) {
    return TransferDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => TransferDirection.sent,
    );
  }
}

enum TransferOutcome {
  completed,
  cancelled,
  failed,
  declined;

  String toJson() => name;

  static TransferOutcome fromJson(String value) {
    return TransferOutcome.values.firstWhere(
      (outcome) => outcome.name == value,
      orElse: () => TransferOutcome.completed,
    );
  }
}

class TransferHistoryFile {
  const TransferHistoryFile({
    required this.fileName,
    required this.size,
    required this.fileType,
    this.path,
  });

  final String fileName;
  final int size;
  final String fileType;
  final String? path;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'size': size,
      'fileType': fileType,
      if (path != null) 'path': path,
    };
  }

  factory TransferHistoryFile.fromJson(Map<String, dynamic> json) {
    return TransferHistoryFile(
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      fileType: json['fileType'] as String? ?? 'application/octet-stream',
      path: json['path'] is String ? json['path'] as String : null,
    );
  }
}

class TransferHistoryEntry {
  const TransferHistoryEntry({
    required this.id,
    required this.direction,
    required this.timestamp,
    required this.peerAlias,
    required this.files,
    required this.outcome,
    this.peerIp,
    this.peerFingerprint,
    this.error,
  });

  final String id;
  final TransferDirection direction;
  final DateTime timestamp;
  final String peerAlias;
  final String? peerIp;
  final String? peerFingerprint;
  final List<TransferHistoryFile> files;
  final TransferOutcome outcome;
  final String? error;

  int get totalBytes => files.fold(0, (sum, file) => sum + file.size);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'direction': direction.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'peerAlias': peerAlias,
      if (peerIp != null) 'peerIp': peerIp,
      if (peerFingerprint != null) 'peerFingerprint': peerFingerprint,
      'files': files.map((file) => file.toJson()).toList(),
      'outcome': outcome.toJson(),
      if (error != null) 'error': error,
    };
  }

  factory TransferHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TransferHistoryEntry(
      id: json['id'] as String,
      direction: TransferDirection.fromJson(json['direction'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      peerAlias: json['peerAlias'] as String,
      peerIp: json['peerIp'] as String?,
      peerFingerprint: json['peerFingerprint'] as String?,
      files: (json['files'] as List<dynamic>)
          .map((file) => TransferHistoryFile.fromJson(file as Map<String, dynamic>))
          .toList(),
      outcome: TransferOutcome.fromJson(json['outcome'] as String),
      error: json['error'] as String?,
    );
  }
}
