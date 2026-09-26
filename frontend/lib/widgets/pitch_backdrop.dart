import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wraps a screen with the shared "Night Pitch" backdrop: faint mown-grass
/// stripes, a barely-there football pitch line marking, and two soft
/// stadium-light glows — so every screen's background reads as the same
/// world instead of a flat charcoal void.
///
/// Painted once per screen (behind an opaque [Scaffold]), so wrapping every
/// route in [AppRoutes] keeps page transitions crisp with no cross-fade
/// bleed between an outgoing and incoming pitch.
class PitchBackdrop extends StatelessWidget {
  const PitchBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _PitchPainter()),
          ),
        ),
        child,
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    _paintGrassStripes(canvas, size);
    _paintPitchLines(canvas, size);
    _paintStadiumGlows(canvas, size);
  }

  void _paintGrassStripes(Canvas canvas, Size size) {
    const stripeHeight = 56.0;
    final paint = Paint()..color = AppColors.pitchGreen.withValues(alpha: 0.02);
    var y = 0.0;
    var lit = true;
    while (y < size.height) {
      if (lit) {
        canvas.drawRect(Rect.fromLTWH(0, y, size.width, stripeHeight), paint);
      }
      y += stripeHeight;
      lit = !lit;
    }
  }

  void _paintPitchLines(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const margin = 20.0;
    final pitch = Rect.fromLTWH(
      margin,
      margin,
      size.width - margin * 2,
      size.height - margin * 2,
    );

    // Outer boundary.
    canvas.drawRect(pitch, line);

    // Halfway line.
    final midY = pitch.top + pitch.height / 2;
    canvas.drawLine(Offset(pitch.left, midY), Offset(pitch.right, midY), line);

    // Centre circle + spot.
    final centre = Offset(pitch.center.dx, midY);
    final circleRadius = pitch.width * 0.16;
    canvas.drawCircle(centre, circleRadius, line);
    canvas.drawCircle(centre, 2.2, line..style = PaintingStyle.fill);
    line.style = PaintingStyle.stroke;

    // Penalty box + goal box + arc, mirrored top and bottom.
    final boxWidth = pitch.width * 0.56;
    final boxLeft = pitch.center.dx - boxWidth / 2;
    final penaltyDepth = pitch.height * 0.16;
    final goalBoxWidth = pitch.width * 0.28;
    final goalBoxLeft = pitch.center.dx - goalBoxWidth / 2;
    final goalDepth = pitch.height * 0.06;
    final arcRadius = pitch.width * 0.11;

    for (final atTop in [true, false]) {
      final baseY = atTop ? pitch.top : pitch.bottom;
      final penaltyY = atTop ? baseY + penaltyDepth : baseY - penaltyDepth;
      canvas.drawRect(
        Rect.fromLTRB(boxLeft, atTop ? baseY : penaltyY, boxLeft + boxWidth,
            atTop ? penaltyY : baseY),
        line,
      );

      final goalY = atTop ? baseY + goalDepth : baseY - goalDepth;
      canvas.drawRect(
        Rect.fromLTRB(goalBoxLeft, atTop ? baseY : goalY,
            goalBoxLeft + goalBoxWidth, atTop ? goalY : baseY),
        line,
      );

      final spotY = atTop ? baseY + penaltyDepth * 0.62 : baseY - penaltyDepth * 0.62;
      final arcCentre = Offset(pitch.center.dx, spotY);
      canvas.drawCircle(arcCentre, 2.0, Paint()..color = line.color);
      canvas.drawArc(
        Rect.fromCircle(center: arcCentre, radius: arcRadius),
        atTop ? 0.34 : 0.34 + 3.1416,
        2.46,
        false,
        line,
      );
    }
  }

  void _paintStadiumGlows(Canvas canvas, Size size) {
    final greenGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.pitchGreen.withValues(alpha: 0.12),
          AppColors.pitchGreen.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.08, size.height * 0.05),
          radius: size.longestSide * 0.45,
        ),
      );
    canvas.drawRect(Offset.zero & size, greenGlow);

    final goldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.08),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.95, size.height * 0.98),
          radius: size.longestSide * 0.5,
        ),
      );
    canvas.drawRect(Offset.zero & size, goldGlow);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) => false;
}
