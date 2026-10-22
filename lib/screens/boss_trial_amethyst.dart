part of 'boss_trial_screen.dart';

// Amethyst's fourth opener under test, the Vein, beside its Spikes, Echo and
// Volley (which play out in the screen itself). The rules are in
// `utils/boss_trial_crystal.dart`; this is its clock, its layout and its
// taps. It shares Sableth's talk panel and field (`boss_trial_sableth.dart`).

class _VeinRound extends _ClockRound {
  _VeinRound(this.wave, double seconds)
      : play = VeinPlay(wave),
        super(seconds);
  final VeinWave wave;
  final VeinPlay play;
}

extension _VeinFlow on _BossTrialScreenState {
  void _beginVein() {
    final wave = VeinWave.build(_sentences,
        previous: _lastAs<TrialSentence>(), random: _rng);
    if (wave == null) {
      _throwWave();
      return;
    }
    _beginClockRound(() {
      _vein = _VeinRound(
        wave,
        _BossTrialScreenState._secs(CrystalRules.veinTime(
            words: wave.sentence.tokens.length, patience: _clockPatience)),
      );
      _lastAsked = wave.sentence;
    });
  }

  /// Crystal [cell] of the wall, in the field.
  Rect _veinRect(_Geo geo, int cell) {
    const gap = 6.0;
    const side = VeinWave.side;
    final space = _fieldBottom(geo) - _fieldTop(geo);
    final h = min(44.0, (space - gap * (side - 1)) / side).floorToDouble();
    final w =
        min((geo.w - 24 - gap * (side - 1)) / side, 110.0).floorToDouble();
    final left = ((geo.w - (w * side + gap * (side - 1))) / 2).roundToDouble();
    final top = _fieldTop(geo) +
        ((space - (h * side + gap * (side - 1))) / 2).roundToDouble();
    return Rect.fromLTWH(left + (cell % side) * (w + gap),
        top + (cell ~/ side) * (h + gap), w, h);
  }

  void _tapCrystal(int cell) {
    final round = _vein;
    final geo = _geo;
    if (_phase != _Phase.playing ||
        _stage != _Stage.veining ||
        round == null ||
        geo == null ||
        round.over) {
      return;
    }
    final at = _veinRect(geo, cell).center;
    switch (round.play.tap(cell)) {
      case VeinTap.ignored:
        return;
      case VeinTap.wrong:
        _refused(geo, round, cell, CrystalRules.veinMistakeCreep, at,
            said: 'off the vein');
      case VeinTap.next:
        HapticFeedback.selectionClick();
        _refresh();
        if (!_reduceMotion) {
          _particles.sparks(at, count: 8, colors: CrystalPalette.shards);
          // A hop for each crystal lit, facing it (`_watchPhase`).
          if (_move == null) _petHop = 0;
        }
      case VeinTap.done:
        // The whole vein lit, the pet rears back and casts it as a CRYSTAL; the
        // crystals stay lit through the wind-up and burst as it leaves.
        _answeredByCast(geo, round, at, look: _ShotLook.crystal,
            onRelease: (geo) {
          if (_reduceMotion) return;
          for (final c in round.wave.path) {
            _particles.shatter(_veinRect(geo, c),
                colors: CrystalPalette.shards);
          }
        });
    }
  }

  List<Widget> _buildVein(_Geo geo, _VeinRound round) {
    if (_stage == _Stage.jumping) return const [];
    final wave = round.wave;
    final style =
        _pixel(9, _BossTrialScreenState._ink, localeCode: _languageCode);
    final next = round.play.followed < wave.path.length
        ? wave.path[round.play.followed]
        : null;
    return [
      _talk(geo, wave.sentence.meaning, round.clock, label: 'FOLLOW THE VEIN'),
      for (var cell = 0; cell < wave.cells.length; cell++)
        Positioned.fromRect(
          rect: _veinRect(geo, cell),
          child: SkinTile(
            skin: _boss.skin,
            label: wave.cells[cell],
            style: style,
            // The vein's first crystal glows until it is tapped; the lit
            // ones stay lit; when the amethyst closes, the rest of the vein
            // shows.
            badge: round.play.isLit(cell)
                ? '${wave.path.indexOf(cell) + 1}'
                : null,
            state: round.isFlashing(cell)
                ? TileState.flashing
                : round.play.isLit(cell) ||
                        (round.lost && wave.path.contains(cell))
                    ? TileState.right
                    : cell == next && round.play.followed == 0
                        ? TileState.held
                        : TileState.plain,
            onTapDown: () => _tapCrystal(cell),
          ),
        ),
    ];
  }
}

extension _CrystalFront on _BossTrialScreenState {
  /// What the pet holds up over its head, drawn over it: a gem it has scooped
  /// up, a shard it has caught.
  List<Widget> _buildHeldFront(_Geo geo) {
    if (_reduceMotion || _time < _heldFrom || _time >= _heldUntil) {
      return const [];
    }
    final at = _plaqueRide(geo, const Size(26, 26)).translate(0, -4);
    return [
      Positioned(
        key: const ValueKey('held-crystal'),
        left: (at.dx - 13).roundToDouble(),
        top: (at.dy - 13).roundToDouble(),
        width: 26,
        height: 26,
        child: IgnorePointer(
          child: _heldGem ? const SpellBolt() : const CrystalChunk(),
        ),
      ),
    ];
  }
}
