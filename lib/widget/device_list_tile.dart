import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';
import 'package:netdrop/model/device.dart';
import 'package:netdrop/util/device_helpers.dart';

class DeviceListTile extends StatelessWidget {
  const DeviceListTile({
    super.key,
    required this.device,
    required this.onTap,
    this.showOnline = true,
  });

  final Device device;
  final VoidCallback onTap;
  final bool showOnline;

  String get _subtitle {
    final model = device.deviceModel?.trim();
    if (model != null && model.isNotEmpty && model != device.alias) {
      return '$model · ${device.ip}';
    }
    return '${formatOsLabel(device.deviceModel)} · ${device.ip}';
  }

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final iconColor = deviceIconColor(device);

    return Material(
      color: context.cs.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: context.isDarkMode ? Border.all(color: nd.border) : null,
            boxShadow: [
              BoxShadow(
                color: nd.cardShadow,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(deviceIcon(device), color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.alias,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: nd.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                if (showOnline)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      color: NetDropColors.online,
                      shape: BoxShape.circle,
                    ),
                  ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: context.cs.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
