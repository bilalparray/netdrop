import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/util/file_type_visuals.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/util/format_helpers.dart';
import 'package:netdrop/util/open_file_helper.dart';

class ReceivedFileListTile extends StatelessWidget {
  const ReceivedFileListTile({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.size,
    required this.completed,
    this.savedPath,
    this.progress,
    this.failed = false,
    this.inProgress = false,
  });

  final String fileName;
  final String fileType;
  final int size;
  final String? savedPath;
  final bool completed;
  final bool failed;
  final bool inProgress;
  final double? progress;

  bool get _canOpen => completed && canOpenReceivedFile(savedPath);

  @override
  Widget build(BuildContext context) {
    final iconColor = fileIconColorFor(fileName, fileType);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: _canOpen || !completed,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(fileIconFor(fileName, fileType), size: 20, color: iconColor),
      ),
      title: Text(
        fileName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        inProgress && !completed && !failed && progress != null
            ? '${formatFileSize(size)} · ${(progress! * 100).toStringAsFixed(0)}%'
            : formatFileSize(size),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.nd.textSecondary, fontSize: 12),
      ),
      trailing: _buildTrailing(context),
      onTap: _canOpen ? () => _openFile(context) : null,
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (_canOpen) {
      return Icon(
        Icons.open_in_new,
        size: 18,
        color: context.cs.primary.withValues(alpha: 0.85),
      );
    }
    if (completed) {
      return const Icon(Icons.check_circle, color: NetDropColors.online, size: 20);
    }
    if (failed) {
      return const Icon(Icons.error_outline, color: NetDropColors.error, size: 20);
    }
    if (inProgress) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          value: progress != null && progress! > 0 ? progress : null,
        ),
      );
    }
    return null;
  }

  Future<void> _openFile(BuildContext context) async {
    final result = await openReceivedFile(
      location: savedPath,
      fileName: fileName,
      fileType: fileType,
    );

    if (!context.mounted) {
      return;
    }

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Could not open file')),
      );
    }
  }
}
