import 'package:flutter/material.dart';

/// Scales [child] uniformly to fit whatever space it's given, instead of
/// scrolling or overflowing: [child] is authored at [designWidth] logical
/// pixels wide (a typical phone width) with a natural height, then that
/// whole block is scaled down on small screens and up on big ones so every
/// device sees the same layout — just smaller or bigger — rather than a
/// scrollbar on tiny phones and wasted blank space on tablets.
///
/// The wrapped content's outer `Column`/`Row` must use
/// `mainAxisSize: MainAxisSize.min` (its height is measured, not imposed).
class ScreenFit extends StatelessWidget {
  const ScreenFit({
    super.key,
    required this.child,
    this.designWidth = 390,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final double designWidth;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      alignment: alignment,
      child: SizedBox(width: designWidth, child: child),
    );
  }
}
