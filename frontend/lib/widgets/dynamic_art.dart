import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/art/art_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Base widget for every dynamically-resolved image (club logo, league badge,
/// trophy). Resolves its URL once in [initState] (re-resolving only if the
/// lookup [key] changes), then renders it with [CachedNetworkImage] so a
/// second appearance anywhere in the app never re-fetches it. Falls back to a
/// [Monogram] while loading or when no image could be found — so a missing
/// badge never breaks layout the way a missing bundled asset would.
class _ResolvedImage extends StatefulWidget {
  const _ResolvedImage({
    required this.lookupKey,
    required this.resolve,
    required this.size,
    required this.monogramText,
  });

  /// Identifies what to fetch (e.g. the club name) — re-fetches on change.
  final String lookupKey;
  final Future<String?> Function() resolve;
  final double size;
  final String monogramText;

  @override
  State<_ResolvedImage> createState() => _ResolvedImageState();
}

class _ResolvedImageState extends State<_ResolvedImage> {
  Future<String?>? _future;

  @override
  void initState() {
    super.initState();
    _future = widget.resolve();
  }

  @override
  void didUpdateWidget(covariant _ResolvedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lookupKey != widget.lookupKey) {
      _future = widget.resolve();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.whiteMuted,
                ),
              ),
            ),
          );
        }
        final url = snapshot.data;
        if (url == null) {
          return Monogram(text: widget.monogramText, size: widget.size);
        }
        return CachedNetworkImage(
          imageUrl: url,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          fadeInDuration: AppTheme.durFast,
          placeholder: (_, _) => SizedBox(width: widget.size, height: widget.size),
          errorWidget: (_, _, _) => Monogram(text: widget.monogramText, size: widget.size),
        );
      },
    );
  }
}

/// A colour-block fallback showing a name's initials — used whenever a
/// dynamic logo/flag/trophy can't be resolved, so the layout never breaks the
/// way a missing bundled asset would.
class Monogram extends StatelessWidget {
  const Monogram({super.key, required this.text, required this.size});

  final String text;
  final double size;

  String get _initials {
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            _initials,
            style: AppTheme.heading(size * 0.4, color: AppColors.pitchGreen),
          ),
        ),
      ),
    );
  }
}

/// A club's badge, resolved dynamically by name. Set [enabled] to false while
/// a slot is mid-spin (rapidly cycling names) to skip the network entirely
/// and just show the [Monogram] — a spin can flash dozens of clubs a second,
/// and none of them are worth fetching art for.
class ClubLogo extends StatelessWidget {
  const ClubLogo({super.key, required this.clubName, this.size = 48, this.enabled = true});

  final String clubName;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return Monogram(text: clubName, size: size);
    return _ResolvedImage(
      lookupKey: 'club:$clubName',
      resolve: () => ArtResolver.instance.clubLogoUrl(clubName),
      size: size,
      monogramText: clubName,
    );
  }
}

/// A country's flag, resolved synchronously (flagcdn needs no lookup call).
class CountryFlag extends StatelessWidget {
  const CountryFlag({super.key, required this.countryName, this.size = 48, this.enabled = true});

  final String countryName;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return Monogram(text: countryName, size: size);
    final url = ArtResolver.instance.flagUrl(countryName);
    if (url == null) return Monogram(text: countryName, size: size);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.14),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size * 0.72,
        fit: BoxFit.cover,
        fadeInDuration: AppTheme.durFast,
        placeholder: (_, _) => SizedBox(width: size, height: size * 0.72),
        errorWidget: (_, _, _) => Monogram(text: countryName, size: size),
      ),
    );
  }
}

/// A domestic league's badge, resolved dynamically by name.
class LeagueBadge extends StatelessWidget {
  const LeagueBadge({super.key, required this.leagueName, this.size = 48});

  final String leagueName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _ResolvedImage(
      lookupKey: 'league:$leagueName',
      resolve: () => ArtResolver.instance.leagueBadgeUrl(leagueName),
      size: size,
      monogramText: leagueName,
    );
  }
}

/// An international tournament's trophy image, resolved dynamically by name.
class TrophyImage extends StatelessWidget {
  const TrophyImage({super.key, required this.tournamentName, this.size = 48});

  final String tournamentName;
  final double size;

  @override
  Widget build(BuildContext context) {
    return _ResolvedImage(
      lookupKey: 'trophy:$tournamentName',
      resolve: () => ArtResolver.instance.trophyUrl(tournamentName),
      size: size,
      monogramText: tournamentName,
    );
  }
}
