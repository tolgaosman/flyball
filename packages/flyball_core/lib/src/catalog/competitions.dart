import 'clubs.dart';

/// A domestic league or international tournament, with the TheSportsDB league
/// id used to fetch its badge/trophy image. A null [sportsDbLeagueId] means no
/// verified id exists (the art resolver falls back to a monogram/icon).
class Competition {
  const Competition(this.name, {this.sportsDbLeagueId});

  final String name;
  final int? sportsDbLeagueId;

  @override
  String toString() => name;
}

/// The domestic leagues and international tournaments used as XOX/party-game
/// factors, with their TheSportsDB league ids (verified against the live API)
/// for dynamic badge/trophy art.
class CompetitionCatalog {
  CompetitionCatalog._();

  static const List<Competition> leagues = [
    Competition(ClubCatalog.premierLeague, sportsDbLeagueId: 4328),
    Competition(ClubCatalog.laLiga, sportsDbLeagueId: 4335),
    Competition(ClubCatalog.bundesliga, sportsDbLeagueId: 4331),
    Competition(ClubCatalog.serieA, sportsDbLeagueId: 4332),
    Competition(ClubCatalog.ligue1, sportsDbLeagueId: 4334),
    Competition(ClubCatalog.superLig, sportsDbLeagueId: 4339),
    Competition(ClubCatalog.saudiProLeague, sportsDbLeagueId: 4668),
  ];

  static const List<Competition> internationalTournaments = [
    Competition('World Cup', sportsDbLeagueId: 4429),
    Competition('Euros', sportsDbLeagueId: 4502),
    Competition('Copa America'),
    Competition('Champions League', sportsDbLeagueId: 4480),
    Competition('Europa League', sportsDbLeagueId: 4481),
  ];

  static final Map<String, Competition> _byName = {
    for (final c in [...leagues, ...internationalTournaments]) c.name: c,
  };

  static Competition? byName(String name) => _byName[name];
}
