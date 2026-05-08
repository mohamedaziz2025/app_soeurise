import 'package:flutter/material.dart';

class Responsive {
  static const double tabletBreakpoint = 700;
  static const double desktopBreakpoint = 1000;
  static const double maxContentWidthTablet = 720;
  static const double maxContentWidthDesktop = 900;
  static const double minHorizontalPadding = 16;

  static bool isNarrow(BuildContext context, {double breakpoint = 520}) {
    return MediaQuery.of(context).size.width < breakpoint;
  }

  static double maxContentWidth(BuildContext context, {double? override}) {
    if (override != null) return override;
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return maxContentWidthDesktop;
    if (width >= tabletBreakpoint) return maxContentWidthTablet;
    return width;
  }

  static double sidePadding(
    BuildContext context, {
    double? maxWidth,
    double min = minHorizontalPadding,
  }) {
    final width = MediaQuery.of(context).size.width;
    final targetWidth = maxWidth ?? maxContentWidth(context);
    if (width <= targetWidth + (min * 2)) {
      return min;
    }
    return (width - targetWidth) / 2;
  }

  static EdgeInsets contentPadding(
    BuildContext context, {
    double? maxWidth,
    double horizontal = minHorizontalPadding,
    double vertical = 0,
  }) {
    final side = sidePadding(
      context,
      maxWidth: maxWidth,
      min: horizontal,
    );
    return EdgeInsets.symmetric(horizontal: side, vertical: vertical);
  }

  static double messageMaxWidth(BuildContext context, {double max = 420}) {
    final width = MediaQuery.of(context).size.width * 0.75;
    return width > max ? max : width;
  }

  static double sheetHeight(
    BuildContext context, {
    double fraction = 0.7,
    double min = 420,
    double max = 640,
  }) {
    final height = MediaQuery.of(context).size.height * fraction;
    if (height < min) return min;
    if (height > max) return max;
    return height;
  }
}

class ResponsiveConstrained extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final Alignment alignment;

  const ResponsiveConstrained({
    super.key,
    required this.child,
    required this.maxWidth,
    this.padding = EdgeInsets.zero,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
