import 'package:flyball_core/flyball_core.dart';
import 'package:test/test.dart';

void main() {
  group('ClubCatalog', () {
    test('has exactly seven leagues', () {
      expect(ClubCatalog.leagues.length, 7);
    });

    test('every club name is unique across the whole catalogue', () {
      final names = ClubCatalog.names;
      expect(names.toSet().length, names.length);
    });

    test('every league has at least 12 clubs', () {
      for (final league in ClubCatalog.leagues) {
        expect(ClubCatalog.clubsInLeague(league).length, greaterThanOrEqualTo(12),
            reason: '$league should have a reasonably wide pool');
      }
    });

    test('byName resolves the club to its declared league', () {
      final club = ClubCatalog.byName('Galatasaray');
      expect(club, isNotNull);
      expect(club!.league, ClubCatalog.superLig);
    });

    test('Saudi Pro League is included (previously missing)', () {
      expect(ClubCatalog.leagues, contains(ClubCatalog.saudiProLeague));
      expect(ClubCatalog.clubsInLeague(ClubCatalog.saudiProLeague), isNotEmpty);
    });
  });

  group('CountryCatalog', () {
    test('every country has a unique name', () {
      final names = CountryCatalog.names;
      expect(names.toSet().length, names.length);
    });

    test('is at least twice the size of the old 59-country pool', () {
      expect(CountryCatalog.all.length, greaterThan(110));
    });

    test('flagUrl resolves a known country to a flagcdn URL', () {
      expect(CountryCatalog.flagUrl('France'), contains('flagcdn.com'));
    });

    test('flagUrl returns null for an unknown country', () {
      expect(CountryCatalog.flagUrl('Narnia'), isNull);
    });
  });

  group('CompetitionCatalog', () {
    test('resolves a known league to its TheSportsDB id', () {
      final epl = CompetitionCatalog.byName(ClubCatalog.premierLeague);
      expect(epl?.sportsDbLeagueId, 4328);
    });
  });
}
