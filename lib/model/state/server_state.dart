import 'package:netdrop/model/dto/file_dto.dart';
import 'package:netdrop/model/dto/register_dto.dart';

class ReceiveSessionState {
  const ReceiveSessionState({
    required this.sessionId,
    required this.sender,
    required this.files,
    this.senderIp,
    this.tokens = const {},
    this.status = ReceiveSessionStatus.pending,
  });

  final String sessionId;
  final RegisterDto sender;
  final Map<String, FileDto> files;
  final String? senderIp;
  final Map<String, String> tokens;
  final ReceiveSessionStatus status;

  ReceiveSessionState copyWith({
    Map<String, String>? tokens,
    ReceiveSessionStatus? status,
    String? senderIp,
  }) {
    return ReceiveSessionState(
      sessionId: sessionId,
      sender: sender,
      files: files,
      senderIp: senderIp ?? this.senderIp,
      tokens: tokens ?? this.tokens,
      status: status ?? this.status,
    );
  }
}

enum ReceiveSessionStatus {
  pending,
  accepted,
  declined,
  completed,
}

class ServerState {
  const ServerState({
    this.running = false,
    this.starting = false,
    this.portBlocked = false,
    this.error,
    this.activeSession,
  });

  final bool running;
  final bool starting;
  final bool portBlocked;
  final String? error;
  final ReceiveSessionState? activeSession;

  ServerState copyWith({
    bool? running,
    bool? starting,
    bool? portBlocked,
    String? error,
    ReceiveSessionState? activeSession,
    bool clearSession = false,
    bool clearError = false,
  }) {
    return ServerState(
      running: running ?? this.running,
      starting: starting ?? this.starting,
      portBlocked: portBlocked ?? this.portBlocked,
      error: clearError ? null : (error ?? this.error),
      activeSession: clearSession ? null : (activeSession ?? this.activeSession),
    );
  }
}
