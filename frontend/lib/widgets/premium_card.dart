import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// The primary "Night Pitch" surface container.
///
/// A warm, softly elevated card with a visible-but-soft border and a
/// diffuse floating shadow.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.shadowColor = AppColors.black,
    this.borderWidth = 1.0,
    this.radius = AppTheme.radius,
    this.shadowOffset = Offset.zero, // Deprecated in premium theme
    this.soft = true,
    this.elevation = 1,
    this.padding,
    this.width,
    this.height,
    this.alignment,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final Color shadowColor;
  final double borderWidth;
  final double radius;
  final Offset shadowOffset;
  final bool soft;
  final double elevation;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    // We ignore the brutalist hard shadow properties and use the soft,
    // premium shadow from the new AppTheme instead.
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.92), // Slight translucency for depth
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.5),
          width: borderWidth,
        ),
        boxShadow: AppTheme.softShadow(elevation: elevation),
      ),
      child: child,
    );
  }
}
