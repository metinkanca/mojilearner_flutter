/// Debris for the boss arena: chunks thrown out when the boss lands, pebbles
/// shaken off the ledge, and rubble shattering.
///
/// Particles are square pixels on whole-pixel positions, drawn in the boss's
/// own stone and moss colours, so the debris reads as pieces of the same art
/// rather than an effect laid over it. They never fade — a pixel-art chunk
/// that goes translucent looks like a rendering bug — they shrink a step at a
/// time and are gone.
library;

import 'dart:math';

import 'package:flutter/widgets.dart';

/// Colours lifted from Mossback's art, so its debris is its own stone.
class DebrisPalette {
  DebrisPalette._();
  static const Color outline = Color(0xFF11120D);
  static const Color stone = Color(0xFF989387);
  static const Color seam = Color(0xFF4F504B);
  static const Color moss = Color(0xFF7E8A3E);
  static const Color dust = Color(0xFFC9C3B1);

  static const List<Color> chunks = [stone, stone, seam, moss, outline];

  /// Spell light: the pet's magic, deliberately not a stone colour.
  static const Color rune = Color(0xFF6DC2CA);
  static const Color runeLight = Color(0xFFCBF1F5);
  static const Color fizzle = Color(0xFFD95763);
}

class TrialParticle {
  TrialParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    this.gravity = 900,
    this.front = false,
  });

  double x, y, vx, vy;
  final double size;
  final Color color;

  /// Seconds it lives for.
  final double life;
  double age = 0;
  final double gravity;

  /// Drawn in front of the pet rather than behind it.
  final bool front;

  bool get isDead => age >= life;

  /// Size after shrinking, in whole pixels: full for most of its life, then
  /// stepping down to nothing.
  double get drawnSize {
    final left = 1 - age / life;
    if (left > 0.35) return size;
    return max(1, (size * left / 0.35).roundToDouble());
  }
}

/// Every live particle, stepped by the arena's game clock.
class TrialParticles extends ChangeNotifier {
  TrialParticles({Random? random}) : _rng = random ?? Random();

  final Random _rng;
  final List<TrialParticle> _items = [];

  List<TrialParticle> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;

  double _between(double a, double b) => a + _rng.nextDouble() * (b - a);

