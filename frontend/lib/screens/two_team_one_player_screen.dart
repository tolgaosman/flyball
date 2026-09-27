import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flyball_core/flyball_core.dart';

import '../data/ai/ai_exceptions.dart';
import '../data/ai/ai_gateway.dart';
import '../data/ai/ai_gateway_factory.dart';
import '../config/app_config.dart';
import '../game/party/round_queue.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/ai_state_views.dart';
import '../widgets/animations.dart';
import '../widgets/answers_sheet.dart';
import '../widgets/dynamic_art.dart';
import '../widgets/party_widgets.dart';
import '../widgets/premium_button.dart';
import '../widgets/screen_fit.dart';
import '../widgets/states.dart';

/// **2 Team 1 Player** — a two-player party quiz.
///
/// Tapping "New Teams" spins two slot boxes that land on a random pair of
/// clubs AI-confirmed to share at least one real footballer. Players then
/// name footballers who turned out for BOTH clubs; "Answers" reveals the
/// full, already-verified list instantly. A manual scoreboard tracks the two
/// players.
class TwoTeamOnePlayerScreen extends StatefulWidget {
  const TwoTeamOnePlayerScreen({super.key});

  @override
  State<TwoTeamOnePlayerScreen> createState() => _TwoTeamOnePlayerScreenState();
}

class _TwoTeamOnePlayerScreenState extends State<TwoTeamOnePlayerScreen> {
  final Random _rng = Random();
  late final AiGateway _aiGateway = createAiGateway();
  late final RoundQueue _queue = RoundQueue(
    aiGateway: _aiGateway,
    kind: RoundKind.twoTeam,
  );

  Round? _round;
  bool _loading = true;
  bool _errored = false;
  bool _quotaExceeded = false;

  String _displayA = '';
  String _displayB = '';
  bool _spinning = false;
  Timer? _spinTimer;

  String _p1Name = '';
  String _p2Name = '';
  int _p1Score = 0;
  int _p2Score = 0;

  @override
  void initState() {
    super.initState();
    if (AppConfig.hasAi) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errored = false;
    });
    Round? round;
    var quotaExceeded = false;
    try {
      round = await _queue.next();
    } on AiUnavailableException catch (e) {
      quotaExceeded = e.quotaExceeded;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _quotaExceeded = quotaExceeded;
      if (round == null) {
        _errored = true;
      } else {
        _round = round;
        _displayA = round.conditionA;
        _displayB = round.conditionB;
      }
    });
  }

  @override
  void dispose() {
    _spinTimer?.cancel();
    super.dispose();
  }

  void _spin() {
    if (_spinning) return;
    final pool = ClubCatalog.names;
    setState(() => _spinning = true);

    _spinTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      setState(() {
        _displayA = pool[_rng.nextInt(pool.length)];
        _displayB = pool[_rng.nextInt(pool.length)];
      });
    });

    Future.delayed(const Duration(seconds: 2), () async {
      Round? round;
      var quotaExceeded = false;
      try {
        round = await _queue.next();
      } on AiUnavailableException catch (e) {
        quotaExceeded = e.quotaExceeded;
      }
      _spinTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _spinning = false;
        _quotaExceeded = quotaExceeded;
        if (round == null) {
          _errored = true;
        } else {
          _errored = false;
          _round = round;
          _displayA = round.conditionA;
          _displayB = round.conditionB;
        }
      });
    });
  }

  Future<void> _editName(bool isPlayerOne) async {
    final l10n = AppLocalizations.of(context);
    final current = isPlayerOne
        ? (_p1Name.isEmpty ? l10n.partyPlayer1Default : _p1Name)
        : (_p2Name.isEmpty ? l10n.partyPlayer2Default : _p2Name);
    final result = await showEditNameDialog(context, initial: current);
    if (result == null || !mounted) return;
    setState(() {
      if (isPlayerOne) {
        _p1Name = result;
      } else {
        _p2Name = result;
      }
    });
  }

  void _showAnswers() {
    final round = _round;
    if (_spinning || round == null) return;
    showPartyAnswersSheet(
      context,
      header: _Header(teamA: round.conditionA, teamB: round.conditionB),
      answers: round.answers,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.twoTeamOnePlayerTitle)),
      body: SafeArea(
        child: !AppConfig.hasAi
            ? const AiNotConfiguredView()
            : _loading
            ? const LoadingState()
            : _errored
            ? AiUnavailableView(onRetry: _load, quotaExceeded: _quotaExceeded)
            : _buildBody(l10n),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return ScreenFit(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SuccessPop(
                      trigger: _spinning ? null : _displayA,
                      child: SlotCard(
                        name: _displayA,
                        spinning: _spinning,
                        isCountry: false,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: SuccessPop(
                      trigger: _spinning ? null : _displayB,
                      child: SlotCard(
                        name: _displayB,
                        spinning: _spinning,
                        isCountry: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ScorePanel(
                      name: _p1Name.isEmpty
                          ? l10n.partyPlayer1Default
                          : _p1Name,
                      score: _p1Score,
                      onEditName: () => _editName(true),
                      onIncrement: () => setState(() => _p1Score++),
                      onDecrement: () =>
                          setState(() => _p1Score = max(0, _p1Score - 1)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: ScorePanel(
                      name: _p2Name.isEmpty
                          ? l10n.partyPlayer2Default
                          : _p2Name,
                      score: _p2Score,
                      onEditName: () => _editName(false),
                      onIncrement: () => setState(() => _p2Score++),
                      onDecrement: () =>
                          setState(() => _p2Score = max(0, _p2Score - 1)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            PremiumButton(
              onPressed: _spinning ? null : _spin,
              child: Text(l10n.partyNewTeams),
            ),
            const SizedBox(height: AppSpacing.md),
            PremiumButton(
              onPressed: (_spinning || _round == null) ? null : _showAnswers,
              color: AppColors.surface,
              foregroundColor: AppColors.white,
              borderColor: AppColors.pitchGreen,
              child: Text(l10n.partyAnswers),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.teamA, required this.teamB});
  final String teamA;
  final String teamB;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClubLogo(clubName: teamA, size: 42),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                '×',
                style: TextStyle(
                  color: AppColors.whiteMuted,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ClubLogo(clubName: teamB, size: 42),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '$teamA  ×  $teamB',
          textAlign: TextAlign.center,
          style: AppTheme.headline(),
        ),
      ],
    );
  }
}
