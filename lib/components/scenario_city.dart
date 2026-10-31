import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../constants/scenarios.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/scenario_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import 'character_sprite.dart';

/// The town the scenarios live in: one building per scenario along a few
/// streets, and the player's pet — the only pet in town — walking to the door
/// of whichever one is picked. A place's host is met inside it, in its chat.
///
/// The ground is `assets/svgs/city_ground.svg` and each place is its own
/// `city_*.svg`, all cut by `art_src/gen_city.py` from the owner's one picture
/// of the town, so every building stands where the owner put it. The generator
/// also writes the numbers in [CityLayout], and `scenario_city_layout_test.dart`
/// checks them against the pictures.
class ScenarioCityMap extends StatefulWidget {
  const ScenarioCityMap({
    super.key,
    required this.selectedId,
    required this.onSelect,
  });

  /// The scenario the player's pet is heading to, or null while it waits in
  /// the square.
  final String? selectedId;

  /// A building or its host was tapped (its id), or the open ground (null).
  final ValueChanged<String?> onSelect;

  @override
  State<ScenarioCityMap> createState() => _ScenarioCityMapState();
}

/// The wall colour of a place's room — what its chat shows before the picture
/// of it has drawn, and the swatch on its card. These are the town palette's
/// own colours (`MASTER` in `art_src/gen_city.py`), so the wall, the card and
/// the room's picture are the same colour.
Color scenarioPlaceColor(String scenarioId) {
  switch (scenarioId) {
    case 'coffee':
      return const Color(0xFFf2a636);
    case 'job_interview':
      return const Color(0xFFcfc3b1);
    case 'directions':
      return const Color(0xFF8dd4f3);
    case 'doctor':
      return const Color(0xFFf6eedb);
    case 'shopping':
      return const Color(0xFF8e73ce);
    case 'restaurant':
      return const Color(0xFFef8169);
    default:
      return AppTheme.retroUi;
  }
}

/// One place on the map: its picture, the box the picture fills, the middle of
/// its door, and the line of paving the player's pet stands on in front of it.
/// All in world units, as printed by `art_src/gen_city.py`.
class _CitySpot {
  const _CitySpot({
    required this.art,
    required this.bounds,
    required this.doorX,
    required this.pavement,
    required this.chipDy,
  });

  /// The building's file in `assets/svgs/`, without the extension.
  final String art;
  final Rect bounds;
  final double doorX;
  final double pavement;

  /// How far below the top of the box the building's roof is at its right-hand
  /// end, which is where its progress tally sits. A building's box is as tall
  /// as its tallest part — the town hall's flagpole — and the tally belongs on
  /// the roof, not floating at the top of the box.
  final double chipDy;
}

/// Where everything in the town is. One unit is 2.6 pixels of the owner's
/// picture (`city_ground.svg` and each building are 2 units to a cell of their
/// art), so every number here can be measured off the picture directly.
///
/// The town hall and the school stand side by side at the top, the avenue
/// running up between them off the top of the map, with a row of two places
/// either side of it below and the kiosk by the square at the bottom. The pet
/// only ever walks along the paths (see [CityLayout.route]).
class CityLayout {
  const CityLayout(this.places);

  /// How many scenarios the map has to seat.
  final int places;

  /// The town ground, drawn at 1:1 with these units.
  static const String groundAsset = 'assets/svgs/city_ground.svg';
  static const Size mapSize = Size(1024, 2250);

  /// The avenue down the middle, which every route runs along.
  static const double avenueX = 512;

  /// Where each place stands, as printed by `python art_src/gen_city.py`.
  static const Map<String, _CitySpot> _spots = {
    'restaurant': _CitySpot(
      art: 'city_restaurant',
      bounds: Rect.fromLTWH(6, 614, 446, 396),
      doorX: 224,
      pavement: 1040,
      chipDy: 94,
    ),
    'shopping': _CitySpot(
      art: 'city_shop',
      bounds: Rect.fromLTWH(576, 634, 446, 370),
      doorX: 806,
      pavement: 1040,
      chipDy: 58,
    ),
    'doctor': _CitySpot(
      art: 'city_clinic',
      bounds: Rect.fromLTWH(6, 1150, 436, 392),
      doorX: 218,
      pavement: 1552,
      chipDy: 108,
    ),
    'coffee': _CitySpot(
      art: 'city_cafe',
      bounds: Rect.fromLTWH(592, 1116, 418, 402),
      doorX: 808,
      pavement: 1552,
      chipDy: 100,
    ),
    'job_interview': _CitySpot(
      art: 'city_office',
      bounds: Rect.fromLTWH(6, 178, 446, 354),
      doorX: 229,
      pavement: 562,
      chipDy: 80,
    ),
    // A gazebo, with no door: the pet stands at its middle, on the path that
    // ends there.
    'directions': _CitySpot(
      art: 'city_kiosk',
      bounds: Rect.fromLTWH(712, 1770, 236, 244),
      doorX: 800,
      pavement: 2032,
      chipDy: 80,
    ),
  };

