import 'package:flutter/material.dart';
import 'package:flyball_core/flyball_core.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/text_utils.dart';
import 'animations.dart';
import 'premium_button.dart';
import 'premium_card.dart';
import 'states.dart';

/// Opens the answers sheet for a party-game round whose [answers] were
/// already confirmed by the AI *before* the round was ever shown (every round
/// [RoundPicker] hands out is pre-verified to have at least one player) — so
/// this never needs to show a loading state.
Future<void> showPartyAnswersSheet(
  BuildContext context, {
  required Widget header,
  required AnswerResult answers,
}) {
  return _showAnswersSheet(
    context,
    header: header,
    loading: false,
    errored: false,
    names: answers.players,
    verified: answers.verified,
    onRetry: null,
  );
}

/// Opens the answers sheet for a fresh AI search (used by Football XOX's
/// long-press reveal, which always re-fetches the authoritative list rather
/// than trusting the board's short preview). Shows [preview] immediately
/// (the board builder's quick example players for this cell, if any) while
/// [fetch] runs, then replaces it with the full result. Offers a retry button
/// if the fetch fails.
Future<void> showAiAnswersSheet(
  BuildContext context, {
  required Widget header,
  List<String> preview = const [],
  required Future<AnswerResult?> Function() fetch,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AiAnswersSheetContent(header: header, preview: preview, fetch: fetch),
  );
}

Future<void> _showAnswersSheet(
  BuildContext context, {
  required Widget header,
  required bool loading,
  required bool errored,
  required List<String> names,
  required bool verified,
  required VoidCallback? onRetry,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AnswersSheetChrome(
      header: header,
      child: _AnswersBody(
        loading: loading,
        errored: errored,
        names: names,
        verified: verified,
        onRetry: onRetry,
      ),
    ),
  );
}

/// Handles the fetch lifecycle (preview → loading → result/error → retry) for
/// [showAiAnswersSheet].
class _AiAnswersSheetContent extends StatefulWidget {
  const _AiAnswersSheetContent({
    required this.header,
    required this.preview,
    required this.fetch,
  });

  final Widget header;
  final List<String> preview;
  final Future<AnswerResult?> Function() fetch;

  @override
  State<_AiAnswersSheetContent> createState() => _AiAnswersSheetContentState();
}

class _AiAnswersSheetContentState extends State<_AiAnswersSheetContent> {
  bool _loading = true;
  bool _errored = false;
  List<String> _names = const [];
  bool _verified = true;

  @override
  void initState() {
    super.initState();
    _names = widget.preview;
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _errored = false;
    });
    final result = await widget.fetch();
    if (!mounted) return;
    if (result == null) {
      // A preview from the board builder is still something real — keep
      // showing it rather than an error, unless there was nothing to show.
      setState(() {
        _errored = _names.isEmpty;
        _loading = false;
      });
      return;
    }
    setState(() {
      _names = result.players;
      _verified = result.verified;
      _loading = false;
      _errored = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _AnswersSheetChrome(
      header: widget.header,
      child: _AnswersBody(
        loading: _loading,
        errored: _errored,
        names: _names,
        verified: _verified,
        onRetry: _errored ? _run : null,
      ),
    );
  }
}

/// The sheet's outer shell: rounded top corners, blurred/tinted background,
/// a drag handle, [header] (e.g. the two club/country badges), then [child].
/// Sized to 85% of the screen and shifted up over the on-screen keyboard —
/// unlike the old fixed-height [Dialog], this never overflows when the
/// keyboard opens.
class _AnswersSheetChrome extends StatelessWidget {
  const _AnswersSheetChrome({required this.header, required this.child});

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: PremiumCard(
          color: AppColors.surfaceHigh,
          borderColor: AppColors.pitchGreen.withValues(alpha: 0.4),
          radius: AppTheme.radius,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              header,
              const SizedBox(height: AppSpacing.md),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared list body: count/verification line, search box, and the filtered,
/// staggered-in list of names — or a loading/empty/error state.
class _AnswersBody extends StatefulWidget {
  const _AnswersBody({
    required this.loading,
    required this.errored,
    required this.names,
    required this.verified,
    required this.onRetry,
  });

  final bool loading;
  final bool errored;
  final List<String> names;
  final bool verified;
  final VoidCallback? onRetry;

  @override
  State<_AnswersBody> createState() => _AnswersBodyState();
}

class _AnswersBodyState extends State<_AnswersBody> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (widget.errored) {
      return ErrorState(
        title: l10n.answersSearchFailedTitle,
        message: l10n.answersSearchFailedMessage,
        action: widget.onRetry == null
            ? null
            : PremiumButton(
                onPressed: widget.onRetry,
                expand: false,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                child: Text(l10n.retry),
              ),
      );
    }

    final filtered = widget.names
        .where((n) => TextFold.contains(n, _query))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.loading ? l10n.answersSearching : l10n.answersCount(widget.names.length),
          textAlign: TextAlign.center,
          style: AppTheme.overline(color: AppColors.pitchGreen),
        ),
        if (!widget.loading && widget.names.isNotEmpty && !widget.verified) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.answersUnverifiedWarning,
            textAlign: TextAlign.center,
            style: AppTheme.overline(color: AppColors.danger),
          ),
        ],
        if (widget.names.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
            style: AppTheme.label(14),
            cursorColor: AppColors.pitchGreen,
            decoration: InputDecoration(
              hintText: l10n.answersSearchHint,
              hintStyle: AppTheme.label(14, color: AppColors.whiteMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.whiteMuted, size: 20),
              filled: true,
              fillColor: AppColors.surfaceLow,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: const BorderSide(color: AppColors.pitchGreen, width: 2),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: widget.loading
              ? LoadingState(message: l10n.answersSearching)
              : filtered.isEmpty
                  ? EmptyState(icon: Icons.search_off_rounded, title: l10n.answersNoneFound)
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        return FadeSlideIn(
                          delay: Duration(milliseconds: 30 * (i > 12 ? 12 : i)),
                          duration: AppTheme.durMed,
                          child: PremiumCard(
                            color: AppColors.surfaceLow,
                            borderColor: AppColors.border,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Text(filtered[i], style: AppTheme.body()),
                          ),
                        );
                      },
                    ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
