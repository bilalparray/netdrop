import 'package:flutter/material.dart';
import 'package:netdrop/config/assets.dart';

class NetDropLogo extends StatelessWidget {
  const NetDropLogo({
    super.key,
    this.size = 48,
    this.borderRadius,
  });

  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);

    return ClipRRect(
      borderRadius: radius,
      child: Image.asset(
        AppAssets.netdropBrand,
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'NetDrop',
      ),
    );
  }
}

class NetDropBrandLockup extends StatelessWidget {
  const NetDropBrandLockup({
    super.key,
    this.logoSize = 120,
    this.subtitle,
  });

  final double logoSize;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NetDropLogo(size: logoSize),
        if (subtitle != null) ...[
          const SizedBox(height: 16),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
