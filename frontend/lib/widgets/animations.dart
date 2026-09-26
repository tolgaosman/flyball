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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _active ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: _active ? (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      } : null,
      onTapCancel: _active ? () => setState(() => _isPressed = false) : null,
      onLongPress: widget.onLongPress,
      // `begin`/`end` are the fixed endpoints for target 0/1 — they must NOT
      // depend on `_isPressed` themselves, or the release animation has no
      // real span to interpolate over and just snaps back instead of
      // springing. Only `target` (which endpoint we're animating toward)
      // changes with press state.
      child: widget.child.animate(target: _isPressed ? 1 : 0)
          .scale(
            begin: const Offset(1, 1),
            end: Offset(widget.pressedScale, widget.pressedScale),
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

/// A premium, bouncy pop effect for successful actions: scales up then
/// settles back to its resting size every time [trigger] changes.
///
/// Implemented as a single [TweenSequence]-driven [ScaleTransition] rather
/// than flutter_animate's `.scale().then().scale()` chaining: that chains two
/// SEPARATE nested scale transforms, and each one holds its own end value once
/// its slice of the timeline finishes — so by the end both are still applied
/// and compose MULTIPLICATIVELY (1.1 × 1.0 done at 1.1, not 1.0), leaving the
/// child permanently ~10% oversized. A single tween has only one transform in
/// the tree, so it can only ever end exactly where it's told to (1.0).
class SuccessPop extends StatefulWidget {
  const SuccessPop({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<SuccessPop> createState() => _SuccessPopState();
}

class _SuccessPopState extends State<SuccessPop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _scale;

  static final TweenSequence<double> _sequence = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 1.1).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 150,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: AppTheme.springCurve)),
      weight: 250,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = _sequence.animate(_controller);
  }

  @override
  void didUpdateWidget(covariant SuccessPop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null &&
        widget.trigger != oldWidget.trigger &&
        !_reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trigger == null || _reduceMotion(context)) return widget.child;
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
