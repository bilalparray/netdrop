import 'package:flutter/material.dart';
import 'package:netdrop/config/assets.dart';
import 'package:netdrop/config/constants.dart';

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

class NetDropAppBarTitle extends StatelessWidget {
  const NetDropAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NetDropLogo(size: 36),
        const SizedBox(width: 12),
        Text(
          appDisplayName,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
        ),
      ],
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
