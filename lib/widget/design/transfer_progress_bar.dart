import 'package:flutter/material.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';

class TransferProgressBar extends StatelessWidget {
  const TransferProgressBar({
    super.key,
    this.value,
    this.height = 10,
  });

  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        backgroundColor: nd.progressTrack,
        color: context.cs.primary,
      ),
    );
  }
}

class TransferProgressDisplay extends StatelessWidget {
  const TransferProgressDisplay({
    super.key,
    required this.progress,
    this.label,
    this.subtitle,
  });

  final double progress;
  final String? label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final percent = (progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      children: [
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.cs.primary,
              ),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: nd.textSecondary,
                ),
          ),
        ],
        const SizedBox(height: 20),
        TransferProgressBar(value: progress),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: nd.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}
