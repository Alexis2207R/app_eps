import 'package:flutter/material.dart';

class ResponsiveWidth extends StatelessWidget {
  final Widget child;
  final double? sm;
  final double? md;
  final double? lg;
  final double? xl;
  final double? xxl;

  const ResponsiveWidth({
    super.key,
    required this.child,
    this.sm,
    this.md,
    this.lg,
    this.xl,
    this.xxl,
  });

  // Breakpoints de ancho de pantalla en píxeles.
  static const double smBreakpoint = 640.0;
  static const double mdBreakpoint = 768.0;
  static const double lgBreakpoint = 1024.0;
  static const double xlBreakpoint = 1280.0;
  static const double xxlBreakpoint = 1536.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double width = MediaQuery.of(context).size.width;
        double? targetWidth;

        if (width >= xxlBreakpoint && xxl != null) {
          targetWidth = width * xxl!;
        } else if (width >= xlBreakpoint && xl != null) {
          targetWidth = width * xl!;
        } else if (width >= lgBreakpoint && lg != null) {
          targetWidth = width * lg!;
        } else if (width >= mdBreakpoint && md != null) {
          targetWidth = width * md!;
        } else if (width >= smBreakpoint && sm != null) {
          targetWidth = width * sm!;
        }

        // Si no se definió un ancho específico, el ancho es el 100%
        return Center(
          child: SizedBox(
            width: targetWidth ?? width,
            child: child,
          ),
        );
      },
    );
  }
}
