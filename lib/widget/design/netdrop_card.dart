import 'package:flutter/material.dart';
import 'package:netdrop/config/netdrop_theme_ext.dart';

class NetDropCard extends StatelessWidget {
  const NetDropCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nd = context.nd;
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: context.cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: context.isDarkMode ? Border.all(color: nd.border) : null,
        boxShadow: [
          BoxShadow(
            color: nd.cardShadow,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }
}
