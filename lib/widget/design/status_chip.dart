import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/model/transfer_history_entry.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
  });

  factory StatusChip.outcome({
    Key? key,
    required BuildContext context,
    required TransferOutcome outcome,
  }) {
    final nd = context.nd;
    final (label, color) = switch (outcome) {
      TransferOutcome.completed => ('Completed', context.cs.primary),
      TransferOutcome.cancelled => ('Cancelled', nd.textMuted),
      TransferOutcome.failed => ('Failed', NetDropColors.error),
      TransferOutcome.declined => ('Declined', NetDropColors.warning),
    };
    return StatusChip(
      key: key,
      label: label,
      color: color,
      backgroundColor: color.withValues(alpha: 0.12),
    );
  }

  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
