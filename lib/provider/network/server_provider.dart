import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/dto/file_dto.dart';
import 'package:netdrop/model/dto/register_dto.dart';
import 'package:netdrop/model/settings_state.dart';
import 'package:netdrop/model/state/server_state.dart';
import 'package:netdrop/model/transfer_history_entry.dart';
import 'package:netdrop/network/transfer_client.dart';
import 'package:netdrop/util/file_saver.dart';
import 'package:netdrop/provider/history_provider.dart';
import 'package:netdrop/provider/local_ip_provider.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/provider/progress_provider.dart';
import 'package:netdrop/provider/security_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/util/user_messages.dart';
import 'package:netdrop/util/simple_server.dart';
import 'package:refena/refena.dart';
import 'package:uuid/uuid.dart';

final _logger = Logger('ServerService');

typedef IncomingSessionCallback = void Function(ReceiveSessionState session);

class ServerService extends Notifier<ServerState> {
  HttpServer? _server;
  IncomingSessionCallback? onIncomingSession;

  final _pendingSessions = <String, _PendingSession>{};
  final _activeTokens = <String, _UploadTarget>{};
  final _savedPaths = <String, Map<String, String>>{};

  @override
  ServerState init() => const ServerState();

  Future<void> startServer({bool scanAlternatePorts = false}) async {
    if (state.starting) {
      return;
    }

    state = state.copyWith(starting: true, clearError: true, portBlocked: false);

    try {
      if (_server != null) {
        await _closeServer();
      }

      final settings = ref.read(settingsProvider);
      _server = await _bindServer(settings);
      _server!.listen(_handleRequest);
      state = state.copyWith(
        running: true,
        starting: false,
        portBlocked: false,
        clearError: true,
      );
      _logger.info('${settings.https ? 'HTTPS' : 'HTTP'} server listening on port ${settings.port}');
    } catch (error, stackTrace) {
      if (scanAlternatePorts && _isAddressInUse(error)) {
        final recovered = await _tryAlternatePorts();
        if (recovered) {
          return;
        }
      }

      final portBlocked = _isAddressInUse(error);
      state = state.copyWith(
        running: false,
        starting: false,
        portBlocked: portBlocked,
        error: friendlyErrorMessage(
          error,
          context: UserMessageContext.server,
          portBlocked: portBlocked,
        ),
      );
      _logger.severe('Failed to start server on port ${ref.read(settingsProvider).port}', error, stackTrace);
    }
  }

  Future<void> tryNextPort() async {
    final current = ref.read(settingsProvider).port;
    final next = current + 1;
    if (next > 65535) {
      return;
    }
    await ref.notifier(settingsProvider).setPort(next);
    await startServer();
  }

  Future<bool> _tryAlternatePorts() async {
    final startPort = ref.read(settingsProvider).port;

    for (var offset = 1; offset <= portFallbackAttempts; offset++) {
      final port = startPort + offset;
      if (port > 65535) {
        break;
      }

      try {
        await ref.notifier(settingsProvider).setPort(port);
        final settings = ref.read(settingsProvider);
        _server = await _bindServer(settings);
        _server!.listen(_handleRequest);
        state = state.copyWith(
          running: true,
          starting: false,
          portBlocked: false,
          clearError: true,
        );
        _logger.info(
          'HTTP server listening on port $port (${startPort} was busy — often LocalSend or another app)',
        );
        return true;
      } catch (error) {
        await _closeServer();
        if (!_isAddressInUse(error)) {
          break;
        }
      }
    }

    await ref.notifier(settingsProvider).setPort(startPort);
    return false;
  }

  Future<HttpServer> _bindServer(SettingsState settings) async {
    const maxAttempts = 6;
    Object? lastError;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (settings.https) {
          return await HttpServer.bindSecure(
            InternetAddress.anyIPv4,
            settings.port,
            ref.notifier(securityProvider).createServerContext(),
            shared: true,
          );
        }
        return await HttpServer.bind(
          InternetAddress.anyIPv4,
          settings.port,
          shared: true,
        );
      } catch (error) {
        lastError = error;
        if (!_isAddressInUse(error) || attempt == maxAttempts - 1) {
          rethrow;
        }
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }

