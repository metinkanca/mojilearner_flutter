import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../components/character_sprite.dart';
import '../l10n/app_localizations.dart';
import '../utils/rtl_locale.dart';
import '../../utils/fonts.dart';

class MessageBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final String? translation;
  final String? grammarAnalysis;

  /// Romanized pronunciation of [text], for non-Latin scripts.
  final String? reading;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.translation,
    this.grammarAnalysis,
    this.reading,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTranslation = false;

  void _showGrammar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(), // Square dialog
        title: Text(
          l10n.grammarBreakdown,
          textDirection: textDirection,
          textAlign: textAlign,
          style: AppFonts.pressStart2p(
            color: AppTheme.retroPrimary,
            fontSize: 12,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            widget.grammarAnalysis ?? l10n.noGrammarAnalysis,
            textDirection: textDirection,
            textAlign: textAlign,
            style: AppFonts.pressStart2p(
              fontSize: 10,
              height: 1.5,
              color: AppTheme.retroDark,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.close,
              textDirection: textDirection,
              textAlign: textAlign,
              style: AppFonts.pressStart2p(
                color: AppTheme.retroDark,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBot = !widget.isUser;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);
    
    // Bubble Layout
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: widget.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot Avatar (Left)
          if (isBot) ...[
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.retroPrimary,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))]
              ),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: CharacterSprite(
                  width: 36,
                  height: 36,
                ),
              ), 
            ),
            const SizedBox(width: 12),
          ],

          // The Message Bubble
          Flexible(
            child: GestureDetector(
              onTap: isBot && widget.translation != null 
                ? () => setState(() => _showTranslation = !_showTranslation)
                : null,
              child: Column(
                crossAxisAlignment: widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                   Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isUser ? AppTheme.retroSkyLight : Colors.white,
                          border: Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.text,
                              textDirection: textDirection,
                              textAlign: textAlign,
                              style: AppFonts.pressStart2p(
                                color: AppTheme.retroDark, 
                                fontSize: 10,
                                height: 1.6
                              ),
                            ),
                            // Pronunciation. Always visible rather than
                            // hidden behind the translation tap: a learner
                            // who cannot read the script needs this to follow
                            // along at all, not on demand.
                            if (widget.reading != null &&
                                widget.reading!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                widget.reading!,
                                // Romanization is Latin script regardless of
                                // the target language's own direction.
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: AppFonts.pressStart2p(
                                  color: AppTheme.retroDark
                                      .withValues(alpha: 0.55),
                                  fontSize: 8,
                                  height: 1.6,
                                ),
                              ),
                            ],
                            // Translation
                            if (_showTranslation && widget.translation != null) ...[
                              const SizedBox(height: 8),
                              Divider(color: AppTheme.retroDark.withValues(alpha: 0.2), thickness: 2),
                              const SizedBox(height: 4),
                              Text(
                                widget.translation!,
                                textDirection: textDirection,
                                textAlign: textAlign,
                                style: AppFonts.pressStart2p(
                                  color: AppTheme.retroDark.withValues(alpha: 0.6),
                                  fontSize: 8,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Pixel Tail
                      Positioned(
                        bottom: 6,
                        left: isBot ? -8 : null,
                        right: widget.isUser ? -8 : null,
                        child: CustomPaint(
                          size: const Size(8, 8),
                          painter: PixelBubbleTailPainter(isLeft: isBot, color: widget.isUser ? const Color(0xFF9dc4ff) : Colors.white),
                        ),
                      )
                    ],
                  ),
                  // Grammar Button
                  if (isBot && widget.grammarAnalysis != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: InkWell(
                        onTap: () => _showGrammar(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                           decoration: BoxDecoration(
                              color: AppTheme.retroAccent,
                              border: Border.all(color: AppTheme.retroDark, width: 2),
                              boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))]
                            ),
                          child: Text(
                            "?",
                            style: AppFonts.pressStart2p(color: AppTheme.retroDark, fontSize: 8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PixelBubbleTailPainter extends CustomPainter {
  final bool isLeft;
  final Color color;
  
  PixelBubbleTailPainter({required this.isLeft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.retroDark..style = PaintingStyle.fill;
    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;

    if (isLeft) {
       // Border
       canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 4), paint);
       canvas.drawRect(const Rect.fromLTWH(4, 4, 4, 4), paint);
       // Fill (Masking to look connected)
       canvas.drawRect(const Rect.fromLTWH(4, 0, 4, 4), fillPaint);
    } else {
       // Right side logic mirrored
       canvas.drawRect(const Rect.fromLTWH(4, 0, 4, 4), paint);
       canvas.drawRect(const Rect.fromLTWH(0, 4, 4, 4), paint);
       
       canvas.drawRect(const Rect.fromLTWH(0, 0, 4, 4), fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}