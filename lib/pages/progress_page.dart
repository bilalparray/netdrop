import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/config/theme.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/model/state/send_state.dart';
import 'package:netdrop/provider/network/nearby_devices_provider.dart';
import 'package:netdrop/provider/network/send_provider.dart';
import 'package:netdrop/provider/progress_provider.dart';
import 'package:netdrop/util/user_messages.dart';
import 'package:netdrop/widget/design/netdrop_card.dart';
import 'package:netdrop/widget/design/transfer_progress_bar.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({
    super.key,
    required this.device,
    required this.files,
  });

  final Device device;
  final List<CrossFile> files;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with Refena {
  var _started = false;

  @override
  void initState() {
    super.initState();
    ensureRef((ref) async {
      if (_started) {
        return;
      }
      _started = true;
      try {
        await ref.notifier(sendProvider).sendToDevice(
              device: widget.device,
              files: widget.files,
            );
        ref.notifier(selectedFilesProvider).clear();
      } catch (_) {
        // Error state is shown in UI.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sendState = context.watch(sendProvider);
    final session = sendState.activeSession;
    final progress = context.watch(progressProvider);

    final canCancel = session?.status == SendSessionStatus.preparing ||
        session?.status == SendSessionStatus.uploading;
    final transferFinished = session != null &&
        session.status != SendSessionStatus.preparing &&
        session.status != SendSessionStatus.uploading;

    return Scaffold(
      appBar: AppBar(title: Text('Sending to ${widget.device.alias}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NetDropCard(
              child: _StatusHeader(session: session, progress: progress.overall),
            ),
            if (progress.files.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Files',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: progress.files.values.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: NetDropCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.fileName,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  TransferProgressBar(
                                    value: entry.completed ? 1 : entry.progress,
                                    height: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (entry.completed)
                              const Icon(Icons.check_circle, color: NetDropColors.online)
                            else if (entry.failed || transferFinished)
                              const Icon(Icons.error_outline, color: NetDropColors.error)
                            else
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value: entry.progress > 0 ? entry.progress : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else
              const Spacer(),
            if (canCancel) ...[
              OutlinedButton(
                onPressed: () async {
                  await context.notifier(sendProvider).cancelActiveTransfer();
                },
                style: netDropDangerOutlinedButtonStyle(context),
                child: const Text('Cancel transfer'),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: () async {
                await context.notifier(sendProvider).dismissTransfer(device: widget.device);
                if (context.mounted) {
                  context.popUntilRoot();
                }
              },
              child: Text(
                session?.status == SendSessionStatus.completed ? 'Done' : 'Close',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.session, required this.progress});

  final SendSessionState? session;
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (session == null || session!.status == SendSessionStatus.preparing) {
      return Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for receiver…',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Accept the transfer on the other device',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.nd.textSecondary,
                ),
          ),
        ],
      );
    }

    return switch (session!.status) {
      SendSessionStatus.uploading => TransferProgressDisplay(
          progress: progress,
          label: 'Uploading…',
        ),
      SendSessionStatus.completed => Column(
          children: [
            Icon(Icons.check_circle, color: NetDropColors.online, size: 64),
            const SizedBox(height: 12),
            Text(
              'Transfer complete',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      SendSessionStatus.cancelled => Column(
          children: [
            Icon(Icons.cancel_outlined, color: context.nd.textMuted, size: 64),
            const SizedBox(height: 12),
            Text(
              'Transfer cancelled',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      SendSessionStatus.failed => Column(
          children: [
            const Icon(Icons.error_outline, color: NetDropColors.error, size: 64),
            const SizedBox(height: 12),
            Text(
              friendlyErrorMessage(
                session!.error,
                context: UserMessageContext.send,
                fallback: 'Transfer failed. Please try again.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NetDropColors.error,
                  ),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
