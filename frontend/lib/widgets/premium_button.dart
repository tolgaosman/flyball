import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A premium, Emil Kowalski inspired button replacing the brutalist one.
///
/// Features a gorgeous spring physics scale down on press, soft haptics,
/// and smooth background color transitions.
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = AppColors.pitchGreen,
    this.foregroundColor = AppColors.white,
    this.borderColor = Colors.transparent,
    this.shadowColor = Colors.transparent,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    this.radius = AppTheme.radius,
    this.restingOffset = Offset.zero,
    this.expand = true,
    this.haptics = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color color;
  final Color foregroundColor;
  final Color borderColor;
  final Color shadowColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Offset restingOffset;
  final bool expand;
  final bool haptics;

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _isPressed = false;

  bool get _enabled => widget.onPressed != null;

  void _handleTapDown(TapDownDetails details) {
    if (!_enabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_enabled) return;
    setState(() => _isPressed = false);
    if (widget.haptics) HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  void _handleTapCancel() {
    if (!_enabled) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final Color faceColor =
        _enabled ? widget.color : AppColors.surfaceLow;
        
    final Color contentColor = 
        _enabled ? widget.foregroundColor : AppColors.textMuted;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: AppTheme.springCurve,
        width: widget.expand ? double.infinity : null,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(widget.radius),
          border: widget.borderColor != Colors.transparent 
              ? Border.all(color: widget.borderColor, width: 1.0)
              : null,
          boxShadow: _isPressed ? [] : AppTheme.softShadow(elevation: 0.5),
        ),
        child: DefaultTextStyle.merge(
          style: AppTheme.heading(16, color: contentColor),
          textAlign: TextAlign.center,
          child: IconTheme.merge(
            data: IconThemeData(color: contentColor, size: 20),
            child: Center(
              widthFactor: widget.expand ? null : 1, 
              child: widget.child,
            ),
          ),
        ),
      ).animate(target: _isPressed ? 1 : 0)
       .scale(
         begin: const Offset(1, 1), 
         end: const Offset(0.95, 0.95),
         duration: const Duration(milliseconds: 150),
         curve: AppTheme.springCurve,
       ),
    );
  }
}
