import 'dart:math';

import '../catalog/clubs.dart';
import '../catalog/competitions.dart';
import '../catalog/countries.dart';
import 'factor.dart';

/// The catalogue of all possible XOX factors plus axis-rule sampling.
///
/// [pickSixUnique] / [pickAxisValidSix] draw six unique factors (three rows +
/// three columns) that obey [axesAreValid] — the historical/logical
/// constraints that keep every one of the 9 resulting cells *askable* (e.g.
/// never a nationality crossing a nationality, never a Euros-winner crossing
/// a Copa-América-winner). Whether a cell actually *has* an answer is
/// verified separately, by the AI board builder — this class only encodes the
/// rules that are true by construction.
class FactorPool {
  FactorPool._();

  static const List<String> leagues = ClubCatalog.leagues;

  static final List<String> internationalTournaments = [
    for (final c in CompetitionCatalog.internationalTournaments) c.name,
  ];

  /// Every club across all seven leagues.
  static final List<String> teams = ClubCatalog.names;

  /// Every nationality in the catalogue.
  static final List<String> nationalities = CountryCatalog.names;

  /// Builds the full flat pool of selectable factors.
  static List<Factor> allFactors() {
    final factors = <Factor>[];

    for (final league in leagues) {
      factors.add(Factor(
        type: FactorType.playedLeague,
        label: 'Played in $league',
        value: league,
      ));
      factors.add(Factor(
        type: FactorType.wonLeague,
        label: 'Won $league',
        value: league,
      ));
    }

    for (final tournament in internationalTournaments) {
      factors.add(Factor(
        type: FactorType.wonInternational,
        label: 'Won $tournament',
        value: tournament,
      ));
    }

    for (final team in teams) {
      factors.add(Factor(
        type: FactorType.team,
        label: 'Played for $team',
        value: team,
      ));
    }

    for (final country in nationalities) {
      factors.add(Factor(
        type: FactorType.nationality,
        label: country,
        value: country,
      ));
    }

    return factors;
  }

  /// Draws six unique factors (reject-sampled until [axesAreValid] holds for
  /// the 3/3 split), splitting them into (rows, columns). Bounded by
  /// [maxAttempts]; if none is found in that budget, returns an arbitrary
  /// (still six-unique) split rather than looping forever.
  static ({List<Factor> rows, List<Factor> columns}) pickAxisValidSix(
    Random rng, {
    int maxAttempts = 500,
  }) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final chosen = pickSixUnique(rng);
      final r = chosen.sublist(0, 3);
      final c = chosen.sublist(3, 6);
      if (axesAreValid(r, c)) return (rows: r, columns: c);
    }
    final chosen = pickSixUnique(rng);
    return (rows: chosen.sublist(0, 3), columns: chosen.sublist(3, 6));
  }

  /// Six distinct factors drawn from a shuffled pool. Because [Factor]
  /// equality is by (type, value) and the pool has no duplicates, the first
  /// six distinct entries are unique.
  static List<Factor> pickSixUnique(Random rng) {
    final pool = allFactors()..shuffle(rng);
    final chosen = <Factor>[];
    final seen = <Factor>{};
    for (final factor in pool) {
      if (seen.add(factor)) {
        chosen.add(factor);
        if (chosen.length == 6) break;
      }
    }
    return chosen;
  }

  /// A nationality on a row crossing a nationality on a column (and likewise
  /// two international-tournament factors) would produce impossible cells. So
  /// the row set and column set must not BOTH contain a nationality, nor BOTH
  /// contain an international tournament. (Two of the same group on the
  /// *same* axis is fine — those headers never intersect each other.)
  static bool axesAreValid(List<Factor> rows, List<Factor> columns) {
    final rowsHaveNation = rows.any((f) => f.isNationality);
    final colsHaveNation = columns.any((f) => f.isNationality);
    if (rowsHaveNation && colsHaveNation) return false;

    final rowsHaveIntl = rows.any((f) => f.isInternational);
    final colsHaveIntl = columns.any((f) => f.isInternational);
    if (rowsHaveIntl && colsHaveIntl) return false;

    // Never put Euros AND Copa America on the same board — no player can win both.
    final allFactors = [...rows, ...columns];
    final hasEuros = allFactors.any(
        (f) => f.type == FactorType.wonInternational && f.value == 'Euros');
    final hasCopa = allFactors.any((f) =>
        f.type == FactorType.wonInternational && f.value == 'Copa America');
    if (hasEuros && hasCopa) return false;

    // Check all 9 intersections to ensure they are historically possible.
    for (final row in rows) {
      for (final col in columns) {
        if (!isCellPossible(row, col)) return false;
      }
    }

    return true;
  }

  static bool isCellPossible(Factor a, Factor b) {
    if (a.type == FactorType.nationality &&
        b.type == FactorType.wonInternational) {
      return _canNationalityWinTournament(a.value, b.value);
    }
    if (b.type == FactorType.nationality &&
        a.type == FactorType.wonInternational) {
      return _canNationalityWinTournament(b.value, a.value);
    }
    return true;
  }

  /// European nationalities (eligible for Euros).
  static const _europeanNations = {
    'France', 'Spain', 'Germany', 'Italy', 'England', 'Portugal',
    'Netherlands', 'Belgium', 'Croatia', 'Switzerland', 'Denmark',
    'Austria', 'Poland', 'Sweden', 'Czechia', 'Hungary', 'Scotland',
    'Wales', 'Serbia', 'Romania', 'Greece', 'Slovakia', 'Slovenia',
    'Bosnia', 'Albania', 'Ireland', 'N. Ireland',
    'Finland', 'Norway', 'Ukraine', 'Russia', 'Turkiye', 'Georgia',
    'Montenegro', 'Bulgaria', 'Kosovo', 'Cyprus', 'Luxembourg', 'Armenia',
    'Azerbaijan', 'Moldova', 'Israel', 'Latvia', 'Lithuania', 'Estonia',
    'Malta', 'Belarus',
  };

  /// South/Central/North American nationalities (eligible for Copa America).
  static const _americanNations = {
    'Argentina', 'Brazil', 'Uruguay', 'Colombia', 'Ecuador', 'Chile',
    'Paraguay', 'Peru', 'Venezuela', 'Bolivia', 'Mexico', 'USA', 'Canada',
    'Costa Rica', 'Honduras', 'Jamaica', 'Panama',
  };

  static bool _canNationalityWinTournament(
      String nationality, String tournament) {
    if (tournament == 'World Cup') {
      const winners = {
        'Argentina', 'Brazil', 'France', 'Germany',
        'Italy', 'Spain', 'Uruguay', 'England',
      };
      return winners.contains(nationality);
    }
    if (tournament == 'Euros') {
      if (!_europeanNations.contains(nationality)) return false;
      const winners = {
        'Germany', 'Spain', 'Italy', 'France', 'Portugal',
        'Netherlands', 'Denmark', 'Greece', 'Czechia', 'Russia',
      };
      return winners.contains(nationality);
    }
    if (tournament == 'Copa America') {
      if (!_americanNations.contains(nationality)) return false;
      const winners = {
        'Argentina', 'Brazil', 'Uruguay', 'Colombia', 'Chile', 'Peru',
        'Paraguay',
      };
      return winners.contains(nationality);
    }
    return true;
  }
}