  /// The school beside the town hall: the way into the quizzes. Not a scenario,
  /// so it has no host, no objectives and no tally -- its card shows the day's
  /// quizzes instead -- and it is not in [_spots]. Printed by `gen_city.py` like
  /// the rest.
  static const _CitySpot _school = _CitySpot(
    art: 'city_school',
    bounds: Rect.fromLTWH(576, 88, 446, 444),
    doorX: 799,
    pavement: 562,
    chipDy: 0,
  );

  /// The id the map reports for a tap on the school, and is told to walk to. No
  /// scenario has it.
  static const String schoolId = 'school';

  // BEGIN paths (written by art_src/gen_city.py)
  static const Map<String, Offset> _nodes = {
    'top': Offset(512, 562),
    'walk': Offset(512, 1040),
    'gate': Offset(512, 2032),
    'start': Offset(512, 2130),
    'ring0': Offset(512, 1550),
    'ring1': Offset(587, 1568),
    'ring2': Offset(642, 1616),
    'ring3': Offset(662, 1682),
    'ring4': Offset(642, 1748),
    'ring5': Offset(587, 1796),
    'ring6': Offset(512, 1814),
    'ring7': Offset(437, 1796),
    'ring8': Offset(382, 1748),
    'ring9': Offset(362, 1682),
    'ring10': Offset(382, 1616),
    'ring11': Offset(437, 1568),
    'job_interview': Offset(229, 562),
    'restaurant': Offset(224, 1040),
    'shopping': Offset(806, 1040),
    'doctor': Offset(218, 1552),
    'coffee': Offset(808, 1552),
    'directions': Offset(800, 2032),
    'school': Offset(799, 562),
    'arm_w': Offset(218, 1682),
    'arm_e': Offset(808, 1682),
  };

  static const List<(String, String)> _links = [
    ('top', 'job_interview'),
    ('top', 'school'),
    ('top', 'walk'),
    ('walk', 'restaurant'),
    ('walk', 'shopping'),
    ('walk', 'ring0'),
    ('gate', 'directions'),
    ('gate', 'start'),
    ('gate', 'ring6'),
    ('ring9', 'arm_w'),
    ('arm_w', 'doctor'),
    ('ring3', 'arm_e'),
    ('arm_e', 'coffee'),
    ('ring0', 'ring1'),
    ('ring1', 'ring2'),
    ('ring2', 'ring3'),
    ('ring3', 'ring4'),
    ('ring4', 'ring5'),
    ('ring5', 'ring6'),
    ('ring6', 'ring7'),
    ('ring7', 'ring8'),
    ('ring8', 'ring9'),
    ('ring9', 'ring10'),
    ('ring10', 'ring11'),
    ('ring11', 'ring0'),
  ];
  // END paths

  static final _PathGraph _graph = _PathGraph(_nodes, _links);

  static _CitySpot _spotAt(int index) =>
      _spots[ScenarioCatalog.all[index].id] ?? _spots['coffee']!;

  Size get world => mapSize;

  /// Where the player's pet waits when the map opens: the foot of the avenue,
  /// below the square.
  Offset get start => const Offset(avenueX, 2130);

  /// The fountain in the square, which the pet hops around while idle.
  Offset get fountain => const Offset(512, 1670);

  Rect lot(int index) => _spotAt(index).bounds;

  /// The building's picture, as an asset path.
  String artAsset(int index) => 'assets/svgs/${_spotAt(index).art}.svg';

  /// The middle of a place's door, which the player's pet stops in front of.
  double doorX(int index) => _spotAt(index).doorX;

  /// The line of paving the player's pet stands on at a place.
  double pavementLine(int index) => _spotAt(index).pavement;

  /// Where its tally sits, down from the top of its box: see [_CitySpot.chipDy].
  double chipDy(int index) => _spotAt(index).chipDy;

