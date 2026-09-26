# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Flyball** — a Flutter mobile app of football trivia mini-games, "Night
Pitch" aesthetic (warm charcoal, a confident pitch green + trophy gold
accent, Space Grotesk headings via `google_fonts`, soft diffuse shadows and
spring-physics motion — see [theme/app_theme.dart](frontend/lib/theme/app_theme.dart)).

Three games exist; two are fully implemented:
- **Football XOX** — fully built. A 3×3 trivia grid; each row/column gets a
  random, AI-verified factor (category). Runs in **Game Master Mode**: designed
  for in-person social play. Tapping a cell instantly claims it for whoever's
  turn it is (the two players agree verbally on a real footballer), and
  long-pressing reveals the AI's answer list for that cell.
- **2 Team 1 Player** and **1 Team 1 Country** — fully built party quiz modes.
  Spin two clubs (or a club + nationality) and name a footballer satisfying
  both; every round handed to the screen is pre-verified by the AI to have a
  real answer, so revealing it is instant.
- **Footballdle** — still a "Coming Soon" placeholder.

**Everything is AI-first — there is no static/offline player database.**
Every answer, every XOX board, and every party-game round comes from a live
(or cached) Google Gemini search grounded with web search. See
[Architecture](#architecture) below.

## Repository layout (monorepo)

```
flyball/
  packages/flyball_core/   # pure-Dart: catalogue + AI engine, shared by both apps
  backend/                 # Dart shelf server — holds the Gemini key, caches answers
  frontend/                # the Flutter app
```

`flyball_core` is a path dependency of both `backend` and `frontend` — it is
the single source of truth for the club/country/competition catalogue, the
`Factor`/`Board`/`Round` models, and the Gemini prompts/parsing/orchestration.
Change catalogue data or prompts **there**, not in either app.

## Commands

All Flutter commands run from `frontend/`; the shared package and backend are
plain Dart (no Flutter SDK needed for them).

```bash
# packages/flyball_core
cd packages/flyball_core && dart pub get && dart test

# backend
cd backend && dart pub get
cp .env.example .env               # then paste a Gemini key into .env
# bash:
set -a; source .env; set +a; dart run bin/server.dart
# PowerShell:
$env:GEMINI_API_KEY="..."; dart run bin/server.dart
dart test                          # backend's own tests

# frontend
cd frontend
flutter pub get
flutter gen-l10n                   # regenerate lib/l10n/app_localizations*.dart after editing an .arb
flutter analyze                    # keep at zero issues
flutter test
flutter run --dart-define-from-file=dart_define.json
```

### Getting a Gemini key
1. Go to **https://aistudio.google.com/apikey**, sign in, "Create API key".
2. Paste it into `backend/.env` (`GEMINI_API_KEY=...`) — this is the
   recommended path; the key never leaves the server.

### Pointing the app at the backend
Copy [dart_define.example.json](frontend/dart_define.example.json) to
`dart_define.json` (git-ignored) and fill in `API_BASE_URL`:

```json
{ "API_BASE_URL": "http://192.168.1.23:8080", "GEMINI_API_KEY": "", "GEMINI_MODEL": "gemini-2.5-flash" }
```

Use your machine's **LAN IP** (not `localhost`) so a physical phone on the
same network can reach it; from an Android emulator use `10.0.2.2`. Run with:

```bash
flutter run --dart-define-from-file=dart_define.json
```

### AI modes ([AppConfig.aiMode](frontend/lib/config/app_config.dart))
- **`backend`** (recommended) — `API_BASE_URL` is set; the app talks only to
  your backend, which holds the real Gemini key.
- **`direct`** — `API_BASE_URL` is empty but `GEMINI_API_KEY` is set; the app
  calls Gemini directly with a compiled-in key (no server to run, but the key
  is extractable from the app binary — fine for personal/local use only).
- **`none`** — neither is set. The app is fully functional UI-wise but every
  screen shows an explicit "AI not configured" state — **it never silently
  falls back to fake/static data.**

## Architecture

```
packages/flyball_core/lib/
  src/catalog/    clubs.dart, countries.dart, competitions.dart
  src/account/    account_user.dart, account_rules.dart (username/password rules + error codes)
  src/model/      factor.dart, factor_pool.dart, board.dart, round.dart, answer_result.dart
  src/ai/         gemini_transport.dart, prompts.dart, gemini_parser.dart,
                  answer_finder.dart, board_builder.dart, round_picker.dart

backend/
  bin/server.dart           # shelf routes: /health, /api/answers, /api/rounds/*, /api/xox/board, /api/auth/*
  lib/env_config.dart        # GEMINI_API_KEY / GEMINI_MODEL / PORT / CACHE_DB_PATH from env
  lib/cache_db.dart          # SQLite cache (answer_cache / boards / rounds) — a CACHE, not a corpus
  lib/app_service.dart       # cache-then-AI, in-flight request dedupe, background buffer top-up
  lib/user_store.dart        # SQLite accounts + sessions — a SEPARATE file from the cache (USER_DB_PATH)
  lib/auth_service.dart      # register / login / logout / token lookup, failed-login throttle
  lib/auth_routes.dart       # /api/auth/{register,login,logout,me}; AuthRoutes.userFor(request) for new endpoints
  lib/password_hasher.dart   # salted PBKDF2-HMAC-SHA256

frontend/lib/
  main.dart                       # MaterialApp + theme + locale + routes
  config/app_config.dart          # reads API_BASE_URL / GEMINI_API_KEY / GEMINI_MODEL (--dart-define)
  data/ai/                        # AiGateway (backend / direct / none) — the app's only door to "AI answers something"
  data/account/                   # AccountApi (HTTP) + SessionController (signed-in user, token, persisted)
  data/art/art_resolver.dart      # dynamic club/league/trophy art (TheSportsDB) — cached, throttled
  l10n/                           # ARB files + generated AppLocalizations + LocaleController
  theme/                          # app_colors.dart, app_theme.dart (design system)
  routing/app_routes.dart         # named routes + onGenerateRoute
  widgets/                        # premium_card/button, dynamic_art (ClubLogo/CountryFlag/…),
                                  #   answers_sheet, party_widgets, animations, ai_state_views
  screens/                        # home, football_xox, two_team_one_player, one_team_one_country,
                                  #   xox_lobby, coming_soon (+ footballdle placeholder)
  game/xox/                       # xox_cell.dart, xox_game.dart (pure state machine)
  game/party/round_queue.dart     # keeps one party round pre-fetched ahead of the one on screen
  utils/text_utils.dart           # TextFold (accent/case-insensitive search), Turkish-correct uppercasing
```

### How an answer is found ([flyball_core/src/ai/answer_finder.dart](packages/flyball_core/lib/src/ai/answer_finder.dart))
Two grounded Gemini calls, both instructed to prefer **Wikipedia and
Transfermarkt** among their web search results:
1. **Recall** — cast a deliberately wide net; told NOT to filter, so it never
   self-censors a correct-but-uncertain name.
2. **Verify** — feed the candidate list back and keep only names a source
   confirms for BOTH conditions; drops hallucinations.

A `null` result means the AI is unreachable — every screen that uses it
(`AiGateway`) shows a real error/retry state, never a silently empty list.

### Football XOX board generation ([board_builder.dart](packages/flyball_core/lib/src/ai/board_builder.dart))
`FactorPool.pickAxisValidSix` draws 3 row + 3 column factors obeying the
axis-exclusivity rules (never two nationalities or two international
tournaments opposite each other, no cross-tournament-ineligible nationality,
etc. — see `FactorPool.axesAreValid`). ONE Gemini call then asks for 1–3
example players per cell (all 9 at once); if a cell comes back empty, the
factor on whichever axis accounts for the most empty cells is swapped and
retried (bounded). Those examples are only an instant long-press *preview* —
the authoritative list is always a fresh `AnswerFinder` search.

### Party rounds ([round_picker.dart](packages/flyball_core/lib/src/ai/round_picker.dart) + [round_queue.dart](frontend/lib/game/party/round_queue.dart))
`RoundPicker` draws a club pair (65% weighted toward same-league, which
shares far more players) or a club+nationality pair, and only ever hands out
one an `AnswerFinder` search actually confirmed — so "Answers" is instant, no
loading state needed. `RoundQueue` keeps one such round pre-fetched client-side;
the backend additionally keeps its own buffer of ready rounds/boards topped up
in the background (`AppService`), so the common case across the whole stack
is "already ready" rather than "wait for Gemini".

### Accounts ([session_controller.dart](frontend/lib/data/account/session_controller.dart))
Username + password accounts live on the backend (`backend` AI mode only —
in `direct`/`none` the home screen hides the SIGN IN pill and
`sessionController.isAvailable` is false). `sessionController` (global, in
`main.dart`, like `localeController`) is a `ValueNotifier<AccountUser?>`;
it persists the token + user to `SharedPreferences`, restores them instantly
on launch and re-checks with `/api/auth/me` in the background (a 401 signs
out; being offline keeps the cached account). Screens: `LoginScreen`
(`/login`) and `SignupScreen` (`/signup`). Validation rules and error codes
are shared through `flyball_core`'s `AccountRules`/`AccountErrors`, so the
form and the server always agree. For a new authenticated endpoint, send
`Authorization: Bearer ${sessionController.token}` and resolve the caller
server-side with `AuthRoutes.userFor(request)`.

### Dynamic art ([art_resolver.dart](frontend/lib/data/art/art_resolver.dart))
No bundled club/league/trophy images — logos come from **TheSportsDB**'s free
keyless API (`searchteams.php` / `lookupleague.php`), flags from
**flagcdn.com** (no lookup needed, just an ISO-2 code from the catalogue).
Every lookup is cached to `SharedPreferences` for 30 days and throttled/
deduped, and **art is never fetched while a slot is mid-spin** (`enabled:
!spinning` on `ClubLogo`/`CountryFlag` — a spin flashes dozens of names a
second). A missing/unresolved image falls back to a `Monogram` (initials),
never breaks layout. Only `assets/images/flyball_app_logo.png` remains as a
bundled asset (app icon).

### i18n
English is the default; Turkish is fully supported (`flutter gen-l10n` /
[l10n.yaml](frontend/l10n.yaml) / `lib/l10n/app_en.arb` + `app_tr.arb`).
`LocaleController` ([frontend/lib/l10n/locale_controller.dart](frontend/lib/l10n/locale_controller.dart))
persists an explicit choice (the toggle on the home screen); otherwise the
device locale resolves it (Turkish device → Turkish, else English). **Every**
new user-facing string goes in the ARB files, not inline — including the
Turkish-correct casing/search helpers in `utils/text_utils.dart` (`'i'.toUpperCase()`
gives `'I'` instead of Turkish `'İ'`, and plain `toLowerCase()` search
matching breaks on `'İlkay'`/`'Özil'`).

## Extending

- **Add a club / league / country**: edit
  [flyball_core/src/catalog/clubs.dart](packages/flyball_core/lib/src/catalog/clubs.dart) or
  [countries.dart](packages/flyball_core/lib/src/catalog/countries.dart). Set
  `sportsDbName` only if TheSportsDB indexes the club under a different name
  than its display name (verify with `GET .../searchteams.php?t=<name>`).
- **Add a competition** (new trophy/league badge): add it to
  [competitions.dart](packages/flyball_core/lib/src/catalog/competitions.dart)
  with its TheSportsDB league id (`GET .../lookupleague.php?id=<id>`).
- **Change a prompt**: [flyball_core/src/ai/prompts.dart](packages/flyball_core/lib/src/ai/prompts.dart) —
  shared by recall, verify, and the board-cell prompt.
- **New factor type**: add to `FactorType`, extend `Factor` (in
  `flyball_core/src/model/factor.dart`), and update `FactorPool.allFactors()` /
  the axis-validity rules.
- **Swap the AI backend/model**: `GeminiTransport` is the interface
  (`flyball_core/src/ai/gemini_transport.dart`); `DirectGeminiTransport` is the
  only implementation today, used both by the backend (real key) and the
  frontend's `direct` mode (compiled-in key).
- **New user-facing text**: add the key to `lib/l10n/app_en.arb` AND
  `app_tr.arb`, then `flutter gen-l10n`.

## Conventions

- `StatefulWidget` for game state (no state-management package).
- Use the shared `PremiumCard` / `PremiumButton` rather than re-styling
  containers; pull colours from `AppColors` and text styles from `AppTheme`.
- Grid/headers must scale to fit common phone sizes without overflow (the XOX
  board sizes header art and cell text off the actual cell size via
  `LayoutBuilder`, not fixed constants).
- **Don't chain the same `flutter_animate` effect type via `.then()`**
  (e.g. `.scale().then().scale()`) — each occurrence renders as a SEPARATE
  nested transform that holds its own end value once its slice of the
  timeline passes, so two `.scale()`s compose *multiplicatively* and the
  widget ends up permanently oversized. `SuccessPop`
  ([widgets/animations.dart](frontend/lib/widgets/animations.dart)) instead
  uses a single `AnimationController` + `TweenSequence` for a pop-and-settle
  effect that reliably ends at scale 1.0 — copy that pattern for any similar
  "animate out and back" effect.
