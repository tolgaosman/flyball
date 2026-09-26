import 'package:flutter/material.dart';
import 'package:flyball_core/flyball_core.dart';

import '../theme/app_colors.dart';
import 'dynamic_art.dart';

/// Renders a Football XOX row/column [Factor] as its dynamic image (flag /
/// league badge / club badge / trophy) — falling back to a [Monogram] when
/// none resolves. A "won league" factor stacks a small trophy badge over the
/// league logo so it reads differently from "played in".
class FactorImage extends StatelessWidget {
  const FactorImage({super.key, required this.factor, this.imageSize = 42});

  final Factor factor;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    final Widget image = switch (factor.type) {
      FactorType.nationality => CountryFlag(countryName: factor.value, size: imageSize),
      FactorType.team => ClubLogo(clubName: factor.value, size: imageSize),
      FactorType.playedLeague => LeagueBadge(leagueName: factor.value, size: imageSize),
      FactorType.wonLeague => LeagueBadge(leagueName: factor.value, size: imageSize),
      FactorType.wonInternational => TrophyImage(tournamentName: factor.value, size: imageSize),
    };

    if (factor.type != FactorType.wonLeague) return image;

    // "Won" reads differently from "played in": stack a small trophy chip.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        image,
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLow,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 14, color: AppColors.gold),
          ),
        ),
      ],
    );
  }
}
