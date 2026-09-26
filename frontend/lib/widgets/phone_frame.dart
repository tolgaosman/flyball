import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A widget that wraps the application in a realistic mobile device frame
/// when viewed on desktop web or large screens, ensuring a consistent mobile
/// experience.
///
/// Rendered in the "Night Pitch" language: a soft-bezel phone floating over a
/// warm dark backdrop lit by two faint colour glows (pitch green + gold),
/// matching the in-app surfaces instead of the old brutalist hard-shadow chrome.
class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    // If screen is narrow (mobile device size), render the app directly without frame.
    if (screenWidth <= 600) {
      return child;
    }

    // Phone dimensions
    const double phoneWidth = 390.0;
    const double phoneHeight = 844.0;
    const double borderRadius = 44.0;
    const double borderWidth = 10.0;

    // Handle vertical scaling for shorter displays
    final double targetHeight = phoneHeight + 60.0; // App height + padding
    final double scale = screenHeight < targetHeight
        ? (screenHeight / targetHeight) * 0.95
        : 1.0;

    // Inner dimensions of the simulated screen
    const double innerWidth = phoneWidth - (2 * borderWidth);
    const double innerHeight = phoneHeight - (2 * borderWidth);

    // Override the child's MediaQuery so it behaves exactly like a real mobile screen size.
    final mediaQueryData = MediaQuery.of(context);
    final simulatedMediaQuery = mediaQueryData.copyWith(
      size: const Size(innerWidth, innerHeight),
      padding: const EdgeInsets.only(top: 44, bottom: 34),
      viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
      viewInsets: EdgeInsets.zero,
    );

    final Widget phoneBody = Container(
      width: phoneWidth,
      height: phoneHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderHigh, width: borderWidth),
        boxShadow: AppTheme.glowShadow(AppColors.pitchGreen, elevation: 2.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        child: Stack(
          children: [
            // The actual application
            Positioned.fill(
              child: MediaQuery(data: simulatedMediaQuery, child: child),
            ),

            // Simulated Mobile Status Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 44,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '9:41',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_4_bar,
                            color: AppColors.white,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, color: AppColors.white, size: 13),
                          SizedBox(width: 4),
                          Icon(
                            Icons.battery_full,
                            color: AppColors.white,
                            size: 13,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Simulated Camera Notch (Dynamic Island style)
            Positioned(
              top: 8,
              left: (innerWidth - 110) / 2,
              child: IgnorePointer(
                child: Container(
                  width: 110,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF151515),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Simulated iOS Home Indicator Bar
            Positioned(
              bottom: 8,
              left: (innerWidth - 140) / 2,
              child: IgnorePointer(
                child: Container(
                  width: 140,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // Header/footer chrome is laid out in a Column *around* the phone (not
    // absolutely positioned over it), so on narrower desktop windows they
    // stack above/below instead of overlapping the phone body.
    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      body: Stack(
        children: [
          // Warm dark backdrop, softly lit by two faint colour glows instead
          // of a flat neon dot grid.
          const Positioned.fill(child: _NightBackdrop()),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header title chip
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: AppColors.pitchGreen.withValues(alpha: 0.5),
                        ),
                        boxShadow: AppTheme.glowShadow(
                          AppColors.pitchGreen,
                          elevation: 0.4,
                        ),
                      ),
                      child: Text(
                        'FLYBALL',
                        style:
                            AppTheme.heading(18, color: AppColors.pitchGreen)
                                .copyWith(letterSpacing: 1.2),
                      ),
                    ),
                    Text(
                      'Web Simulator',
                      style: AppTheme.body(color: AppColors.whiteMuted),
                    ),
                  ],
                ),

                // Phone body, centred in the remaining space.
                Expanded(
                  child: Center(
                    child: scale == 1.0
                        ? phoneBody
                        : Transform.scale(scale: scale, child: phoneBody),
                  ),
                ),

                // bottom instructions info card
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppTheme.softShadow(elevation: 0.6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.devices_rounded,
                            color: AppColors.pitchGreen, size: 18),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Runs in native mobile layouts. Resize the window to test the mobile view directly.',
                            style: AppTheme.caption(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A warm, dark canvas softly lit by two faint radial colour glows (pitch
/// green top-left, gold bottom-right) over a faint dot texture.
class _NightBackdrop extends StatelessWidget {
  const _NightBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surfaceLow),
      child: CustomPaint(painter: _NightBackdropPainter()),
    );
  }
}

class _NightBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Faint dot texture.
    final dotPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.025)
      ..strokeWidth = 2;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, dotPaint);
      }
    }

    // Ambient glows.
    final greenGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.pitchGreen.withValues(alpha: 0.16),
          AppColors.pitchGreen.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.12, size.height * 0.08),
          radius: size.longestSide * 0.5,
        ),
      );
    canvas.drawRect(Offset.zero & size, greenGlow);

    final goldGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.gold.withValues(alpha: 0.12),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width * 0.92, size.height * 0.95),
          radius: size.longestSide * 0.55,
        ),
      );
    canvas.drawRect(Offset.zero & size, goldGlow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
