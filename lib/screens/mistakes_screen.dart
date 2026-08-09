import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/mistakes_provider.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

class MistakesScreen extends StatefulWidget {
  const MistakesScreen({super.key});

  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  String selectedFilter = 'all'; // 'all', 'grammar', 'vocabulary'

  void _showExplanationDialog(BuildContext context, Mistake mistake) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 4),
            boxShadow: const [
              BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(8, 8),
                  blurRadius: 0),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.grammarBreakdown,
                  textDirection: textDirection,
                  textAlign: textAlign,
                    style: AppFonts.pressStart2p(
                        fontSize: 14, color: AppTheme.retroDark)),
                const SizedBox(height: 24),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.red, width: 2)),
                    child: Text(mistake.original,
                      textDirection: textDirection,
                      textAlign: textAlign,
                        style: AppFonts.spaceMono(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.red[900]))),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.green, width: 2)),
                    child: Text(mistake.correction,
                      textDirection: textDirection,
                      textAlign: textAlign,
                        style: AppFonts.spaceMono(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900]))),
                const Divider(
                    height: 32, thickness: 4, color: AppTheme.retroDark),
                Text(mistake.explanation.isNotEmpty ? mistake.explanation : l10n.noGrammarAnalysis,
                  textDirection: textDirection,
                  textAlign: textAlign,
                    style: AppFonts.spaceMono(fontSize: 14, height: 1.5)),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.retroAccent,
                        border: Border.all(color: AppTheme.retroDark, width: 4),
                        boxShadow: const [
                          BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(4, 4),
                              blurRadius: 0)
                        ],
                      ),
                        child: Text(l10n.close.toUpperCase(),
                          textDirection: textDirection,
                          textAlign: TextAlign.center,
                          style: AppFonts.pressStart2p(
                              fontSize: 12, color: AppTheme.retroDark)),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    final mistakesProvider = Provider.of<MistakesProvider>(context);
    final validMistakes = mistakesProvider.mistakes
        .where((m) => m.type != 'style')
        .toList()
        .reversed
        .toList();

    final filteredMistakes = selectedFilter == 'all'
        ? validMistakes
        : validMistakes.where((m) => m.type == selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Retro AppBar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.retroDark, width: 4)),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.retroDark, width: 4),
                        boxShadow: const [
                          BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(2, 2))
                        ],
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppTheme.retroDark),
                    ),
                  ),
                  const SizedBox(width: 16),
                    Text(l10n.mistakes,
                      textDirection: textDirection,
                      textAlign: textAlign,
                      style: AppFonts.pressStart2p(
                          fontSize: 20, color: AppTheme.retroDark)),
                ],
              ),
            ),

            // Filter Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildRetroChip('all', l10n.all),
                    const SizedBox(width: 12),
                    _buildRetroChip('grammar', l10n.grammar),
                    const SizedBox(width: 12),
                    _buildRetroChip('vocabulary', l10n.vocabulary),
                  ],
                ),
              ),
            ),

            // List
            Expanded(
              child: filteredMistakes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 64,
                              color: AppTheme.retroDark.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noMistakesYet,
                            textDirection: textDirection,
                            textAlign: textAlign,
                            style: AppFonts.pressStart2p(
                                color: AppTheme.retroDark.withValues(alpha: 0.5),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: filteredMistakes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final mistake = filteredMistakes[index];
                        return _buildMistakeCard(context, mistake);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetroChip(String key, String label) {
    final isSelected = selectedFilter == key;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.retroAccent : Colors.white,
          border: Border.all(
              color: AppTheme.retroDark, width: isSelected ? 4 : 2),
          boxShadow: isSelected
              ? const [
                  BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4))
                ]
              : null,
        ),
        child: Text(
          label.toUpperCase(),
          textDirection: textDirection,
          textAlign: textAlign,
          style: AppFonts.pressStart2p(
              fontSize: 10,
              color: isSelected ? AppTheme.retroDark : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMistakeCard(BuildContext context, Mistake mistake) {
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 4),
        boxShadow: const [
          BoxShadow(color: AppTheme.retroDark, offset: Offset(6, 6))
        ],
      ),
      child: Column(
        children: [
          // Header of card
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppTheme.retroDark, width: 2)),
                color: AppTheme.retroLight),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.orange[800]),
                const SizedBox(width: 8),
                Text(mistake.type.toUpperCase(),
                  textDirection: textDirection,
                  textAlign: textAlign,
                    style: AppFonts.pressStart2p(
                        fontSize: 10, color: AppTheme.retroDark)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showExplanationDialog(context, mistake),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.retroSkyLight,
                      border: Border.all(color: AppTheme.retroDark, width: 2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 12),
                        const SizedBox(width: 4),
                        Text("INFO",
                          textDirection: textDirection,
                          textAlign: textAlign,
                            style: AppFonts.pressStart2p(fontSize: 8)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(mistake.original,
                  textDirection: textDirection,
                  textAlign: textAlign,
                    style: AppFonts.spaceMono(
                        fontSize: 16,
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough)),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_downward, size: 20),
                const SizedBox(height: 8),
                Text(mistake.correction,
                  textDirection: textDirection,
                  textAlign: textAlign,
                    style: AppFonts.spaceMono(
                        fontSize: 16,
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
