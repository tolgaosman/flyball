import 'dart:async';
import 'dart:convert';

import 'package:flyball_core/flyball_core.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Resolves club logos and league/trophy badges dynamically from
/// **TheSportsDB**'s free, keyless API — no bundled image assets, so growing
/// the club/country pool never means shipping more PNGs.
///
/// Every lookup is cached to [SharedPreferences] for 30 days (a badge/trophy
/// almost never changes), and concurrent requests for the same name are
/// collapsed into one HTTP call. Requests are also throttled a little, since
/// the free tier is rate-limited.
///
/// Country flags don't need this: [flagUrl] resolves synchronously from the
/// catalogue straight to a flagcdn.com URL (which needs no lookup at all).
class ArtResolver {
  ArtResolver._();
  static final ArtResolver instance = ArtResolver._();

  static const _apiBase = 'https://www.thesportsdb.com/api/v1/json/123';
  static const _cacheTtl = Duration(days: 30);
  static const _minRequestGap = Duration(milliseconds: 250);

  final http.Client _client = http.Client();
  final Map<String, Future<String?>> _inFlight = {};
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// The club badge URL for [clubName] (a canonical [ClubCatalog] name), or
  /// null if it isn't in the catalogue or no badge could be found.
  Future<String?> clubLogoUrl(String clubName) {
    final club = ClubCatalog.byName(clubName);
    if (club == null) return Future.value(null);
    return _cached('club:${club.name}', () => _fetchClubBadge(club));
  }

  /// The league badge URL for [leagueName], or null if unavailable.
  Future<String?> leagueBadgeUrl(String leagueName) {
    final comp = CompetitionCatalog.byName(leagueName);
    final id = comp?.sportsDbLeagueId;
    if (id == null) return Future.value(null);
    return _cached('league_badge:$leagueName', () => _fetchLeagueField(id, 'strBadge'));
  }

  /// The trophy image URL for [tournamentName], or null if unavailable.
  Future<String?> trophyUrl(String tournamentName) {
    final comp = CompetitionCatalog.byName(tournamentName);
    final id = comp?.sportsDbLeagueId;
    if (id == null) return Future.value(null);
    return _cached('trophy:$tournamentName', () => _fetchLeagueField(id, 'strTrophy'));
  }

  /// The flagcdn.com flag URL for [countryName] — synchronous, no network
  /// call needed to resolve the URL itself (the image still loads over the
  /// network, same as any other picture).
  String? flagUrl(String countryName) => CountryCatalog.flagUrl(countryName);

  Future<String?> _cached(String key, Future<String?> Function() fetch) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final ts = DateTime.fromMillisecondsSinceEpoch(decoded['ts'] as int);
        if (DateTime.now().difference(ts) < _cacheTtl) {
          return decoded['url'] as String?;
        }
      } catch (_) {
        // Corrupt cache entry — fall through and re-fetch.
      }
    }

    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = fetch().then((url) async {
      await prefs.setString(
        key,
        jsonEncode({'url': url, 'ts': DateTime.now().millisecondsSinceEpoch}),
      );
      return url;
    });
    _inFlight[key] = future;
    unawaited(future.whenComplete(() => _inFlight.remove(key)));
    return future;
  }

  Future<void> _throttle() async {
    final wait = _minRequestGap - DateTime.now().difference(_lastRequestAt);
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    _lastRequestAt = DateTime.now();
  }

  Future<String?> _fetchClubBadge(Club club) async {
    await _throttle();
    try {
      final uri = Uri.parse(
          '$_apiBase/searchteams.php?t=${Uri.encodeQueryComponent(club.sportsDbName)}');
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final teams = decoded['teams'] as List?;
      if (teams == null || teams.isEmpty) return null;

      Map<String, dynamic>? best;
      for (final raw in teams) {
        final team = raw as Map<String, dynamic>;
        if (team['strSport'] != 'Soccer') continue;
        best ??= team;
        if (_leagueMatches(team['strLeague'] as String? ?? '', club.league)) {
          best = team;
          break;
        }
      }
      return best?['strBadge'] as String?;
    } catch (_) {
      return null;
    }
  }

  bool _leagueMatches(String sportsDbLeague, String catalogLeague) {
    final l = sportsDbLeague.toLowerCase();
    switch (catalogLeague) {
      case ClubCatalog.premierLeague:
        return l.contains('premier league') && l.contains('english');
      case ClubCatalog.laLiga:
        return l.contains('la liga');
      case ClubCatalog.bundesliga:
        return l.contains('bundesliga');
      case ClubCatalog.serieA:
        return l.contains('serie a');
      case ClubCatalog.ligue1:
        return l.contains('ligue 1');
      case ClubCatalog.superLig:
        return l.contains('super lig');
      case ClubCatalog.saudiProLeague:
        return l.contains('saudi');
    }
    return false;
  }

  Future<String?> _fetchLeagueField(int leagueId, String field) async {
    await _throttle();
    try {
      final uri = Uri.parse('$_apiBase/lookupleague.php?id=$leagueId');
      final res = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      final leagues = decoded['leagues'] as List?;
      if (leagues == null || leagues.isEmpty) return null;
      final value = (leagues.first as Map<String, dynamic>)[field] as String?;
      return (value == null || value.isEmpty) ? null : value;
    } catch (_) {
      return null;
    }
  }
}
