import 'answer_result.dart';

/// The kind of party-game round (which shape of two-condition question).
enum RoundKind {
  /// Name a footballer who played for BOTH clubs ("2 Team 1 Player").
  twoTeam,

  /// Name a footballer of the given nationality who played for the given club
  /// ("1 Team 1 Country").
  teamCountry,
}

/// A ready-to-play party-game round: the two conditions (already settled —
/// not mid-spin) plus its AI-confirmed answers, so revealing them is instant.
class Round {
  const Round({
    required this.kind,
    required this.conditionA,
    required this.conditionB,
    required this.answers,
  });

  final RoundKind kind;

  /// The club (both kinds) shown in slot A.
  final String conditionA;

  /// The other club (twoTeam) or the nationality (teamCountry) in slot B.
  final String conditionB;

  final AnswerResult answers;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'conditionA': conditionA,
        'conditionB': conditionB,
        'answers': answers.toJson(),
      };

  factory Round.fromJson(Map<String, dynamic> json) => Round(
        kind: RoundKind.values.byName(json['kind'] as String),
        conditionA: json['conditionA'] as String,
        conditionB: json['conditionB'] as String,
        answers: AnswerResult.fromJson(json['answers'] as Map<String, dynamic>),
      );
}
