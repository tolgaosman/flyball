/// A club in the Flyball catalogue.
///
/// [name] is the canonical display/AI-prompt name. [sportsDbName] is the query
/// string used against TheSportsDB's `searchteams.php` when it differs from
/// [name] (disambiguates clubs TheSportsDB indexes under another spelling).
/// [aliases] are additional lowercase name forms (e.g. "man utd") the AI
/// prompts treat as the same club, and that free-text matching can use.
class Club {
  const Club(
    this.name,
    this.league, {
    String? sportsDbName,
    this.aliases = const [],
  }) : sportsDbName = sportsDbName ?? name;

  final String name;
  final String league;
  final String sportsDbName;
  final List<String> aliases;

  @override
  String toString() => name;
}

/// The seven leagues Flyball draws its club pool from, plus the fixed club
/// roster for each. Kept as one source of truth so the frontend, backend and
/// AI prompts never disagree on a club's canonical name or league.
class ClubCatalog {
  ClubCatalog._();

  static const String premierLeague = 'Premier League';
  static const String laLiga = 'La Liga';
  static const String bundesliga = 'Bundesliga';
  static const String serieA = 'Serie A';
  static const String ligue1 = 'Ligue 1';
  static const String superLig = 'Süper Lig';
  static const String saudiProLeague = 'Roshn Saudi Pro League';

  /// The seven leagues, in display order.
  static const List<String> leagues = [
    premierLeague,
    laLiga,
    bundesliga,
    serieA,
    ligue1,
    superLig,
    saudiProLeague,
  ];

  static const List<Club> premierLeagueClubs = [
    Club('Arsenal', premierLeague),
    Club('Aston Villa', premierLeague),
    Club('Bournemouth', premierLeague, sportsDbName: 'AFC Bournemouth'),
    Club('Brentford', premierLeague),
    Club('Brighton', premierLeague, sportsDbName: 'Brighton and Hove Albion'),
    Club('Burnley', premierLeague),
    Club('Chelsea', premierLeague),
    Club('Crystal Palace', premierLeague),
    Club('Everton', premierLeague),
    Club('Fulham', premierLeague),
    Club('Leeds United', premierLeague),
    Club('Liverpool', premierLeague),
    Club('Manchester City', premierLeague, aliases: ['man city']),
    Club('Manchester United', premierLeague, aliases: ['man utd', 'man united']),
    Club('Newcastle United', premierLeague, aliases: ['newcastle']),
    Club('Nottingham Forest', premierLeague),
    Club('Sunderland', premierLeague),
    Club('Tottenham Hotspur', premierLeague, aliases: ['spurs', 'tottenham']),
    Club('West Ham United', premierLeague, aliases: ['west ham']),
    Club('Wolverhampton Wanderers', premierLeague, aliases: ['wolves']),
  ];

  static const List<Club> laLigaClubs = [
    Club('Alaves', laLiga, sportsDbName: 'Deportivo Alaves'),
    Club('Athletic Bilbao', laLiga, aliases: ['athletic club']),
    Club('Atletico Madrid', laLiga, sportsDbName: 'Atlético Madrid'),
    Club('Barcelona', laLiga, sportsDbName: 'FC Barcelona'),
    Club('Real Betis', laLiga, aliases: ['betis']),
    Club('Celta Vigo', laLiga, sportsDbName: 'Celta de Vigo'),
    Club('Elche', laLiga),
    Club('Espanyol', laLiga, sportsDbName: 'RCD Espanyol'),
    Club('Getafe', laLiga),
    Club('Girona', laLiga),
    Club('Levante', laLiga),
    Club('Mallorca', laLiga, sportsDbName: 'RCD Mallorca'),
    Club('Osasuna', laLiga, sportsDbName: 'CA Osasuna'),
    Club('Rayo Vallecano', laLiga),
    Club('Real Madrid', laLiga),
    Club('Real Oviedo', laLiga),
    Club('Real Sociedad', laLiga),
    Club('Sevilla', laLiga, sportsDbName: 'Sevilla FC'),
    Club('Valencia', laLiga, sportsDbName: 'Valencia CF'),
    Club('Villarreal', laLiga, sportsDbName: 'Villarreal CF'),
  ];

