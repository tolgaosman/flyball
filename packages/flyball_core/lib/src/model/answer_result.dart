/// The outcome of a live AI answer search: the [players] plus a [verified]
/// flag telling the UI whether they survived the strict verification pass.
///
/// [verified] is `true` for a normal two-phase success (recall → verify). It
/// is `false` only when the verification call itself failed and the caller
/// fell back to the raw, unchecked recall candidates — letting the UI warn
/// that the list was not fact-checked.
class AnswerResult {
  const AnswerResult(this.players, {required this.verified});

  final List<String> players;
  final bool verified;

  Map<String, dynamic> toJson() => {'players': players, 'verified': verified};

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        (json['players'] as List).map((e) => e.toString()).toList(),
        verified: json['verified'] as bool? ?? true,
      );
}
