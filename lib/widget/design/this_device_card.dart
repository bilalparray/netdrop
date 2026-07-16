import 'package:flutter/material.dart';
import 'package:netdrop/config/app_colors.dart';
import 'package:netdrop/model/device.dart';

class ThisDeviceCard extends StatelessWidget {
  const ThisDeviceCard({
    super.key,
    required this.alias,
    required this.deviceType,
    required this.osLabel,
    this.ipAddress,
  });

  final String alias;
  final DeviceType deviceType;
  final String osLabel;
  final String? ipAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: NetDropColors.gradientPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: NetDropColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              deviceType == DeviceType.mobile ? Icons.smartphone : Icons.laptop_mac,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This device',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  alias,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  ipAddress != null ? '$osLabel · $ipAddress' : osLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