    throw lastError ?? StateError('Failed to bind server');
  }

  bool _isAddressInUse(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('address already in use') || text.contains('eaddrinuse')) {
      return true;
    }
    if (error is SocketException) {
      final code = error.osError?.errorCode;
      return code == 98 || code == 10048 || code == 48;
    }
    return false;
  }

  Future<void> stopServer() async {
    for (final pending in _pendingSessions.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(const HttpException('Cancelled'));
      }
    }
    _pendingSessions.clear();
    _activeTokens.clear();
    _savedPaths.clear();

    await _closeServer();
    ref.notifier(progressProvider).clear();
    state = const ServerState();
  }

  Future<void> _closeServer() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> acceptSession(String sessionId) async {
    final pending = _pendingSessions.remove(sessionId);
    if (pending == null) {
      return;
    }

    final tokens = createFileTokens(pending.session.files);
    for (final entry in tokens.entries) {
      final file = pending.session.files[entry.key]!;
      _activeTokens[entry.value] = _UploadTarget(
        sessionId: sessionId,
        file: file,
      );
    }

    final accepted = pending.session.copyWith(
      tokens: tokens,
      status: ReceiveSessionStatus.accepted,
    );
    state = state.copyWith(activeSession: accepted);
    ref.notifier(progressProvider).startSession(
          accepted.files.values
              .map(
                (file) => (
                  id: file.id,
                  name: file.fileName,
                  type: file.fileType,
                  size: file.size,
                ),
              )
              .toList(),
        );
    pending.completer.complete(
      PrepareUploadResponseDto(sessionId: sessionId, files: tokens),
    );
  }

  Future<void> declineSession(String sessionId) async {
    final pending = _pendingSessions.remove(sessionId);
    if (pending == null) {
      return;
    }

    await ref.notifier(historyProvider).recordReceive(
          session: pending.session,
          outcome: TransferOutcome.declined,
        );
    pending.completer.completeError(const HttpException('Declined'));
    state = state.copyWith(clearSession: true);
  }

  void clearActiveSession() {
    ref.notifier(progressProvider).clear();
    _releaseSessionLocks();
    state = state.copyWith(clearSession: true);
  }

  void _releaseSessionLocks() {
    for (final pending in _pendingSessions.values) {
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(const HttpException('Cancelled'));
      }
    }
    _pendingSessions.clear();
    _activeTokens.clear();
    _savedPaths.clear();
  }

  void _healStaleSessions() {
    final now = DateTime.now();
    final expiredPending = _pendingSessions.entries
        .where((entry) => now.difference(entry.value.createdAt) > const Duration(minutes: 6))
        .map((entry) => entry.key)
        .toList();
    for (final sessionId in expiredPending) {
      unawaited(_cancelReceiveSession(sessionId));
    }

    final session = state.activeSession;
    if (session == null) {
      return;
    }

    if (session.status == ReceiveSessionStatus.pending &&
        !_pendingSessions.containsKey(session.sessionId)) {
      state = state.copyWith(clearSession: true);
      return;
    }

    if (session.status == ReceiveSessionStatus.accepted &&
        !_activeTokens.values.any((target) => target.sessionId == session.sessionId)) {
      ref.notifier(progressProvider).clear();
      state = state.copyWith(clearSession: true);
    }
  }

  bool get _isReceivingBusy {
    _healStaleSessions();

    if (_pendingSessions.isNotEmpty) {
      return true;
    }

    final session = state.activeSession;
    if (session == null) {
      return false;
    }

    return switch (session.status) {
      ReceiveSessionStatus.completed || ReceiveSessionStatus.declined => false,
      ReceiveSessionStatus.accepted =>
        _activeTokens.values.any((target) => target.sessionId == session.sessionId),
      ReceiveSessionStatus.pending => _pendingSessions.containsKey(session.sessionId),
    };
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final routes = [
      SimpleServerRoute(method: 'GET', path: '$apiBasePath/info', handler: _handleInfo),
      SimpleServerRoute(method: 'POST', path: '$apiBasePath/register', handler: _handleRegister),
      SimpleServerRoute(method: 'POST', path: '$apiBasePath/prepare-upload', handler: _handlePrepareUpload),
      SimpleServerRoute(method: 'POST', path: '$apiBasePath/upload', handler: _handleUpload),
      SimpleServerRoute(method: 'POST', path: '$apiBasePath/cancel', handler: _handleCancel),
    ];
    await SimpleServer(routes).handle(request);
  }

  Future<void> _handleInfo(HttpRequest request) async {
    final settings = ref.read(settingsProvider);
    final body = {
      'alias': settings.alias,
      'version': protocolVersion,
      'fingerprint': settings.fingerprint,
      'deviceModel': ref.read(deviceModelProvider),
      'deviceType': ref.read(deviceTypeProvider).name,
      'download': false,
    };
    await SimpleServer.writeJson(request, HttpStatus.ok, body);
  }

  Future<void> _handleRegister(HttpRequest request) async {
    final body = await SimpleServer.readBody(request);
    final dto = RegisterDto.fromJson(jsonDecode(body) as Map<String, dynamic>);
    final ip = request.connectionInfo?.remoteAddress.address ?? 'unknown';

    if (dto.fingerprint != ref.read(settingsProvider).fingerprint) {
      ref.redux(nearbyDevicesProvider).dispatch(
            RegisterDeviceAction(
              dto.toDevice(ip),
              localFingerprint: ref.read(settingsProvider).fingerprint,
            ),
          );
    }

    final settings = ref.read(settingsProvider);
    final response = RegisterDto(
      alias: settings.alias,
      version: protocolVersion,
      fingerprint: settings.fingerprint,
      port: settings.port,
      protocol: settings.https ? 'https' : 'http',
      deviceType: ref.read(deviceTypeProvider),
      deviceModel: ref.read(deviceModelProvider),
    );
    await SimpleServer.writeJson(request, HttpStatus.ok, response.toJson());
  }

  Future<void> _handlePrepareUpload(HttpRequest request) async {
    if (_isReceivingBusy) {
      await SimpleServer.writeJson(request, HttpStatus.conflict, {'message': 'Busy'});
      return;
    }

    final body = await SimpleServer.readBody(request);
    final dto = PrepareUploadRequestDto.fromJson(jsonDecode(body) as Map<String, dynamic>);
    const uuid = Uuid();
    final sessionId = uuid.v4();
    final sender = RegisterDto.fromJson(dto.info);
    final senderIp = request.connectionInfo?.remoteAddress.address;

    final session = ReceiveSessionState(
      sessionId: sessionId,
      sender: sender,
      files: dto.files,
      senderIp: senderIp,
    );

    final completer = Completer<PrepareUploadResponseDto>();
    _pendingSessions[sessionId] = _PendingSession(session: session, completer: completer);
    state = state.copyWith(activeSession: session);
    _logger.info('Incoming transfer from ${sender.alias} (${session.files.length} files)');
    onIncomingSession?.call(session);

    try {
      final response = await completer.future.timeout(const Duration(minutes: 5));
      await SimpleServer.writeJson(request, HttpStatus.ok, response.toJson());
    } on TimeoutException {
      _pendingSessions.remove(sessionId);
      state = state.copyWith(clearSession: true);
      await SimpleServer.writeJson(request, HttpStatus.forbidden, {'message': 'Timed out'});
    } catch (error) {
      _pendingSessions.remove(sessionId);
      final cancelled =
          error is HttpException && error.message == 'Cancelled';
      if (state.activeSession?.sessionId == sessionId) {
        if (cancelled) {
          state = state.copyWith(clearSession: true);
        } else {
          state = state.copyWith(
            activeSession: session.copyWith(status: ReceiveSessionStatus.declined),
          );
        }
      }
      await SimpleServer.writeJson(
        request,
        HttpStatus.forbidden,
        {'message': cancelled ? 'Cancelled' : 'Declined'},
      );
    }
  }

  Future<void> _handleUpload(HttpRequest request) async {
    final params = request.uri.queryParameters;
    final token = params['token'];
    if (token == null || !_activeTokens.containsKey(token)) {
      await SimpleServer.writeJson(request, HttpStatus.forbidden, {'message': 'Invalid token'});
      return;
    }

    final target = _activeTokens.remove(token)!;
    final fileSaver = ref.read(fileSaverProvider);
    final progress = ref.notifier(progressProvider);
    final savedLocation = await fileSaver.saveStream(
      stream: request,
      fileName: target.file.fileName,
      fileType: target.file.fileType,
      totalBytes: target.file.size,
      onProgress: (value) => progress.updateFile(target.file.id, value),
    );
    _savedPaths
        .putIfAbsent(target.sessionId, () => {})
        [target.file.id] = savedLocation;
    progress.completeFile(
      target.file.id,
      savedPath: savedLocation,
      fileType: target.file.fileType,
      size: target.file.size,
    );
    await SimpleServer.writeEmpty(request, HttpStatus.ok);

    final remaining = _activeTokens.values.where((value) => value.sessionId == target.sessionId);
    if (remaining.isEmpty) {
      final session = state.activeSession;
      if (session != null && session.sessionId == target.sessionId) {
        await ref.notifier(historyProvider).recordReceive(
              session: session.copyWith(status: ReceiveSessionStatus.completed),
              outcome: TransferOutcome.completed,
              savedPaths: _savedPaths.remove(target.sessionId) ?? const {},
            );
      }
      progress.finalizeSession(success: true);
      state = state.copyWith(clearSession: true);
    }
  }

  Future<void> _handleCancel(HttpRequest request) async {
    final sessionId = _resolveCancelSessionId(request);
    if (sessionId != null) {
      await _cancelReceiveSession(sessionId);
    }
    await SimpleServer.writeEmpty(request, HttpStatus.ok);
  }

  String? _resolveCancelSessionId(HttpRequest request) {
    final sessionId = request.uri.queryParameters['sessionId'];
    if (sessionId != null && sessionId.isNotEmpty) {
      return sessionId;
    }

    final fingerprint = request.uri.queryParameters['fingerprint'];
    if (fingerprint == null || fingerprint.isEmpty) {
      return null;
    }

    for (final entry in _pendingSessions.entries) {
      if (entry.value.session.sender.fingerprint == fingerprint) {
        return entry.key;
      }
    }

    final active = state.activeSession;
    if (active != null && active.sender.fingerprint == fingerprint) {
      return active.sessionId;
    }
    return null;
  }

  Future<void> _cancelReceiveSession(
    String sessionId, {
    bool recordHistory = true,
  }) async {
    final pending = _pendingSessions.remove(sessionId);
    if (pending != null && !pending.completer.isCompleted) {
      pending.completer.completeError(const HttpException('Cancelled'));
    }

    final session = state.activeSession;
    if (session != null && session.sessionId == sessionId && recordHistory) {
      await ref.notifier(historyProvider).recordReceive(
            session: session,
            outcome: TransferOutcome.cancelled,
            savedPaths: _savedPaths.remove(sessionId) ?? const {},
          );
    }

    _activeTokens.removeWhere((_, target) => target.sessionId == sessionId);
    _savedPaths.remove(sessionId);
    ref.notifier(progressProvider).clear();
    if (state.activeSession?.sessionId == sessionId) {
      state = state.copyWith(clearSession: true);
    }
  }
}

class _PendingSession {
  _PendingSession({
    required this.session,
    required this.completer,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final ReceiveSessionState session;
  final Completer<PrepareUploadResponseDto> completer;
  final DateTime createdAt;
}

class _UploadTarget {
  _UploadTarget({
    required this.sessionId,
    required this.file,
  });

  final String sessionId;
  final FileDto file;
}

final serverProvider = NotifierProvider<ServerService, ServerState>(
  (ref) => ServerService(),
);
