import 'package:netdrop/config/constants.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/dto/register_dto.dart';
import 'package:netdrop/model/state/send_state.dart';
import 'package:netdrop/network/transfer_client.dart';
import 'package:netdrop/network/upload_queue.dart';
import 'package:netdrop/provider/history_provider.dart';
import 'package:netdrop/provider/local_ip_provider.dart';
import 'package:netdrop/provider/progress_provider.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/util/user_messages.dart';
import 'package:refena/refena.dart';
import 'package:uuid/uuid.dart';

class SendService extends Notifier<SendState> {
  bool _cancelRequested = false;
  Device? _activeDevice;

  @override
  SendState init() => const SendState();

  Future<void> sendToDevice({
    required Device device,
    required List<CrossFile> files,
  }) async {
    if (files.isEmpty) {
      return;
    }

    _cancelRequested = false;
    _activeDevice = device;

    const uuid = Uuid();
    final localSessionId = uuid.v4();
    final progress = ref.notifier(progressProvider);
    progress.startSession(
      files
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

    state = SendState(
      activeSession: SendSessionState(
        sessionId: localSessionId,
        remoteSessionId: '',
        fileTokens: const {},
        status: SendSessionStatus.preparing,
      ),
    );

    try {
      final settings = ref.read(settingsProvider);
      final sender = RegisterDto(
        alias: settings.alias,
        version: '2.1',
        fingerprint: settings.fingerprint,
        port: settings.port,
        protocol: settings.https ? 'https' : 'http',
        deviceType: ref.read(deviceTypeProvider),
        deviceModel: ref.read(deviceModelProvider),
      );

      final client = ref.read(transferClientProvider);
      final session = await client.openUploadSession(
        target: device,
        sender: sender,
        files: files,
      );

      if (_cancelRequested) {
        await session.close(force: true);
        throw SessionCancelledException();
      }

      state = SendState(
        activeSession: SendSessionState(
          sessionId: localSessionId,
          remoteSessionId: session.sessionId,
          fileTokens: session.files,
          status: SendSessionStatus.uploading,
        ),
      );

      try {
        await runWithConcurrency<CrossFile>(
          items: files,
          maxConcurrent: uploadConcurrency,
          shouldCancel: () => _cancelRequested,
          worker: (file) async {
            if (_cancelRequested) {
              throw SessionCancelledException();
            }

            final token = session.files[file.id];
            if (token == null) {
              progress.failFile(file.id);
              return;
            }

            await retryWithBackoff(
              shouldCancel: () {
                if (_cancelRequested) {
                  throw SessionCancelledException();
                }
                return false;
              },
              shouldRethrow: (error) => error is SessionCancelledException,
              action: () => session.uploadFile(
                file: file,
                token: token,
                shouldCancel: () => _cancelRequested,
                onProgress: (value) => progress.updateFile(file.id, value),
              ),
            );
            progress.completeFile(file.id);
          },
        );
      } finally {
        await session.close(force: _cancelRequested);
      }

      state = SendState(
        activeSession: state.activeSession!.copyWith(
          status: SendSessionStatus.completed,
          progress: 1,
        ),
      );
      await ref.notifier(historyProvider).recordSend(
            device: device,
            files: files,
            status: SendSessionStatus.completed,
          );
      progress.finalizeSession(success: true);
    } on SessionCancelledException {
      state = SendState(
        activeSession: state.activeSession?.copyWith(
          status: SendSessionStatus.cancelled,
        ),
      );
      await ref.notifier(historyProvider).recordSend(
            device: device,
            files: files,
            status: SendSessionStatus.cancelled,
          );
      progress.finalizeSession(success: false);
    } catch (error) {
      if (_cancelRequested) {
        state = SendState(
          activeSession: state.activeSession?.copyWith(
            status: SendSessionStatus.cancelled,
          ),
        );
        await ref.notifier(historyProvider).recordSend(
              device: device,
              files: files,
              status: SendSessionStatus.cancelled,
            );
        progress.finalizeSession(success: false);
        return;
      }
      await _releaseRemoteSession(device);
      final message = friendlyErrorMessage(error, context: UserMessageContext.send);
      state = SendState(
        activeSession: state.activeSession?.copyWith(
          status: SendSessionStatus.failed,
          error: message,
        ),
      );
      await ref.notifier(historyProvider).recordSend(
            device: device,
            files: files,
            status: SendSessionStatus.failed,
            error: message,
          );
      progress.finalizeSession(success: false);
      rethrow;
    } finally {
      _activeDevice = null;
    }
  }

  Future<void> cancelActiveTransfer() async {
    _cancelRequested = true;
    final session = state.activeSession;
    final device = _activeDevice;
    await _releaseRemoteSession(device, session: session);

    state = SendState(
      activeSession: state.activeSession?.copyWith(
        status: SendSessionStatus.cancelled,
      ),
    );
    ref.notifier(progressProvider).clear();
  }

  Future<void> _releaseRemoteSession(Device? device, {SendSessionState? session}) async {
    session ??= state.activeSession;
    if (device == null || session == null) {
      return;
    }

    final client = ref.read(transferClientProvider);
    try {
      if (session.remoteSessionId.isNotEmpty) {
        await client.cancelSession(
          target: device,
          sessionId: session.remoteSessionId,
        );
      } else {
        final fingerprint = ref.read(settingsProvider).fingerprint;
        await client.cancelSession(
          target: device,
          senderFingerprint: fingerprint,
        );
        client.abortPrepareUpload();
      }
    } catch (_) {
      // Best effort — receiver may already have cleared the session.
    }
  }

  Future<void> dismissTransfer({Device? device}) async {
    final session = state.activeSession;
    final target = device ?? _activeDevice;
    if (target != null &&
        session != null &&
        (session.status == SendSessionStatus.preparing ||
            session.status == SendSessionStatus.uploading)) {
      _cancelRequested = true;
      await _releaseRemoteSession(target, session: session);
    }
    clearSession();
  }

  void clearSession() {
    _cancelRequested = false;
    _activeDevice = null;
    ref.notifier(progressProvider).clear();
    state = const SendState();
  }
}

final sendProvider = NotifierProvider<SendService, SendState>(
  (ref) => SendService(),
);