  /// Whether a place stands left of the footpath.
  static bool isLeftLot(int index) => _spotAt(index).doorX < avenueX;

  /// The school: where it stands, its picture, and where the pet stops at it.
  Rect get schoolLot => _school.bounds;
  String get schoolArt => 'assets/svgs/${_school.art}.svg';
  Offset get schoolDoorSpot => Offset(_school.doorX, _school.pavement);
  static bool get schoolIsLeft => _school.doorX < avenueX;

  /// Where the player's pet stops: on the paving in front of the door.
  Offset doorSpot(int index) {
    final spot = _spotAt(index);
    return Offset(spot.doorX, spot.pavement);
  }

  /// The paths, as the straight links between their junctions: the avenue, the
  /// walkway, the arms and stubs to the doors, and a line round the square's
  /// fountain. Every one is on the paving, which `gen_city.py` checks.
  List<(Offset, Offset)> get pathLinks => [
        for (final (a, b) in _links) (_nodes[a]!, _nodes[b]!),
      ];

  /// The points to walk through from [from] to [to], along the paths: down the
  /// avenue, round the fountain, along a walkway or up a stub, whichever is
  /// shortest. [from] may be anywhere (it joins the nearest path first); [to]
  /// is a door spot. Empty when [from] is already there.
  List<Offset> route(Offset from, Offset to) => _graph.route(from, to);
}

/// The paths as a graph of junctions and straight links, and the shortest way
/// along them between two points.
class _PathGraph {
  _PathGraph(this.nodes, this.links);

  final Map<String, Offset> nodes;
  final List<(String, String)> links;

  /// The nearest point to [p] on any link: which link, how far along it
  /// (0 to 1), and where that is.
  (int, double, Offset) _snap(Offset p) {
    var best = (0, 0.0, Offset.zero);
    var bestDistance = double.infinity;
    for (var i = 0; i < links.length; i++) {
      final a = nodes[links[i].$1]!;
      final b = nodes[links[i].$2]!;
      final ab = b - a;
      final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) /
              (ab.dx * ab.dx + ab.dy * ab.dy))
          .clamp(0.0, 1.0);
      final at = a + ab * t;
      final distance = (p - at).distance;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = (i, t, at);
      }
    }
    return best;
  }

  List<Offset> route(Offset from, Offset to) {
    if ((from - to).distance < 0.5) return const [];
    final names = nodes.keys.toList();
    final points = [for (final name in names) nodes[name]!];
    final start = _snap(from);
    final end = _snap(to);
    final fromIndex = points.length;
    points.add(start.$3);
    final toIndex = points.length;
    points.add(end.$3);

    // Along each link, its two junctions and any end that was put on it, in
    // order, each joined to the next.
    final adjacent = List.generate(points.length, (_) => <int>[]);
    for (var i = 0; i < links.length; i++) {
      final along = <(double, int)>[
        (0, names.indexOf(links[i].$1)),
        (1, names.indexOf(links[i].$2)),
        if (start.$1 == i) (start.$2, fromIndex),
        if (end.$1 == i) (end.$2, toIndex),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      for (var k = 0; k + 1 < along.length; k++) {
        adjacent[along[k].$2].add(along[k + 1].$2);
        adjacent[along[k + 1].$2].add(along[k].$2);
      }
    }

    // Dijkstra over a few dozen points.
    final cost = List.filled(points.length, double.infinity);
    final before = List.filled(points.length, -1);
    final done = List.filled(points.length, false);
    cost[fromIndex] = 0;
    for (;;) {
      var here = -1;
      for (var i = 0; i < points.length; i++) {
        if (!done[i] && cost[i].isFinite && (here < 0 || cost[i] < cost[here])) {
          here = i;
        }
      }
      if (here < 0 || here == toIndex) break;
      done[here] = true;
      for (final next in adjacent[here]) {
        final c = cost[here] + (points[next] - points[here]).distance;
        if (c < cost[next]) {
          cost[next] = c;
          before[next] = here;
        }
      }
    }
    if (before[toIndex] < 0) return [to];

    final way = <Offset>[];
    for (var i = toIndex; i >= 0; i = before[i]) {
      way.add(points[i]);
    }
    final out = <Offset>[];
    var at = from;
    for (final point in [...way.reversed, to]) {
      if ((point - at).distance > 0.5) out.add(at = point);
    }
    return out;
  }
}

