import 'package:flutter/material.dart';
import 'package:netdrop/provider/local_ip_provider.dart';
import 'package:netdrop/provider/progress_provider.dart';
import 'package:netdrop/widget/design/server_status_banner.dart';
import 'package:netdrop/provider/settings_provider.dart';
import 'package:netdrop/provider/local_device_info_provider.dart';
import 'package:netdrop/widget/design/empty_state.dart';
import 'package:netdrop/widget/design/netdrop_card.dart';
import 'package:netdrop/widget/design/section_header.dart';
import 'package:netdrop/util/file_saver.dart';
import 'package:netdrop/widget/design/this_device_card.dart';
import 'package:netdrop/widget/design/transfer_progress_bar.dart';
import 'package:netdrop/widget/received_file_list_tile.dart';
import 'package:netdrop/widget/responsive_builder.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ReceiveTab extends StatelessWidget {
  const ReceiveTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch(settingsProvider);
    final progress = context.watch(progressProvider);
    final files = progress.files.values.toList();
    final receiving = progress.active;
    final deviceType = context.watch(deviceTypeProvider);
    final osLabel = context.watch(localDeviceInfoProvider).osLabel;

    return ResponsiveListView(
      children: [
        FutureBuilder<List<String>>(
          future: context.read(localIpProvider).getLocalIps(),
          builder: (context, snapshot) {
            return ThisDeviceCard(
              alias: settings.alias,
              deviceType: deviceType,
              osLabel: osLabel,
              ipAddress: snapshot.data?.firstOrNull,
            );
          },
        ),
        const SizedBox(height: 24),
        const ServerStatusBanner(),
        SectionHeader(title: 'Received files'),
        const SizedBox(height: 12),
        if (files.isEmpty)
          FutureBuilder<List<ReceiveSaveLocation>>(
            future: context.read(fileSaverProvider).getReceiveSaveLocations(),
            builder: (context, snapshot) {
              final locations = snapshot.data;
              final subtitle = locations == null
                  ? 'Accepted transfers will appear here. You can tap a file to open it.'
                  : locations.length == 1
                      ? 'Accepted transfers appear here. Saved files go to ${locations.first.path}.'
                      : 'Accepted transfers appear here. Saved by type under NetDrop in '
                          '${locations.map((l) => l.path.split('/').first).join(', ')}.';
              return EmptyState(
                icon: Icons.download_outlined,
                title: 'No files yet',
                subtitle: subtitle,
              );
            },
          )
        else
          NetDropCard(
            child: Column(
              children: [
                if (receiving) ...[
                  TransferProgressDisplay(
                    progress: progress.overall,
                    label: 'Receiving…',
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
                ...files.map(
                  (file) => ReceivedFileListTile(
                    fileName: file.fileName,
                    fileType: file.fileType,
                    size: file.size,
                    savedPath: file.savedPath,
                    completed: file.completed,
                    failed: file.failed,
                    inProgress: receiving,
                    progress: receiving ? file.progress : null,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
