import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/state/server_state.dart';
import 'package:netdrop/model/state/send_state.dart';
import 'package:netdrop/model/transfer_history_entry.dart';
import 'package:netdrop/provider/persistence_provider.dart';
import 'package:refena/refena.dart';
import 'package:uuid/uuid.dart';

const maxHistoryEntries = 100;

class HistoryService extends Notifier<List<TransferHistoryEntry>> {
  @override
  List<TransferHistoryEntry> init() {
    return ref.read(persistenceProvider).loadHistory();
  }

  Future<void> addEntry(TransferHistoryEntry entry) async {
    final updated = [entry, ...state];
    if (updated.length > maxHistoryEntries) {
      updated.removeRange(maxHistoryEntries, updated.length);
    }
    state = updated;
    await ref.read(persistenceProvider).saveHistory(updated);
  }

  Future<void> clearHistory() async {
    state = const [];
    await ref.read(persistenceProvider).saveHistory(const []);
  }

  Future<void> recordSend({
    required Device device,
    required List<CrossFile> files,
    required SendSessionStatus status,
    String? error,
  }) async {
    final outcome = switch (status) {
      SendSessionStatus.completed => TransferOutcome.completed,
      SendSessionStatus.cancelled => TransferOutcome.cancelled,
      SendSessionStatus.failed => TransferOutcome.failed,
      _ => null,
    };
    if (outcome == null) {
      return;
    }

    await addEntry(
      TransferHistoryEntry(
        id: const Uuid().v4(),
        direction: TransferDirection.sent,
        timestamp: DateTime.now(),
        peerAlias: device.alias,
        peerIp: device.ip,
        peerFingerprint: device.fingerprint,
        files: files
            .map(
              (file) => TransferHistoryFile(
                fileName: file.fileName,
                size: file.size,
                fileType: file.fileType,
                path: file.path,
              ),
            )
            .toList(),
        outcome: outcome,
        error: error,
      ),
    );
  }

  Future<void> recordReceive({
    required ReceiveSessionState session,
    required TransferOutcome outcome,
    Map<String, String> savedPaths = const {},
    String? error,
  }) async {
    await addEntry(
      TransferHistoryEntry(
        id: session.sessionId,
        direction: TransferDirection.received,
        timestamp: DateTime.now(),
        peerAlias: session.sender.alias,
        peerIp: session.senderIp,
        peerFingerprint: session.sender.fingerprint,
        files: session.files.values
            .map(
              (file) => TransferHistoryFile(
                fileName: file.fileName,
                size: file.size,
                fileType: file.fileType,
                path: savedPaths[file.id],
              ),
            )
            .toList(),
        outcome: outcome,
        error: error,
      ),
    );
  }
}

final historyProvider = NotifierProvider<HistoryService, List<TransferHistoryEntry>>(
  (ref) => HistoryService(),
);