  static const List<Club> bundesligaClubs = [
    Club('Bayern Munich', bundesliga, sportsDbName: 'Bayern Munich'),
    Club('Borussia Dortmund', bundesliga, aliases: ['bvb', 'dortmund']),
    Club('RB Leipzig', bundesliga, aliases: ['leipzig']),
    Club('Bayer Leverkusen', bundesliga, aliases: ['leverkusen']),
    Club('Eintracht Frankfurt', bundesliga, aliases: ['frankfurt']),
    Club('VfL Wolfsburg', bundesliga, aliases: ['wolfsburg']),
    Club('Borussia Monchengladbach', bundesliga,
        sportsDbName: 'Borussia Monchengladbach', aliases: ['gladbach']),
    Club('VfB Stuttgart', bundesliga, aliases: ['stuttgart']),
    Club('Werder Bremen', bundesliga, aliases: ['bremen']),
    Club('Union Berlin', bundesliga, sportsDbName: '1. FC Union Berlin'),
    Club('Freiburg', bundesliga, sportsDbName: 'SC Freiburg'),
    Club('Mainz 05', bundesliga, sportsDbName: '1. FSV Mainz 05'),
    Club('Augsburg', bundesliga, sportsDbName: 'FC Augsburg'),
    Club('Hoffenheim', bundesliga, sportsDbName: 'TSG 1899 Hoffenheim'),
    Club('Heidenheim', bundesliga, sportsDbName: '1. FC Heidenheim'),
    Club('FC Koln', bundesliga, sportsDbName: '1. FC Koln', aliases: ['cologne']),
    Club('St Pauli', bundesliga, sportsDbName: 'FC St. Pauli'),
    Club('Hamburger SV', bundesliga, aliases: ['hamburg']),
  ];

  static const List<Club> serieAClubs = [
    Club('Juventus', serieA),
    Club('Inter Milan', serieA, sportsDbName: 'Inter Milan', aliases: ['inter', 'internazionale']),
    Club('AC Milan', serieA, aliases: ['milan']),
    Club('Napoli', serieA, sportsDbName: 'SSC Napoli'),
    Club('Roma', serieA, sportsDbName: 'AS Roma'),
    Club('Lazio', serieA, sportsDbName: 'SS Lazio'),
    Club('Atalanta', serieA),
    Club('Fiorentina', serieA, sportsDbName: 'ACF Fiorentina'),
    Club('Bologna', serieA, sportsDbName: 'Bologna FC'),
    Club('Torino', serieA, sportsDbName: 'Torino FC'),
    Club('Udinese', serieA),
    Club('Sassuolo', serieA, sportsDbName: 'US Sassuolo'),
    Club('Genoa', serieA, sportsDbName: 'Genoa CFC'),
    Club('Cagliari', serieA, sportsDbName: 'Cagliari Calcio'),
    Club('Verona', serieA, sportsDbName: 'Hellas Verona'),
    Club('Parma', serieA, sportsDbName: 'Parma Calcio 1913'),
    Club('Lecce', serieA, sportsDbName: 'US Lecce'),
    Club('Como', serieA, sportsDbName: 'Como 1907'),
    Club('Cremonese', serieA, sportsDbName: 'US Cremonese'),
    Club('Pisa', serieA, sportsDbName: 'Pisa SC'),
  ];

  static const List<Club> ligue1Clubs = [
    Club('PSG', ligue1, sportsDbName: 'Paris Saint-Germain', aliases: ['paris saint-germain', 'paris sg']),
    Club('Monaco', ligue1, sportsDbName: 'AS Monaco'),
    Club('Marseille', ligue1, sportsDbName: 'Olympique Marseille'),
    Club('Lyon', ligue1, sportsDbName: 'Olympique Lyonnais'),
    Club('Lille', ligue1, sportsDbName: 'LOSC Lille'),
    Club('Nice', ligue1, sportsDbName: 'OGC Nice'),
    Club('Lens', ligue1, sportsDbName: 'RC Lens'),
    Club('Rennes', ligue1, sportsDbName: 'Stade Rennais'),
    Club('Strasbourg', ligue1, sportsDbName: 'RC Strasbourg'),
    Club('Toulouse', ligue1, sportsDbName: 'Toulouse FC'),
    Club('Nantes', ligue1, sportsDbName: 'FC Nantes'),
    Club('Brest', ligue1, sportsDbName: 'Stade Brestois'),
    Club('Auxerre', ligue1, sportsDbName: 'AJ Auxerre'),
    Club('Angers', ligue1, sportsDbName: 'Angers SCO'),
    Club('Le Havre', ligue1, sportsDbName: 'Le Havre AC'),
    Club('Metz', ligue1, sportsDbName: 'FC Metz'),
    Club('Paris FC', ligue1),
    Club('Lorient', ligue1, sportsDbName: 'FC Lorient'),
  ];

