import 'package:flutter/material.dart';

import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';

import 'package:netdrop/model/transfer_history_entry.dart';

import 'package:netdrop/provider/history_provider.dart';

import 'package:netdrop/util/format_helpers.dart';

import 'package:netdrop/util/open_file_helper.dart';

import 'package:netdrop/util/user_messages.dart';

import 'package:netdrop/widget/design/empty_state.dart';

import 'package:netdrop/widget/design/netdrop_card.dart';

import 'package:netdrop/widget/design/section_header.dart';

import 'package:netdrop/widget/design/status_chip.dart';

import 'package:netdrop/widget/received_file_list_tile.dart';

import 'package:netdrop/widget/responsive_builder.dart';

import 'package:refena_flutter/refena_flutter.dart';



enum _HistoryFilter { all, sending, receiving }



class HistoryTab extends StatefulWidget {

  const HistoryTab({super.key});



  @override

  State<HistoryTab> createState() => _HistoryTabState();

}



class _HistoryTabState extends State<HistoryTab> {

  _HistoryFilter _filter = _HistoryFilter.all;



  @override

  Widget build(BuildContext context) {

    final history = context.watch(historyProvider);

    final filtered = switch (_filter) {

      _HistoryFilter.all => history,

      _HistoryFilter.sending =>

        history.where((entry) => entry.direction == TransferDirection.sent).toList(),

      _HistoryFilter.receiving =>

        history.where((entry) => entry.direction == TransferDirection.received).toList(),

    };



    return ResponsiveListView(

      children: [

        SectionHeader(

          title: 'Transfers',

          trailing: history.isNotEmpty

              ? TextButton(

                  onPressed: () => _confirmClear(context),

                  child: const Text('Clear'),

                )

              : null,

        ),

        const SizedBox(height: 12),

        _HistoryFilterBar(
          selected: _filter,
          onChanged: (value) => setState(() => _filter = value),
        ),

        const SizedBox(height: 16),

        if (filtered.isEmpty)

          EmptyState(

            icon: Icons.swap_horiz,

            title: 'No transfers yet',

            subtitle: 'Sent and received files will appear here.',

          )

        else

          ...filtered.map((entry) => Padding(

                padding: const EdgeInsets.only(bottom: 12),

                child: _HistoryEntryCard(entry: entry),

              )),

      ],

    );

  }



  Future<void> _confirmClear(BuildContext context) async {

    final confirmed = await showDialog<bool>(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('Clear history?'),

        content: const Text('This removes all transfer history from this device.'),

        actions: [

          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),

          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),

        ],

      ),

    );



    if (confirmed == true && context.mounted) {

      await context.notifier(historyProvider).clearHistory();

    }

  }

}



class _HistoryEntryCard extends StatelessWidget {

  const _HistoryEntryCard({required this.entry});



  final TransferHistoryEntry entry;



  @override

  Widget build(BuildContext context) {

    final isSent = entry.direction == TransferDirection.sent;

    final canOpenFiles = !isSent &&

        entry.outcome == TransferOutcome.completed &&

        entry.files.any((file) => canOpenReceivedFile(file.path));



    return NetDropCard(

      padding: EdgeInsets.zero,

      child: Theme(

        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),

        child: ExpansionTile(

          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

          leading: Container(

            width: 44,

            height: 44,

            decoration: BoxDecoration(

              color: (isSent ? NetDropColors.primary : NetDropColors.iconVideos)

                  .withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(12),

            ),

            child: Icon(

              isSent ? Icons.upload_outlined : Icons.download_outlined,

              color: isSent ? NetDropColors.primary : NetDropColors.iconVideos,

            ),

          ),

          title: Text(
            entry.peerAlias,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          subtitle: Text(
            '${entry.files.length} file(s) · ${formatFileSize(entry.totalBytes)} · '
            '${formatHistoryTimestamp(entry.timestamp)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.nd.textSecondary, fontSize: 12),
          ),

          trailing: SizedBox(
            width: 84,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: StatusChip.outcome(context: context, outcome: entry.outcome),
              ),
            ),
          ),

          children: [

            _DetailRow(label: 'When', value: formatHistoryTimestamp(entry.timestamp)),

            _DetailRow(label: 'Direction', value: isSent ? 'Sent' : 'Received'),

            if (entry.peerIp != null) _DetailRow(label: 'Device', value: entry.peerIp!),

            const SizedBox(height: 8),

            Text('Files', style: Theme.of(context).textTheme.titleSmall),

            if (canOpenFiles)

              Padding(

                padding: const EdgeInsets.only(top: 4, bottom: 4),

                child: Text(

                  'Tap a file to open it.',

                  style: Theme.of(context).textTheme.bodySmall?.copyWith(

                        color: context.nd.textSecondary,

                      ),

                ),

              ),

            const SizedBox(height: 4),

            ...entry.files.map(
              (file) {
                final succeeded = entry.outcome == TransferOutcome.completed;
                final failed = entry.outcome == TransferOutcome.failed ||
                    entry.outcome == TransferOutcome.declined ||
                    entry.outcome == TransferOutcome.cancelled;

                return ReceivedFileListTile(
                  fileName: file.fileName,
                  fileType: file.fileType,
                  size: file.size,
                  savedPath: file.path,
                  completed: succeeded,
                  failed: failed,
                  inProgress: false,
                );
              },
            ),

            if (entry.error != null) ...[

              const SizedBox(height: 8),

              Text(

                friendlyErrorMessage(

                  entry.error,

                  context: entry.direction == TransferDirection.sent

                      ? UserMessageContext.send

                      : UserMessageContext.receive,

                ),

                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: NetDropColors.error),

              ),

            ],

          ],

        ),

      ),

    );

  }

}



class _DetailRow extends StatelessWidget {

  const _DetailRow({required this.label, required this.value});



  final String label;

  final String value;



  @override

  Widget build(BuildContext context) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 2),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          SizedBox(

            width: 72,

            child: Text(

              label,

              style: TextStyle(

                fontWeight: FontWeight.w500,

                color: context.nd.textSecondary,

              ),

            ),

          ),

          Expanded(
            child: Text(
              value,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        ],

      ),

    );

  }

}



class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.selected,
    required this.onChanged,
  });

  final _HistoryFilter selected;
  final ValueChanged<_HistoryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final filter in _HistoryFilter.values) ...[
          if (filter != _HistoryFilter.values.first) const SizedBox(width: 8),
          Expanded(
            child: _HistoryFilterChip(
              label: _labelFor(filter),
              selected: selected == filter,
              onTap: () => onChanged(filter),
            ),
          ),
        ],
      ],
    );
  }

  String _labelFor(_HistoryFilter filter) {
    return switch (filter) {
      _HistoryFilter.all => 'All',
      _HistoryFilter.sending => 'Sent',
      _HistoryFilter.receiving => 'Received',
    };
  }
}



class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }
}


