import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/theme.dart';
import '../providers/language_provider.dart';

class MessageBubble extends StatefulWidget {
  final String text;
  final bool isUser;
  final String? translation;
  final String? grammarAnalysis;

  const MessageBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.translation,
    this.grammarAnalysis,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTranslation = false;

  void _showGrammar(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final translations = languageProvider.getTranslations();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(), // Square dialog
        title: Text(translations['grammarBreakdown'] ?? "Grammar Breakdown", style: GoogleFonts.pressStart2p(color: AppTheme.retroPrimary, fontSize: 12)),
        content: SingleChildScrollView(
          child: Text(widget.grammarAnalysis ?? translations['noGrammarAnalysis'] ?? "No grammar analysis available.", style: GoogleFonts.pressStart2p(fontSize: 10, height: 1.5, color: AppTheme.retroDark)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(translations['close'] ?? "Close", style: GoogleFonts.pressStart2p(color: AppTheme.retroDark, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBot = !widget.isUser;
    
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
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: SvgPicture.asset('assets/svgs/pet.svg', fit: BoxFit.contain),
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
                              style: GoogleFonts.pressStart2p(
                                color: AppTheme.retroDark, 
                                fontSize: 10,
                                height: 1.6
                              ),
                            ),
                            // Translation
                            if (_showTranslation && widget.translation != null) ...[
                              const SizedBox(height: 8),
                              Divider(color: AppTheme.retroDark.withOpacity(0.2), thickness: 2),
                              const SizedBox(height: 4),
                              Text(
                                widget.translation!,
                                style: GoogleFonts.pressStart2p(
                                  color: AppTheme.retroDark.withOpacity(0.6),
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
                            style: GoogleFonts.pressStart2p(color: AppTheme.retroDark, fontSize: 8),
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