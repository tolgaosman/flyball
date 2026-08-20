import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Whether the platform/user has requested reduced motion.
bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

/// A fluid, spring-physics scale animation for tappable surfaces.
/// Emulates the high-quality interactions seen in premium iOS apps.
class SpringScale extends StatefulWidget {
  const SpringScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool enabled;

  @override
  State<SpringScale> createState() => _SpringScaleState();
}

class _SpringScaleState extends State<SpringScale> {
  bool _isPressed = false;
  bool get _active => widget.enabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? widget.pressedScale : 1.0;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _active ? (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      } : null,
      onTapCancel: _active ? () => setState(() => _isPressed = false) : null,
      onLongPress: widget.onLongPress,
      child: widget.child.animate(target: _isPressed ? 1 : 0)
          .scale(
            begin: const Offset(1, 1), 
            end: Offset(scale, scale),
            duration: AppTheme.durFast, 
            curve: AppTheme.springCurve,
          ),
    );
  }
}

/// A subtle, fluid entrance animation that fades and slides up.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppTheme.durSlow,
    this.offset = const Offset(0, 0.05), // Smaller, more subtle offset
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return child;
    
    return child
        .animate(delay: delay)
        .fade(duration: duration, curve: AppTheme.emphasized)
        .slide(
          begin: offset, 
          end: Offset.zero, 
          duration: duration, 
          curve: AppTheme.emphasized
        );
  }
}

/// A premium, bouncy pop effect for successful actions.
class SuccessPop extends StatelessWidget {
  const SuccessPop({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (trigger == null || _reduceMotion(context)) return child;

    return child.animate(key: ValueKey(trigger))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
        )
        .then()
        .scale(
          begin: const Offset(1.1, 1.1),
          end: const Offset(1, 1),
          duration: const Duration(milliseconds: 250),
          curve: AppTheme.springCurve, // Bouncy settle
        );
  }
}