  static const List<Club> superLigClubs = [
    Club('Galatasaray', superLig),
    Club('Fenerbahce', superLig, sportsDbName: 'Fenerbahce', aliases: ['fenerbahçe']),
    Club('Besiktas', superLig, sportsDbName: 'Besiktas', aliases: ['beşiktaş']),
    Club('Trabzonspor', superLig),
    Club('Basaksehir', superLig,
        sportsDbName: 'Istanbul Basaksehir', aliases: ['başakşehir', 'istanbul basaksehir']),
    Club('Samsunspor', superLig),
    Club('Kasimpasa', superLig, sportsDbName: 'Kasimpasa', aliases: ['kasımpaşa']),
    Club('Kayserispor', superLig),
    Club('Antalyaspor', superLig),
    Club('Alanyaspor', superLig),
    Club('Sivasspor', superLig),
    Club('Konyaspor', superLig),
    Club('Gaziantep FK', superLig),
    Club('Rizespor', superLig, sportsDbName: 'Caykur Rizespor', aliases: ['çaykur rizespor']),
    Club('Goztepe', superLig, sportsDbName: 'Goztepe', aliases: ['göztepe']),
    Club('Genclerbirligi', superLig, sportsDbName: 'Genclerbirligi', aliases: ['gençlerbirliği']),
    Club('Eyupspor', superLig, sportsDbName: 'Eyupspor', aliases: ['eyüpspor']),
    Club('Kocaelispor', superLig),
    Club('Fatih Karagumruk', superLig, sportsDbName: 'Fatih Karagumruk', aliases: ['karagümrük']),
  ];

  static const List<Club> saudiProLeagueClubs = [
    Club('Al-Hilal', saudiProLeague, sportsDbName: 'Al Hilal'),
    Club('Al-Nassr', saudiProLeague, sportsDbName: 'Al Nassr'),
    Club('Al-Ittihad', saudiProLeague, sportsDbName: 'Al Ittihad Jeddah'),
    Club('Al-Ahli', saudiProLeague, sportsDbName: 'Al Ahli Saudi'),
    Club('Al-Shabab', saudiProLeague, sportsDbName: 'Al Shabab Riyadh'),
    Club('Al-Taawoun', saudiProLeague, sportsDbName: 'Al Taawoun'),
    Club('Al-Fateh', saudiProLeague, sportsDbName: 'Al Fateh'),
    Club('Al-Fayha', saudiProLeague, sportsDbName: 'Al Fayha'),
    Club('Al-Riyadh', saudiProLeague, sportsDbName: 'Al Riyadh SC'),
    Club('Al-Ettifaq', saudiProLeague, sportsDbName: 'Al Ettifaq'),
    Club('Al-Qadsiah', saudiProLeague, sportsDbName: 'Al Qadsiah'),
    Club('Al-Khaleej', saudiProLeague, sportsDbName: 'Al Khaleej Saihat'),
    Club('Al-Okhdood', saudiProLeague, sportsDbName: 'Al Okhdood'),
    Club('Damac', saudiProLeague, sportsDbName: 'Damac FC'),
    Club('Al-Kholood', saudiProLeague, sportsDbName: 'Al Kholood'),
    Club('Al-Najma', saudiProLeague, sportsDbName: 'Al Najma'),
    Club('Neom', saudiProLeague, sportsDbName: 'Neom SC'),
    Club('Al-Hazem', saudiProLeague, sportsDbName: 'Al Hazem'),
  ];

  /// Every club, across all seven leagues.
  static const List<Club> all = [
    ...premierLeagueClubs,
    ...laLigaClubs,
    ...bundesligaClubs,
    ...serieAClubs,
    ...ligue1Clubs,
    ...superLigClubs,
    ...saudiProLeagueClubs,
  ];

  /// Just the names, in catalogue order — the surface most callers want.
  static final List<String> names = [for (final c in all) c.name];

  static final Map<String, Club> _byName = {for (final c in all) c.name: c};

  /// Looks up a club by its canonical [name], or null if not in the catalogue.
  static Club? byName(String name) => _byName[name];

  /// The club's league, or null if not in the catalogue.
  static String? leagueOf(String name) => _byName[name]?.league;

  static final Map<String, List<Club>> _byLeague = {
    for (final league in leagues)
      league: all.where((c) => c.league == league).toList(),
  };

  /// All clubs in [league].
  static List<Club> clubsInLeague(String league) =>
      _byLeague[league] ?? const [];
}
