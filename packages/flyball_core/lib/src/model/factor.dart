/// The kind of constraint a [Factor] expresses.
enum FactorType {
  /// Player appeared in a given league.
  playedLeague,

  /// Player won a given domestic league title.
  wonLeague,

  /// Player won a given international tournament.
  wonInternational,

  /// Player represented a given club.
  team,

  /// Player holds a given nationality.
  nationality,
}

/// A single XOX axis constraint (a row or column "category").
///
/// Each factor carries the [label] shown in the header (and sent to the AI as
/// one half of a search condition) and the canonical [value] it constrains
/// (e.g. a league, club or country name from the catalogue). Two factors are
/// equal when their type + value match, which the board generator uses to
/// guarantee all six headers are unique.
class Factor {
  const Factor({
    required this.type,
    required this.label,
    required this.value,
  });

  final FactorType type;

  /// Human-readable header text, e.g. "Played in Premier League".
  final String label;

  /// The canonical value, e.g. "Premier League", "World Cup", "Real Madrid",
  /// "France".
  final String value;

  /// True when this factor constrains nationality. Two nationality factors on
  /// opposing axes would create impossible cells, so the board generator never
  /// places one on a row and another on a column.
  bool get isNationality => type == FactorType.nationality;

  /// True when this factor is an international tournament title. Like
  /// nationalities, two of these on opposing axes are mutually exclusive.
  bool get isInternational => type == FactorType.wonInternational;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'label': label,
        'value': value,
      };

  factory Factor.fromJson(Map<String, dynamic> json) => Factor(
        type: FactorType.values.byName(json['type'] as String),
        label: json['label'] as String,
        value: json['value'] as String,
      );

  @override
  bool operator ==(Object other) =>
      other is Factor && other.type == type && other.value == value;

  @override
  int get hashCode => Object.hash(type, value);

  @override
  String toString() => 'Factor($type, $value)';
}
