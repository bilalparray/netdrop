import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/model/cross_file.dart';
import 'package:netdrop/util/file_type_visuals.dart';
import 'package:netdrop/util/format_helpers.dart';
import 'package:netdrop/widget/design/netdrop_card.dart';

class SelectedFilesPanel extends StatelessWidget {
  const SelectedFilesPanel({
    super.key,
    required this.files,
    required this.onRemove,
    required this.onClearAll,
  });

  final List<CrossFile> files;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final totalBytes = files.fold<int>(0, (sum, file) => sum + file.size);
    final fileLabel = files.length == 1 ? '1 file ready' : '${files.length} files ready';

    return NetDropCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: NetDropColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.upload_file_outlined,
              color: NetDropColors.primary,
            ),
          ),
          title: Text(
            fileLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            formatFileSize(totalBytes),
            style: TextStyle(color: context.nd.textSecondary, fontSize: 12),
          ),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear all'),
                style: TextButton.styleFrom(
                  foregroundColor: context.nd.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
            for (var i = 0; i < files.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: context.nd.border.withValues(alpha: 0.6),
                ),
              _SelectedFileRow(
                file: files[i],
                onRemove: () => onRemove(files[i].id),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectedFileRow extends StatelessWidget {
  const _SelectedFileRow({
    required this.file,
    required this.onRemove,
  });

  final CrossFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isTextMessage = isTextMessageFile(
      file.fileName,
      file.fileType,
      isInMemory: file.isInMemory,
    );
    final iconColor = isTextMessage
        ? NetDropColors.iconDocuments
        : fileIconColorFor(file.fileName, file.fileType);
    final icon = isTextMessage
        ? Icons.message_outlined
        : fileIconFor(file.fileName, file.fileType);
    final title = isTextMessage ? 'Text message' : file.fileName;
    final subtitle = isTextMessage ? _textPreview(file) : formatFileSize(file.size);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        maxLines: isTextMessage ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.nd.textSecondary, fontSize: 12),
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 20, color: context.nd.textSecondary),
        tooltip: 'Remove',
        onPressed: onRemove,
      ),
    );
  }

  String _textPreview(CrossFile file) {
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return formatFileSize(file.size);
    }

    final text = utf8.decode(bytes).trim();
    if (text.isEmpty) {
      return 'Empty message';
    }
    if (text.length <= 80) {
      return text;
    }
    return '${text.substring(0, 80)}…';
  }
}
