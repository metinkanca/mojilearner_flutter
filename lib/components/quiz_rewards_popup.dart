import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

class _PixelParticle {
  final double angle;
  final double velocity;
  final double size;
  final Color color;

  const _PixelParticle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.color,
  });
}

class _PixelConfettiPainter extends CustomPainter {
  final List<_PixelParticle> particles;
  final double spreadProgress;
  final double fallProgress;

  const _PixelConfettiPainter({
    required this.particles,
    required this.spreadProgress,
    required this.fallProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final progress = fallProgress;
    final t = progress * 1.05;
    const gravity = 880.0;

    final originX = size.width * 0.5;
    final originY = size.height * -0.1;

    final fadeOut = progress < 0.9
      ? 1.0
      : (1.0 - ((progress - 0.9) / 0.1)).clamp(0.0, 1.0);
    if (fadeOut <= 0) return;

    for (final particle in particles) {
      final vx = math.cos(particle.angle) * particle.velocity;
      final vy = math.sin(particle.angle) * particle.velocity;

      final x = originX + (vx * t * spreadProgress);
      final y = originY + (vy * t) + (0.5 * gravity * t * t);

      if (x < -32 || x > size.width + 32 || y < -32 || y > size.height + 32) {
        continue;
      }

      final fillPaint = Paint()
        ..color = particle.color.withValues(alpha: fadeOut)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = AppTheme.retroDark.withValues(alpha: fadeOut)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final rect = Rect.fromLTWH(x, y, particle.size, particle.size);
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelConfettiPainter oldDelegate) {
    return oldDelegate.spreadProgress != spreadProgress ||
        oldDelegate.fallProgress != fallProgress ||
        oldDelegate.particles != particles;
  }
}

class QuizRewardsPopup extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String level;
  final int xpReward;
  final int coinReward;
  final int happinessDelta;
  final int hungerDelta;
  final bool passed;

  /// True when the pet was sick and the rewards shown are the halved ones,
  /// so the popup can explain why the numbers look low.
  final bool sickPenaltyApplied;
  final VoidCallback onContinue;

  const QuizRewardsPopup({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.level,
    required this.xpReward,
    required this.coinReward,
    required this.happinessDelta,
    required this.hungerDelta,
    required this.passed,
    this.sickPenaltyApplied = false,
    required this.onContinue,
  });

  @override
  State<QuizRewardsPopup> createState() => _QuizRewardsPopupState();
}

class _QuizRewardsPopupState extends State<QuizRewardsPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _overlayFade;
  late Animation<double> _panelScale;
  late Animation<double> _panelFade;
  late Animation<double> _detailsSlide;
  late Animation<double> _rewardPulse;
  late Animation<double> _confettiSpread;
  late Animation<double> _confettiFall;
  late List<_PixelParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _overlayFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
      ),
    );

    _panelScale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _panelFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _detailsSlide = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _rewardPulse = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.elasticOut),
      ),
    );

    _confettiSpread = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _confettiFall = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _particles = _buildParticles();

    _controller.forward();
  }

  List<_PixelParticle> _buildParticles() {
    const paletteA = [Color(0xFFFF9A00), Color(0xFFFF7400), Color(0xFFFF4D00)];
    const paletteB = [Color(0xFF8D960F), Color(0xFFBE0F10), Color(0xFF445404)];
    const paletteC = [Color(0xFFF93963), Color(0xFFA10864), Color(0xFFEE0B93)];
    const palettePixel = [
      AppTheme.retroAccent,
      AppTheme.retroPrimary,
      AppTheme.retroSky,
      AppTheme.retroGrass,
    ];

    final colors = <Color>[...paletteA, ...paletteB, ...paletteC, ...palettePixel]
      
      
      
      ;

    final random = math.Random(42);
    const particleCount = 64;
    const spread = math.pi; // 180 degrees

    return List.generate(particleCount, (index) {
      final angle = math.pi / 2 + (random.nextDouble() - 0.5) * spread;
      final velocity = 330 + random.nextDouble() * 170;
      final size = random.nextBool() ? 10.0 : 12.0;
      final color = colors[index % colors.length];

      return _PixelParticle(
        angle: angle,
        velocity: velocity,
        size: size,
        color: color,
      );
    });
  }

  Widget _buildParticleLayer(Size size) {
    if (_confettiFall.value >= 0.98) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: _PixelConfettiPainter(
            particles: _particles,
            spreadProgress: _confettiSpread.value,
            fallProgress: _confettiFall.value,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final fontFunction =
      settings.usePixelFont ? AppFonts.pressStart2p : AppFonts.spaceMono;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Material(
          color: Colors.black.withValues(alpha: 0.5 * _overlayFade.value),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              return Stack(
                children: [
                  _buildParticleLayer(size),
                  Center(
                    child: Opacity(
                      opacity: _panelFade.value,
                      child: Transform.scale(
                        scale: _panelScale.value,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 340,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border:
                                    Border.all(color: AppTheme.retroDark, width: 4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppTheme.retroDark,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  )
                                ],
                              ),
                              child: Transform.translate(
                                offset: Offset(0, _detailsSlide.value),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.passed
                                          ? 'QUIZ COMPLETE!'
                                          : 'KEEP GOING!',
                                      textDirection: textDirection,
                                      textAlign: TextAlign.center,
                                      style: fontFunction(
                                        fontSize: 12,
                                        color: AppTheme.retroDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.retroLight,
                                        border: Border.all(
                                            color: AppTheme.retroDark, width: 3),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Score: ${widget.score}/${widget.totalQuestions}',
                                            textDirection: TextDirection.ltr,
                                            textAlign: TextAlign.left,
                                            style: fontFunction(
                                              fontSize: 10,
                                              color: AppTheme.retroDark,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Level: ${widget.level}',
                                            textDirection: textDirection,
                                            textAlign: textAlign,
                                            style: fontFunction(
                                              fontSize: 9,
                                              color: AppTheme.retroDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Transform.scale(
                                      scale: _rewardPulse.value,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: widget.passed
                                              ? AppTheme.retroGrass
                                                  .withValues(alpha: 0.25)
                                              : AppTheme.retroAccent
                                                  .withValues(alpha: 0.2),
                                          border: Border.all(
                                              color: AppTheme.retroDark,
                                              width: 3),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'REWARDS',
                                              textDirection: textDirection,
                                              textAlign: textAlign,
                                              style: fontFunction(
                                                fontSize: 9,
                                                color: AppTheme.retroDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '+${widget.xpReward} XP',
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.left,
                                              style: fontFunction(
                                                fontSize: 9,
                                                color: AppTheme.retroDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              widget.happinessDelta >= 0
                                                  ? '+${widget.happinessDelta} Happiness'
                                                  : '${widget.happinessDelta} Happiness',
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.left,
                                              style: fontFunction(
                                                fontSize: 9,
                                                color: AppTheme.retroDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '+${widget.coinReward} Coins',
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.left,
                                              style: fontFunction(
                                                fontSize: 9,
                                                color: AppTheme.retroDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '+${widget.hungerDelta} Hunger',
                                              textDirection: TextDirection.ltr,
                                              textAlign: TextAlign.left,
                                              style: fontFunction(
                                                fontSize: 9,
                                                color: AppTheme.retroDark,
                                              ),
                                            ),
                                            if (widget.sickPenaltyApplied) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Moji is sick — rewards halved',
                                                textDirection: textDirection,
                                                textAlign: textAlign,
                                                style: fontFunction(
                                                  fontSize: 8,
                                                  color: AppTheme.retroAccent,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    GestureDetector(
                                      onTap: widget.onContinue,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.retroPrimary,
                                          border: Border.all(
                                              color: AppTheme.retroDark,
                                              width: 3),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppTheme.retroDark,
                                              offset: Offset(2, 2),
                                              blurRadius: 0,
                                            )
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'CONTINUE',
                                            textDirection: textDirection,
                                            textAlign: TextAlign.center,
                                            style: fontFunction(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.none,
                                            ),
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
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