class _ScenarioCityMapState extends State<ScenarioCityMap>
    with SingleTickerProviderStateMixin {
  static const double _petSize = 124;

  /// Map units a second. Quick enough that a walk across the whole town is
  /// over in about three seconds; the card is usable the whole way.
  static const double _walkSpeed = 440;

  /// The grass at the town artwork's edges.
  static const Color _mapEdge = Color(0xFF93c66a);

  /// Distance per hop, and how high one goes.
  static const double _stride = 38;
  static const double _hopHeight = 10;

  final CityLayout _layout = CityLayout(ScenarioCatalog.all.length);
  final TransformationController _view = TransformationController();
  late final Ticker _walker = createTicker(_tick);
  bool _viewPlaced = false;

  late Offset _feet = _layout.start;
  List<Offset> _route = const [];
  Duration _lastTick = Duration.zero;
  double _walked = 0;
  bool _facingLeft = false;
  bool _arrivalFacesLeft = false;

  late final String _petType;

  /// Built once: a frame of the walk moves these, it never rebuilds a rig.
  late final Widget _petSprite = CharacterSprite(
    width: double.infinity,
    height: double.infinity,
    groundShadow: true,
    // Awake whatever its mood at home, in its own coat and outfit — the same
    // treatment the pet gets in a boss trial.
    previewType: _petType,
  );

  /// Built once, like the pet: the buildings are redrawn for chrome whenever
  /// the camera moves, and must not be re-read each time.
  late final List<Widget> _buildingArt = [
    for (var i = 0; i < ScenarioCatalog.all.length; i++)
      SvgPicture.asset(_layout.artAsset(i), fit: BoxFit.fill),
  ];
  late final Widget _schoolArt =
      SvgPicture.asset(_layout.schoolArt, fit: BoxFit.fill);

  @override
  void initState() {
    super.initState();
    _petType = context.read<CharacterProvider>().currentCharacterType;
  }

  @override
  void didUpdateWidget(covariant ScenarioCityMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.selectedId;
    if (id == null || id == oldWidget.selectedId) return;
    if (id == CityLayout.schoolId) {
      _walkTo(_layout.schoolDoorSpot, CityLayout.schoolIsLeft);
      return;
    }
    final index = ScenarioCatalog.all.indexWhere((s) => s.id == id);
    if (index >= 0) {
      _walkTo(_layout.doorSpot(index), CityLayout.isLeftLot(index));
    }
  }

  @override
  void dispose() {
    _walker.dispose();
    _view.dispose();
    super.dispose();
  }

  void _walkTo(Offset target, bool leftOfFootpath) {
    // It stops facing the way it came in along the paving: away from the
    // footpath, toward the door.
    _arrivalFacesLeft = leftOfFootpath;

    if (MediaQuery.disableAnimationsOf(context)) {
      _walker.stop();
      setState(() {
        _feet = target;
        _route = const [];
        _walked = 0;
        _facingLeft = _arrivalFacesLeft;
      });
      return;
    }

    _route = _layout.route(_feet, target);
    if (!_walker.isActive) {
      _lastTick = Duration.zero;
      _walker.start();
    }
  }

  void _tick(Duration elapsed) {
    // Capped, so a dropped frame skips ahead rather than teleporting.
    final dt = math.min(0.05, (elapsed - _lastTick).inMicroseconds / 1e6);
    _lastTick = elapsed;

    var step = _walkSpeed * dt;
    var feet = _feet;
    final route = List<Offset>.of(_route);
    while (step > 0 && route.isNotEmpty) {
      final leg = route.first - feet;
      final length = leg.distance;
      if (leg.dx.abs() > 0.5) _facingLeft = leg.dx < 0;
      if (length <= step) {
        feet = route.removeAt(0);
        step -= length;
        _walked += length;
      } else {
        feet += leg / length * step;
        _walked += step;
        step = 0;
      }
    }

    setState(() {
      _feet = feet;
      _route = route;
      if (route.isEmpty) {
        _walker.stop();
        _walked = 0;
        _facingLeft = _arrivalFacesLeft;
      }
    });
  }

  /// How far the walking pet is off the ground: a hop per stride, snapped to
  /// three heights so it steps like the rest of the pixel motion instead of
  /// gliding.
  double get _hop {
    if (_route.isEmpty) return 0;
    final arc = math.sin(_walked / _stride * math.pi).abs();
    return (arc * 3).round() / 3 * _hopHeight;
  }

  /// The camera the map opens with: the player's pet low and centred.
  Matrix4 _initialView(Size viewport, double scale) {
    final world = _layout.world;
    final focus = _layout.start;
    final tx = math.max(viewport.width - world.width * scale,
        math.min(0.0, viewport.width / 2 - focus.dx * scale));
    final slack = viewport.height - world.height * scale;
    final ty = slack >= 0
        ? slack / 2
        : math.max(
            slack, math.min(0.0, viewport.height * 0.62 - focus.dy * scale));
    return Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(tx, ty, 0);
  }

  Widget _pet({
    required Offset feet,
    required Widget sprite,
    required bool facingLeft,
    double lift = 0,
  }) {
    return Positioned(
      left: feet.dx - _petSize / 2,
      top: feet.dy - _petSize - lift,
      width: _petSize,
      height: _petSize,
      child: Transform.flip(flipX: facingLeft, child: sprite),
    );
  }

  @override
  Widget build(BuildContext context) {
    const scenarios = ScenarioCatalog.all;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final world = _layout.world;
        // The town is drawn to be read across, so fit its width and let it
        // scroll down — unless the screen is taller than that makes the town,
        // when it is fitted to the height instead and scrolls across. Either
        // way it covers the whole viewport and never zooms out past that, so
        // there is no edge of the map to see.
        final minScale = math.max(
            viewport.width / world.width, viewport.height / world.height);
        if (!_viewPlaced) {
          _viewPlaced = true;
          _view.value = _initialView(viewport, minScale);
        }

        return ColoredBox(
          // Never seen while the map covers the viewport; the grass the
          // town's own edges are, behind it, for the frame it is first laid
          // out in.
          color: _mapEdge,
          child: InteractiveViewer(
            transformationController: _view,
            constrained: false,
            minScale: minScale,
            maxScale: minScale * 2,
            boundaryMargin: EdgeInsets.zero,
            child: SizedBox.fromSize(
              size: world,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => widget.onSelect(null),
                      child: SvgPicture.asset(
                        CityLayout.groundAsset,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  for (var i = 0; i < scenarios.length; i++)
                    Positioned.fromRect(
                      rect: _layout.lot(i),
                      child: CityBuilding(
                        scenario: scenarios[i],
                        art: _buildingArt[i],
                        onTap: () => widget.onSelect(scenarios[i].id),
                      ),
                    ),
                  Positioned.fromRect(
                    rect: _layout.schoolLot,
                    child: CityBuilding(
                      art: _schoolArt,
                      onTap: () => widget.onSelect(CityLayout.schoolId),
                    ),
                  ),
                  _pet(
                    feet: _feet,
                    sprite: _petSprite,
                    facingLeft: _facingLeft,
                    lift: _hop,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One place on the map: the building itself and the tap target over it. Its
/// name is not drawn on the map; it is on the card that opens when the place is
/// picked.
class CityBuilding extends StatelessWidget {
  const CityBuilding({
    super.key,
    this.scenario,
    required this.onTap,
    this.art,
  });

  /// The scenario this is the place of; null for the school, which has no
  /// scenario to have cleared.
  final ScenarioDefinition? scenario;
  final VoidCallback onTap;

  /// The building's picture, filling the box. Passed in so a caller that
  /// rebuilds this as the camera moves can keep one instance of it.
  final Widget? art;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: art == null ? const SizedBox.expand() : art!,
    );
  }
}

/// "2/3", or a CLEARED stamp — the same rule the old scenario grid used.
class ScenarioProgressChip extends StatelessWidget {
  const ScenarioProgressChip({super.key, required this.scenario});

  final ScenarioDefinition scenario;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final progress = context.watch<ScenarioProvider>();
    final done = progress.clearedRequiredCount(scenario);
    final everCleared = progress.hasEverCompleted(scenario.id);
    // A cleared scenario keeps showing its in-progress count once replayed,
    // so the stamp and the tally are both useful.
    final stamped = everCleared && done == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: everCleared ? AppTheme.retroGrass : Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 2),
      ),
      child: Text(
        stamped
            ? l10n.scenarioCleared.toUpperCase()
            : l10n.scenarioProgress(done, scenario.requiredCount),
        textDirection: stamped ? textDirection : TextDirection.ltr,
        textAlign: TextAlign.center,
        style: AppFonts.pressStart2p(
          fontSize: 7,
          color: AppTheme.retroDark,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
