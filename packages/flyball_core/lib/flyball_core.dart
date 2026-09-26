/// Shared game logic for Flyball: catalogue, factor/board model, and the
/// Gemini-backed AI answer/board engine. Used by both `frontend` and
/// `backend`.
library;

export 'src/account/account_rules.dart';
export 'src/account/account_user.dart';

export 'src/catalog/clubs.dart';
export 'src/catalog/competitions.dart';
export 'src/catalog/countries.dart';

export 'src/model/answer_result.dart';
export 'src/model/board.dart';
export 'src/model/factor.dart';
export 'src/model/factor_pool.dart';
export 'src/model/round.dart';

export 'src/ai/answer_finder.dart';
export 'src/ai/board_builder.dart';
export 'src/ai/gemini_parser.dart';
export 'src/ai/gemini_transport.dart';
export 'src/ai/prompts.dart';
export 'src/ai/round_picker.dart';
