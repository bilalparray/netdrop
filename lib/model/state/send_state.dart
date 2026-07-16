enum SendSessionStatus {
  preparing,
  uploading,
  completed,
  failed,
  cancelled,
}

class SendSessionState {
  const SendSessionState({
    required this.sessionId,
    required this.remoteSessionId,
    required this.fileTokens,
    this.status = SendSessionStatus.preparing,
    this.progress = 0,
    this.error,
  });

  final String sessionId;
  final String remoteSessionId;
  final Map<String, String> fileTokens;
  final SendSessionStatus status;
  final double progress;
  final String? error;

  SendSessionState copyWith({
    String? remoteSessionId,
    Map<String, String>? fileTokens,
    SendSessionStatus? status,
    double? progress,
    String? error,
  }) {
    return SendSessionState(
      sessionId: sessionId,
      remoteSessionId: remoteSessionId ?? this.remoteSessionId,
      fileTokens: fileTokens ?? this.fileTokens,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }
}

class SendState {
  const SendState({this.activeSession});

  final SendSessionState? activeSession;

  SendState copyWith({
    SendSessionState? activeSession,
    bool clearSession = false,
  }) {
    return SendState(
      activeSession: clearSession ? null : (activeSession ?? this.activeSession),
    );
  }
}