  /// Advances every particle by [dt] seconds. Anything below [floor] has hit
  /// the ground and is gone.
  void update(double dt, {required double floor}) {
    if (_items.isEmpty) return;
    for (final p in _items) {
      p.age += dt;
      p.vy += p.gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }
    _items.removeWhere((p) => p.isDead || p.y > floor);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// The landing: chunks kicked out from both feet, arcing away to the sides.
  ///
  /// [left] and [right] are where the outermost feet meet the ledge, [scale]
  /// sizes the chunks to the boss as drawn.
  void landing({
    required Offset left,
    required Offset right,
    required double scale,
  }) {
    for (final (origin, dir) in [(left, -1.0), (right, 1.0)]) {
      for (var i = 0; i < 13; i++) {
        _items.add(TrialParticle(
          x: origin.dx + _between(-8, 8),
          y: origin.dy - _between(0, 8),
          vx: dir * _between(60, 280) * scale,
          vy: -_between(160, 380) * scale,
          // A few big chunks among the gravel, so it reads as the ledge
          // breaking rather than as sparks.
          size: (i < 3 ? _between(9, 13) : _between(4, 8)).roundToDouble() *
              scale,
          color: DebrisPalette.chunks[_rng.nextInt(DebrisPalette.chunks.length)],
          life: _between(0.9, 1.6),
        ));
      }
      // A puff of dust that hangs rather than flies.
      for (var i = 0; i < 5; i++) {
        _items.add(TrialParticle(
          x: origin.dx + dir * _between(0, 18),
          y: origin.dy - _between(2, 10),
          vx: dir * _between(10, 50),
          vy: -_between(10, 40),
          size: _between(3, 6).roundToDouble() * scale,
          color: DebrisPalette.dust,
          life: _between(0.35, 0.6),
          gravity: 40,
        ));
      }
    }
    notifyListeners();
  }

  /// Pebbles shaken loose along the ledge by the landing, falling down the
  /// edges of the arena.
  void shakeLoose({required double width, required double ledgeY}) {
    for (var i = 0; i < 10; i++) {
      final nearLeft = i.isEven;
      final x = nearLeft
          ? _between(4, width * 0.18)
          : _between(width * 0.82, width - 4);
      _items.add(TrialParticle(
        x: x,
        y: ledgeY + _between(0, 4),
        vx: _between(-15, 15),
        vy: _between(0, 60),
        size: _between(2, 6).roundToDouble(),
        color: DebrisPalette.chunks[_rng.nextInt(DebrisPalette.chunks.length)],
        life: _between(1.2, 2.0),
        gravity: _between(500, 800),
      ));
    }
    notifyListeners();
  }

  /// A piece of rubble breaking apart where it is — in the boss's stone, or
  /// in [colors] for a block that is not stone.
  void shatter(Rect rect, {bool front = true, List<Color>? colors}) {
    final palette = colors ?? DebrisPalette.chunks;
    for (var i = 0; i < 12; i++) {
      _items.add(TrialParticle(
        x: _between(rect.left, rect.right),
        y: _between(rect.top, rect.bottom),
        vx: _between(-90, 90),
        vy: -_between(20, 160),
        size: _between(3, 7).roundToDouble(),
        color: palette[_rng.nextInt(palette.length)],
        life: _between(0.5, 0.9),
        front: front,
      ));
    }
    notifyListeners();
  }

  /// Sand blown off [rect] by a wind going [dir] (+1 right, -1 left): grains
  /// streaming away along it, hardly falling.
  void gust(Rect rect, {required double dir, List<Color>? colors}) {
    final palette = colors ?? DebrisPalette.chunks;
    for (var i = 0; i < 9; i++) {
      _items.add(TrialParticle(
        x: _between(rect.left, rect.right),
        y: _between(rect.top, rect.bottom),
        vx: dir * _between(160, 340),
        vy: -_between(0, 50),
        size: _between(2, 5).roundToDouble(),
        color: palette[_rng.nextInt(palette.length)],
        life: _between(0.45, 0.9),
        gravity: 60,
        front: true,
      ));
    }
    notifyListeners();
  }

  /// Spell light scattering from [at]: a trail behind a bolt, a stone
  /// finding its place, or — in [DebrisPalette.fizzle] — a stone refusing.
  ///
  /// [colors], when given, replaces the spell light — the home game's catch
  /// sparkles in the pet's own heart colours.
  void sparks(
    Offset at, {
    int count = 6,
    bool fizzle = false,
    List<Color>? colors,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = _between(0, 2 * pi);
      final speed = _between(20, 110);
      _items.add(TrialParticle(
        x: at.dx + _between(-4, 4),
        y: at.dy + _between(-4, 4),
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: _between(2, 5).roundToDouble(),
        color: colors != null
            ? colors[i % colors.length]
            : fizzle
                ? DebrisPalette.fizzle
                : (i.isEven ? DebrisPalette.rune : DebrisPalette.runeLight),
        life: _between(0.25, 0.5),
        gravity: fizzle ? 400 : 60,
        front: true,
      ));
    }
    notifyListeners();
  }

  /// Rubble bursting against the boss.
  void impact(Offset at, {required double scale}) {
    for (var i = 0; i < 14; i++) {
      final angle = _between(-pi, 0);
      final speed = _between(80, 260) * scale;
      _items.add(TrialParticle(
        x: at.dx,
        y: at.dy,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: _between(3, 7).roundToDouble() * scale,
        color: DebrisPalette.chunks[_rng.nextInt(DebrisPalette.chunks.length)],
        life: _between(0.5, 1.0),
        front: true,
      ));
    }
    notifyListeners();
  }
}

/// Paints one layer of [particles]: those in front of the pet, or those
/// behind it.
class TrialParticlePainter extends CustomPainter {
  TrialParticlePainter(this.particles, {required this.front})
      : super(repaint: particles);

  final TrialParticles particles;
  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (final p in particles.items) {
      if (p.front != front) continue;
      final s = p.drawnSize;
      paint.color = p.color;
      canvas.drawRect(
        Rect.fromLTWH(
            (p.x - s / 2).roundToDouble(), (p.y - s / 2).roundToDouble(), s, s),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TrialParticlePainter old) =>
      old.particles != particles || old.front != front;
}
