/// A nationality in the Flyball catalogue.
///
/// [name] is the canonical English name used in AI prompts and as the
/// `Factor` value. [nameTr] is the Turkish display name (falls back to [name]
/// when it's spelled the same in both languages). [iso2] is the ISO-3166
/// alpha-2 code used to build a flagcdn.com URL; UK home nations use flagcdn's
/// `gb-eng`/`gb-sct`/`gb-wls`/`gb-nir` extension codes.
class Country {
  const Country(this.name, this.iso2, {String? nameTr})
      : nameTr = nameTr ?? name;

  final String name;
  final String nameTr;
  final String iso2;

  @override
  String toString() => name;
}

/// A wide nationality pool spanning UEFA, CONMEBOL, CONCACAF, CAF, AFC and
/// OFC — every country with a footballing profile large enough to reliably
/// produce AI-verifiable answers for the party games and XOX.
class CountryCatalog {
  CountryCatalog._();

  static const List<Country> all = [
    // ── UEFA ──
    Country('France', 'fr', nameTr: 'Fransa'),
    Country('Spain', 'es', nameTr: 'İspanya'),
    Country('England', 'gb-eng', nameTr: 'İngiltere'),
    Country('Portugal', 'pt', nameTr: 'Portekiz'),
    Country('Netherlands', 'nl', nameTr: 'Hollanda'),
    Country('Belgium', 'be', nameTr: 'Belçika'),
    Country('Germany', 'de', nameTr: 'Almanya'),
    Country('Croatia', 'hr', nameTr: 'Hırvatistan'),
    Country('Italy', 'it', nameTr: 'İtalya'),
    Country('Switzerland', 'ch', nameTr: 'İsviçre'),
    Country('Denmark', 'dk', nameTr: 'Danimarka'),
    Country('Turkiye', 'tr', nameTr: 'Türkiye'),
    Country('Austria', 'at', nameTr: 'Avusturya'),
    Country('Norway', 'no', nameTr: 'Norveç'),
    Country('Ukraine', 'ua', nameTr: 'Ukrayna'),
    Country('Poland', 'pl', nameTr: 'Polonya'),
    Country('Wales', 'gb-wls', nameTr: 'Galler'),
    Country('Sweden', 'se', nameTr: 'İsveç'),
    Country('Serbia', 'rs', nameTr: 'Sırbistan'),
    Country('Czechia', 'cz', nameTr: 'Çekya'),
    Country('Hungary', 'hu', nameTr: 'Macaristan'),
    Country('Scotland', 'gb-sct', nameTr: 'İskoçya'),
    Country('Greece', 'gr', nameTr: 'Yunanistan'),
    Country('Slovakia', 'sk', nameTr: 'Slovakya'),
    Country('Romania', 'ro', nameTr: 'Romanya'),
    Country('Slovenia', 'si', nameTr: 'Slovenya'),
    Country('Ireland', 'ie', nameTr: 'İrlanda'),
    Country('Albania', 'al', nameTr: 'Arnavutluk'),
    Country('Bosnia', 'ba', nameTr: 'Bosna Hersek'),
    Country('N. Ireland', 'gb-nir', nameTr: 'Kuzey İrlanda'),
    Country('Georgia', 'ge', nameTr: 'Gürcistan'),
    Country('Finland', 'fi', nameTr: 'Finlandiya'),
    Country('Iceland', 'is', nameTr: 'İzlanda'),
    Country('North Macedonia', 'mk', nameTr: 'Kuzey Makedonya'),
    Country('Russia', 'ru', nameTr: 'Rusya'),
    Country('Montenegro', 'me', nameTr: 'Karadağ'),
    Country('Bulgaria', 'bg', nameTr: 'Bulgaristan'),
    Country('Kosovo', 'xk', nameTr: 'Kosova'),
    Country('Cyprus', 'cy', nameTr: 'Kıbrıs'),
    Country('Luxembourg', 'lu', nameTr: 'Lüksemburg'),
    Country('Armenia', 'am', nameTr: 'Ermenistan'),
    Country('Azerbaijan', 'az', nameTr: 'Azerbaycan'),
    Country('Moldova', 'md', nameTr: 'Moldova'),
    Country('Israel', 'il', nameTr: 'İsrail'),
    Country('Latvia', 'lv', nameTr: 'Letonya'),
    Country('Lithuania', 'lt', nameTr: 'Litvanya'),
    Country('Estonia', 'ee', nameTr: 'Estonya'),
    Country('Malta', 'mt', nameTr: 'Malta'),
    Country('Belarus', 'by', nameTr: 'Belarus'),

    // ── CONMEBOL ──
    Country('Argentina', 'ar', nameTr: 'Arjantin'),
    Country('Brazil', 'br', nameTr: 'Brezilya'),
    Country('Uruguay', 'uy', nameTr: 'Uruguay'),
    Country('Colombia', 'co', nameTr: 'Kolombiya'),
    Country('Ecuador', 'ec', nameTr: 'Ekvador'),
    Country('Chile', 'cl', nameTr: 'Şili'),
    Country('Paraguay', 'py', nameTr: 'Paraguay'),
    Country('Peru', 'pe', nameTr: 'Peru'),
    Country('Venezuela', 've', nameTr: 'Venezuela'),
    Country('Bolivia', 'bo', nameTr: 'Bolivya'),

    // ── CONCACAF ──
    Country('Mexico', 'mx', nameTr: 'Meksika'),
    Country('USA', 'us', nameTr: 'ABD'),
    Country('Canada', 'ca', nameTr: 'Kanada'),
    Country('Costa Rica', 'cr', nameTr: 'Kosta Rika'),
    Country('Honduras', 'hn', nameTr: 'Honduras'),
    Country('Jamaica', 'jm', nameTr: 'Jamaika'),
    Country('Panama', 'pa', nameTr: 'Panama'),

    // ── CAF ──
    Country('Morocco', 'ma', nameTr: 'Fas'),
    Country('Senegal', 'sn', nameTr: 'Senegal'),
    Country('Nigeria', 'ng', nameTr: 'Nijerya'),
    Country('Algeria', 'dz', nameTr: 'Cezayir'),
    Country('Egypt', 'eg', nameTr: 'Mısır'),
    Country('Ivory Coast', 'ci', nameTr: 'Fildişi Sahili'),
    Country('Cameroon', 'cm', nameTr: 'Kamerun'),
    Country('Tunisia', 'tn', nameTr: 'Tunus'),
    Country('DR Congo', 'cd', nameTr: 'Kongo DC'),
    Country('Mali', 'ml', nameTr: 'Mali'),
    Country('South Africa', 'za', nameTr: 'Güney Afrika'),
    Country('Ghana', 'gh', nameTr: 'Gana'),
    Country('Burkina Faso', 'bf', nameTr: 'Burkina Faso'),
    Country('Guinea', 'gn', nameTr: 'Gine'),
    Country('Zambia', 'zm', nameTr: 'Zambiya'),
    Country('Cape Verde', 'cv', nameTr: 'Yeşil Burun Adaları'),
    Country('Gabon', 'ga', nameTr: 'Gabon'),
    Country('Benin', 'bj', nameTr: 'Benin'),
    Country('Angola', 'ao', nameTr: 'Angola'),
    Country('Mozambique', 'mz', nameTr: 'Mozambik'),
    Country('Equatorial Guinea', 'gq', nameTr: 'Ekvator Ginesi'),
    Country('Guinea-Bissau', 'gw', nameTr: 'Gine-Bissau'),
    Country('Comoros', 'km', nameTr: 'Komorlar'),
    Country('Congo', 'cg', nameTr: 'Kongo'),

    // ── AFC ──
    Country('Japan', 'jp', nameTr: 'Japonya'),
    Country('South Korea', 'kr', nameTr: 'Güney Kore'),
    Country('Iran', 'ir', nameTr: 'İran'),
    Country('Saudi Arabia', 'sa', nameTr: 'Suudi Arabistan'),
    Country('Australia', 'au', nameTr: 'Avustralya'),
    Country('Qatar', 'qa', nameTr: 'Katar'),
    Country('Iraq', 'iq', nameTr: 'Irak'),
    Country('UAE', 'ae', nameTr: 'BAE'),
    Country('Uzbekistan', 'uz', nameTr: 'Özbekistan'),
    Country('Jordan', 'jo', nameTr: 'Ürdün'),
    Country('China', 'cn', nameTr: 'Çin'),
    Country('Syria', 'sy', nameTr: 'Suriye'),
    Country('Oman', 'om', nameTr: 'Umman'),
    Country('Kuwait', 'kw', nameTr: 'Kuveyt'),
    Country('Bahrain', 'bh', nameTr: 'Bahreyn'),
    Country('Vietnam', 'vn', nameTr: 'Vietnam'),
    Country('Thailand', 'th', nameTr: 'Tayland'),
    Country('India', 'in', nameTr: 'Hindistan'),
    Country('Indonesia', 'id', nameTr: 'Endonezya'),
    Country('Palestine', 'ps', nameTr: 'Filistin'),
    Country('Lebanon', 'lb', nameTr: 'Lübnan'),
    Country('Kyrgyzstan', 'kg', nameTr: 'Kırgızistan'),
    Country('Tajikistan', 'tj', nameTr: 'Tacikistan'),
    Country('Turkmenistan', 'tm', nameTr: 'Türkmenistan'),

    // ── OFC ──
    Country('New Zealand', 'nz', nameTr: 'Yeni Zelanda'),
  ];

  static final List<String> names = [for (final c in all) c.name];

  static final Map<String, Country> _byName = {for (final c in all) c.name: c};

  static Country? byName(String name) => _byName[name];

  /// The flagcdn.com URL for [name] at the requested pixel [width], or null
  /// when the country isn't in the catalogue.
  static String? flagUrl(String name, {int width = 160}) {
    final iso = _byName[name]?.iso2;
    return iso == null ? null : 'https://flagcdn.com/w$width/$iso.png';
  }
}
