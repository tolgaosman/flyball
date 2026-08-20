import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A premium, glassmorphic container replacing the old brutalist design.
///
/// Provides a sleek, soft elevated surface with subtle borders and 
/// beautiful diffuse shadows.
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
        color: color.withOpacity(0.9), // Slight translucency for depth
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor.withOpacity(0.3), 
          width: borderWidth,
        ),
        boxShadow: AppTheme.softShadow(elevation: elevation),
      ),
      child: child,
    );
  }
}
