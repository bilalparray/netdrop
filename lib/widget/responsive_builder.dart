import 'package:flutter/material.dart';

class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) => MediaQuery.sizeOf(context).width < 700;
  static bool isDesktop(BuildContext context) => MediaQuery.sizeOf(context).width >= 800;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 800 && desktop != null) {
      return desktop!;
    }
    if (width >= 700 && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

class ResponsiveListView extends StatelessWidget {
  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: padding ?? const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}
