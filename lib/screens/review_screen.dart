import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../constants/bond.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vocab_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import '../utils/srs_scheduler.dart';

/// Spaced-repetition review: a flip card per due item, self-graded on SM-2's
/// four-point scale.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  /// The session is snapshotted on entry rather than read live from the
  /// provider: grading reschedules an item out of the due queue, so a live
  /// list would reshuffle under the user mid-session.
  List<ReviewItem>? _session;
  int _index = 0;
  bool _answerShown = false;
  int _reviewed = 0;

  /// XP per item. Reviews are self-graded, so this is deliberately small and
  /// the due queue is the real rate limiter — you can only review what's
  /// actually due, and grading pushes an item out of reach for the day.
  /// Coins stay with quizzes, which can't be self-graded.
  static const int _xpPerReview = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session ??= _buildSession();
  }

  List<ReviewItem> _buildSession() {
    final vocab = Provider.of<VocabProvider>(context, listen: false);
    final language = Provider.of<LanguageProvider>(context, listen: false);
    return vocab.nextSession(
      languageCode: language.targetLanguage?.code,
    );
  }

  ReviewItem? get _current {
    final session = _session;
    if (session == null || _index >= session.length) return null;
    return session[_index];
  }

  bool get _isComplete {
    final session = _session;
    return session != null && session.isNotEmpty && _index >= session.length;
  }

  Future<void> _grade(ReviewGrade grade) async {
    final item = _current;
    if (item == null) return;

    final vocab = Provider.of<VocabProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);

    vocab.grade(item.id, grade);
    await userProvider.addXp(characterProvider.scaleReward(_xpPerReview));
    // Per card, not per session: acting on a correction is the single event
    // most likely to be real learning rather than exposure.
    characterProvider.recordLearning(BondSource.correction);

    if (!mounted) return;
    setState(() {
      _reviewed++;
      _index++;
      _answerShown = false;
    });
  }

  void _finish(CharacterProvider characterProvider) {
    // One happiness bump for the session, not per card — the pet is pleased
    // you studied, not farmable by grading fast.
    characterProvider.rewardChat();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    final usePixelFont =
        Provider.of<SettingsProvider>(context).usePixelFont;
    final fontFunction = AppFonts.getFont(usePixelFont);
    final characterProvider = Provider.of<CharacterProvider>(context);

    final session = _session ?? const <ReviewItem>[];

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              l10n: l10n,
              textDirection: textDirection,
              textAlign: textAlign,
              fontFunction: fontFunction,
              remaining: session.length,
            ),
            Expanded(
              child: session.isEmpty
                  ? _buildEmptyState(
                      l10n: l10n,
                      textDirection: textDirection,
                      textAlign: textAlign,
                      fontFunction: fontFunction,
                    )
                  : _isComplete
                      ? _buildSessionComplete(
                          l10n: l10n,
                          textDirection: textDirection,
                          textAlign: textAlign,
                          fontFunction: fontFunction,
                          characterProvider: characterProvider,
                        )
                      : _buildCard(
                          l10n: l10n,
                          textDirection: textDirection,
                          textAlign: textAlign,
                          fontFunction: fontFunction,
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required AppLocalizations l10n,
    required TextDirection textDirection,
    required TextAlign textAlign,
    required TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
    required int remaining,
  }) {
    final session = _session ?? const <ReviewItem>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.retroDark, width: 4)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))
                ],
                color: Colors.white,
              ),
              child:
                  const Icon(Icons.arrow_back, color: AppTheme.retroDark),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.review,
              textDirection: textDirection,
              textAlign: textAlign,
              style: fontFunction(fontSize: 18, color: AppTheme.retroDark),
            ),
          ),
          if (session.isNotEmpty && !_isComplete)
            Text(
              l10n.reviewProgress(_index + 1, session.length),
              textDirection: TextDirection.ltr,
              style: fontFunction(fontSize: 10, color: AppTheme.retroDark),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required AppLocalizations l10n,
    required TextDirection textDirection,
    required TextAlign textAlign,
    required TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✓', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Text(
              l10n.reviewAllCaughtUp,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(fontSize: 14, color: AppTheme.retroLight),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.reviewNothingDue,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 9,
                color: AppTheme.retroLight,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required AppLocalizations l10n,
    required TextDirection textDirection,
    required TextAlign textAlign,
    required TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
  }) {
    final item = _current;
    if (item == null) return const SizedBox.shrink();

    final question = item.kind == ReviewItemKind.correction
        ? l10n.reviewCorrectionPrompt
        : l10n.reviewVocabularyPrompt;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.retroLight,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4)),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question,
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: fontFunction(
                        fontSize: 8,
                        color: AppTheme.retroDark.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      item.prompt,
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 16,
                        color: AppTheme.retroDark,
                        height: 1.5,
                      ),
                    ),
                    if (_answerShown) ...[
                      const SizedBox(height: 24),
                      Container(
                        height: 4,
                        color: AppTheme.retroDark.withValues(alpha: 0.15),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        item.answer,
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: fontFunction(
                          fontSize: 14,
                          color: AppTheme.retroGrassDark,
                          height: 1.5,
                        ),
                      ),
                      // Pronunciation, revealed with the answer rather than
                      // shown alongside the prompt. For a non-Latin script
                      // the reading is most of the recall — giving it away
                      // up front would reduce the card to a translation quiz.
                      if (item.reading != null &&
                          item.reading!.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          item.reading!,
                          // Romanization is Latin script whatever the target
                          // language's own direction is.
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          style: fontFunction(
                            fontSize: 10,
                            color: AppTheme.retroDark.withValues(alpha: 0.55),
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (item.context != null &&
                          item.context!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          item.context!,
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: fontFunction(
                            fontSize: 9,
                            color: AppTheme.retroDark.withValues(alpha: 0.7),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_answerShown)
            _buildGradeButtons(l10n: l10n, fontFunction: fontFunction)
          else
            _buildRetroButton(
              label: l10n.reviewShowAnswer,
              color: AppTheme.retroAccent,
              fontFunction: fontFunction,
              textDirection: textDirection,
              onTap: () => setState(() => _answerShown = true),
            ),
        ],
      ),
    );
  }

  Widget _buildGradeButtons({
    required AppLocalizations l10n,
    required TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
  }) {
    final grades = <(ReviewGrade, String, Color)>[
      (ReviewGrade.again, l10n.reviewGradeAgain, AppTheme.retroPrimary),
      (ReviewGrade.hard, l10n.reviewGradeHard, AppTheme.retroOrange),
      (ReviewGrade.good, l10n.reviewGradeGood, AppTheme.retroGrass),
      (ReviewGrade.easy, l10n.reviewGradeEasy, AppTheme.retroSkyLight),
    ];

    return Row(
      children: [
        for (var i = 0; i < grades.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _grade(grades[i].$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: grades[i].$3,
                  border: Border.all(color: AppTheme.retroDark, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.retroDark, offset: Offset(3, 3)),
                  ],
                ),
                child: Text(
                  grades[i].$2,
                  textAlign: TextAlign.center,
                  style: fontFunction(fontSize: 8, color: AppTheme.retroDark),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSessionComplete({
    required AppLocalizations l10n,
    required TextDirection textDirection,
    required TextAlign textAlign,
    required TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
    required CharacterProvider characterProvider,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('★', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 24),
            Text(
              l10n.reviewSessionComplete,
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(fontSize: 14, color: AppTheme.retroLight),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.reviewSessionSummary(_reviewed),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(fontSize: 10, color: AppTheme.retroLight),
            ),
            const SizedBox(height: 32),
            _buildRetroButton(
              label: l10n.reviewDone,
              color: AppTheme.retroGrass,
              fontFunction: fontFunction,
              textDirection: textDirection,
              onTap: () => _finish(characterProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroButton({
    required String label,
    required Color color,
    required TextDirection textDirection,
    required TextStyle Function({
      double? fontSize,
      FontWeight? fontWeight,
      Color? color,
      double? height,
      TextDecoration? decoration,
      double? letterSpacing,
      FontStyle? fontStyle,
    }) fontFunction,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4)),
          ],
        ),
        child: Text(
          label,
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(fontSize: 10, color: AppTheme.retroDark),
        ),
      ),
    );
  }
}
