import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../components/accessory_icon.dart';
import '../components/character_sprite.dart';
import '../components/scene_thumbnail.dart';
import '../constants/accessories.dart';
import '../constants/app_runtime_config.dart';
import '../constants/scenes.dart';
import '../constants/season_pass.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/character_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import '../utils/season_pass_progress.dart';
import 'wardrobe_screen.dart' show accessoryName, sceneName;

/// The season pass, drawn as a track rather than as an offer.
///
/// The page leads with what is owed and what is waiting, not with a price,
/// because the thing being sold is a month of studying with something at the
/// end of it. The two promises that separate this from a battle pass —
/// progress measured from the purchase, and nothing ever expiring — are stated
/// on the page rather than left in `SEASON_PASS.md`, since they are the whole
/// reason a player who has been away is not being punished.
///
/// The track is a card carousel rather than a list, borrowed from
/// `level_rewards_screen.dart`, and for the same reason: what is being sold
/// here is a *picture*, and a 40px thumbnail in a row cannot sell one. A card
/// per rung gives each piece room to be looked at, opens on wherever the
/// player actually is, and leaves space for the button the list had nowhere to
/// put — [_FittingRoom], which puts the piece on the player's own pet before
/// they have earned it. Wanting the thing is the whole mechanic; a hat you
/// have only seen as an icon is not something anyone wants.
/// The pass on its own page, for the routes that arrive from outside the shop
/// — the profile tile, and anything that links straight to `/pass`.
///
/// A frame and nothing else: everything the page actually shows is
/// [SeasonPassBody], because the shop's slider shows the same thing without a
/// Scaffold or a back arrow of its own. Two widgets rather than a `bool`
/// parameter so neither caller can accidentally get the other's chrome.
class SeasonPassScreen extends StatelessWidget {
  const SeasonPassScreen({super.key, this.passId});

  /// Which pass to show, or null for season one, the one on sale. The wardrobe
  /// passes the id of the pass that carries a world the player is looking at,
  /// which is not always the one on sale.
  final String? passId;

  @override
  Widget build(BuildContext context) {
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: _RetroIconButton(
          icon: Icons.arrow_back,
          onPressed: () => context.pop(),
        ),
        title: Text(
          // The pass's own name, verbatim. The level track shouts its title
          // because "LEVELS" is a label; this one is a proper noun, and
          // upper-casing a name is a thing that goes wrong in some scripts.
          seasonPassById(passId ?? kSeasonOneId)?.name ?? '',
          textDirection: textDirection,
          textAlign: TextAlign.center,
          style: fontFunction(
            fontSize: 12,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SeasonPassBody(passId: passId),
    );
  }
}

/// The pass itself: what is owed, what is waiting, and the one thing to do
/// next. Carries no chrome, so the shop's slider can show it under the tabs.
class SeasonPassBody extends StatefulWidget {
  const SeasonPassBody({super.key, this.passId});

  /// Which pass to show, or null for season one. See [SeasonPassScreen.passId].
  final String? passId;

  @override
  State<SeasonPassBody> createState() => _SeasonPassBodyState();
}

class _SeasonPassBodyState extends State<SeasonPassBody> {
  bool _claiming = false;
  PageController? _track;
  int _page = 0;

  @override
  void dispose() {
    _track?.dispose();
    super.dispose();
  }

  /// The carousel, opened on the rung the player is working towards.
  ///
  /// Built once, on the first frame that knows where the player is, rather
  /// than in `initState` — the progress it needs comes from a provider. Later
  /// progress must not move the page under a player who has scrolled away, so
  /// the controller is created once and then left alone.
  PageController _controllerFor(PassProgress? progress, int tierCount) {
    final existing = _track;
    if (existing != null) return existing;
    final reached = progress?.reachedTierIndex ?? -1;
    final opensOn = (reached + 1).clamp(0, tierCount - 1);
    _page = opensOn;
    return _track = PageController(
      viewportFraction: 0.78,
      initialPage: opensOn,
    );
  }

  Future<void> _claim(SeasonPassDef pass, AppLocalizations? l10n) async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final claimed = await context.read<UserProvider>().claimPassTiers(pass.id);
    if (!mounted) return;
    setState(() => _claiming = false);
    if (claimed.isEmpty) return;

    // A world among the rungs goes up straight away, the way a bought one
    // does. Done here rather than in `claimPassTiers` because moving the pet
    // is the character provider's to do, and the claim is the only moment it
    // is the right thing to do — see [CharacterProvider.grantScene].
    final character = context.read<CharacterProvider>();
    for (final index in claimed) {
      final sceneId = pass.tiers[index].sceneId;
      if (sceneId != null) character.grantScene(sceneId);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l10n?.seasonPassClaimedToast(claimed.length) ??
          'Claimed: ${claimed.length}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textDirection =
        textDirectionForLocale(Localizations.localeOf(context));
    final fontFunction =
        AppFonts.getFont(context.watch<SettingsProvider>().usePixelFont);
    final user = context.watch<UserProvider>();
    final store = context.watch<PremiumProvider>();

    // No id means the on-sale pass, which is season one until a second one
    // has a store listing.
    final pass = seasonPassById(widget.passId ?? kSeasonOneId);
    if (pass == null) {
      return const SizedBox.shrink();
    }

    final progress = _progressFor(user, pass);
    final owned = user.ownsPass(pass.id);
    final controller = _controllerFor(progress, pass.tiers.length);

    return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Summary(
                      pass: pass,
                      progress: progress,
                      l10n: l10n,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                    ),
                    const SizedBox(height: 12),
                    // The track takes the room that is left, down to a floor: a
                    // card squeezed below about this is all frame and no picture,
                    // which defeats the point of showing the piece at all. Below
                    // the floor the page scrolls rather than crushing the cards.
                    SizedBox(
                      height: (constraints.maxHeight - 300).clamp(300.0, 470.0),
                      child: PageView.builder(
                        controller: controller,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: pass.tiers.length,
                        itemBuilder: (context, index) => _TierCard(
                          index: index,
                          tier: pass.tiers[index],
                          progress: progress,
                          controller: controller,
                          page: _page,
                          l10n: l10n,
                          fontFunction: fontFunction,
                          textDirection: textDirection,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TrackPips(
                      count: pass.tiers.length,
                      page: _page,
                      reached: progress?.reachedTierIndex ?? -1,
                    ),
                    const SizedBox(height: 12),
                    _action(
                      pass: pass,
                      progress: progress,
                      owned: owned,
                      store: store,
                      l10n: l10n,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n?.seasonPassPromise ??
                          'Tiers are owed XP you earn after buying the pass, so '
                              'buying it late costs you nothing. Nothing here '
                              'expires: a tier you have reached stays reached, and '
                              'one you have not stays waiting.',
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
                      style: fontFunction(
                        fontSize: 6,
                        height: 1.8,
                        color: AppTheme.retroDark.withValues(alpha: 0.75),
                      ),
                    ),
                    if (AppRuntimeConfig.seasonPassXpOverride >= 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Debug: showing ${AppRuntimeConfig.seasonPassXpOverride} XP '
                        'of progress. Nothing is owned and nothing is saved.',
                        textDirection: textDirection,
                        textAlign: TextAlign.center,
                        style: fontFunction(
                          fontSize: 6,
                          height: 1.6,
                          color: AppTheme.retroPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
  }

  /// The one thing to do next: claim what is owed, or buy in, or an honest
  /// statement of why neither is on offer.
  Widget _action({
    required SeasonPassDef pass,
    required PassProgress? progress,
    required bool owned,
    required PremiumProvider store,
    required AppLocalizations? l10n,
    required _PassFontFn fontFunction,
    required TextDirection textDirection,
  }) {
    if (progress != null && progress.hasClaimable) {
      return _Button(
        label: _claiming
            ? (l10n?.seasonPassClaiming ?? 'Claiming…')
            : (l10n?.seasonPassClaim(progress.claimableTierIndexes.length) ??
                'Claim (${progress.claimableTierIndexes.length})'),
        onTap: _claiming ? null : () => _claim(pass, l10n),
        fontFunction: fontFunction,
        textDirection: textDirection,
      );
    }
    if (owned) return const SizedBox.shrink();
    if (store.isPurchasePending) {
      return _Notice(
        label: l10n?.premiumPurchasePending ?? 'Finishing with the store…',
        fontFunction: fontFunction,
        textDirection: textDirection,
      );
    }
    if (store.isPassAvailable(pass.id)) {
      return _Button(
        // The store's own formatted price, never one built here: it carries
        // the player's currency and their region's tax rules, and a number
        // assembled locally would be wrong somewhere.
        label: l10n?.seasonPassBuy(store.passProduct(pass.id)!.price) ??
            'Buy ${store.passProduct(pass.id)!.price}',
        onTap: () => store.buyPass(pass.id),
        fontFunction: fontFunction,
        textDirection: textDirection,
      );
    }
    // No listing, so no price is drawn. A live-looking dead button is worse
    // than an honest gap — the same call the paywall makes when the store will
    // not talk to it.
    return _Notice(
      label: l10n?.seasonPassNotOnSale ?? 'This pass is not on sale yet.',
      fontFunction: fontFunction,
      textDirection: textDirection,
    );
  }

  /// Where the player is, or a pretend position under the debug override.
  ///
  /// The override builds a [PassProgress] rather than granting anything, so a
  /// dev run cannot leave a purchase record behind — see
  /// [AppRuntimeConfig.seasonPassXpOverride].
  PassProgress? _progressFor(UserProvider user, SeasonPassDef pass) {
    final real = user.passProgress(pass.id);
    if (real != null) return real;

    final fake = AppRuntimeConfig.seasonPassXpOverride;
    if (fake < 0) return null;
    return PassProgress(
      pass: pass,
      owned: OwnedPass(passId: pass.id, xpAtPurchase: 0),
      xpSincePurchase: fake,
    );
  }
}

/// The one-line answer to "how far along am I", above the track.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.pass,
    required this.progress,
    required this.l10n,
    required this.fontFunction,
    required this.textDirection,
  });

  final SeasonPassDef pass;
  final PassProgress? progress;
  final AppLocalizations? l10n;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final reached = p == null ? 0 : p.reachedTierIndex + 1;

    final headline = Text(
      p == null
          ? (l10n?.seasonPassTrackLength(
                  pass.tiers.length, pass.xpToComplete) ??
              '${pass.tiers.length} pieces · ${pass.xpToComplete} XP')
          : (l10n?.seasonPassTierOf(reached, pass.tiers.length) ??
              'Tier $reached / ${pass.tiers.length}'),
      textDirection: textDirection,
      style: fontFunction(
        fontSize: 10,
        color: AppTheme.retroDark,
        fontWeight: FontWeight.bold,
      ),
    );

    final backlog = p != null && p.hasClaimable
        ? _Chip(
            label:
                l10n?.seasonPassWaitingToClaim(p.claimableTierIndexes.length) ??
                    'Waiting to claim: ${p.claimableTierIndexes.length}',
            background: AppTheme.retroAccent,
            foreground: AppTheme.retroDark,
            fontFunction: fontFunction,
            textDirection: textDirection,
          )
        : null;

    return _RetroPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Side by side where they fit, stacked where they do not. The
          // backlog tag is a whole sentence in several languages and the
          // headline is a different length in each of them, so which of those
          // happens is measured rather than guessed at from a screen width.
          if (backlog == null)
            headline
          else
            LayoutBuilder(
              builder: (context, constraints) => Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  headline,
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: backlog,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 10),
          // The bar crosses the CURRENT rung rather than the whole track, so
          // it moves every session instead of once a fortnight — the same call
          // the bond meter makes.
          _RetroBar(value: p?.tierProgress ?? 0),
          // Nothing under the bar until the pass is owned. What used to sit
          // here described what the pass does not contain, which is a strange
          // thing to lead with on the one line a player reads before deciding.
          if (p != null) ...[
            const SizedBox(height: 9),
            Text(
              p.isComplete
                  ? (l10n?.seasonPassComplete ?? 'Track complete.')
                  : (l10n?.seasonPassXpToNext(p.xpToNextTier) ??
                      '${p.xpToNextTier} XP to the next piece'),
              textDirection: textDirection,
              style: fontFunction(
                fontSize: 8,
                height: 1.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One rung, as a card: what the piece looks like, what it costs, and a way to
/// see it on your own pet before you have it.
class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.index,
    required this.tier,
    required this.progress,
    required this.controller,
    required this.page,
    required this.l10n,
    required this.fontFunction,
    required this.textDirection,
  });

  final int index;
  final SeasonPassTier tier;
  final PassProgress? progress;
  final PageController controller;
  final int page;
  final AppLocalizations? l10n;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    final accessory =
        tier.accessoryId == null ? null : accessoryById(tier.accessoryId!);
    final scene = tier.sceneId == null ? null : sceneThemeById(tier.sceneId!);
    final p = progress;
    final claimed = p != null && p.owned.claimedThroughTier >= index;
    final reached = p != null && p.reachedTierIndex >= index;
    final claimable = reached && !claimed;

    // Greyed means "you own the pass and have not got this far yet". Someone
    // who has not bought in has not fallen behind on anything, and a whole
    // carousel of grey is a poor way to show them what is in the box — so
    // before the purchase every card is lit and only the chips say locked.
    final lit = reached || p == null;

    final String title;
    if (scene != null) {
      title = l10n == null ? scene.name : sceneName(l10n!, scene);
    } else if (accessory != null) {
      title = l10n == null ? accessory.name : accessoryName(l10n!, accessory);
    } else {
      title = tier.itemId;
    }

    // The card off to the side sits back, so the eye lands on the one in the
    // middle. Lifted from the level track, which does the same.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        var scale = index == page ? 1.0 : 0.9;
        if (controller.hasClients && controller.position.haveDimensions) {
          final delta = (controller.page ?? page.toDouble()) - index;
          scale = (1 - delta.abs() * 0.11).clamp(0.86, 1.0);
        }
        return Center(child: Transform.scale(scale: scale, child: child));
      },
      child: ConstrainedBox(
        // Capped, because past about this height the display case is mostly
        // empty and the piece inside it stops being the subject of the card.
        constraints: const BoxConstraints(maxHeight: 470),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: _RetroPanel(
            background: lit ? Colors.white : const Color(0xFFE4E0DA),
            borderColor:
                claimable ? AppTheme.retroGrassDark : AppTheme.retroDark,
            borderWidth: 5,
            shadowOffset: const Offset(6, 6),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _TierNumber(index: index, fontFunction: fontFunction),
                    const Spacer(),
                    _Chip(
                      label: claimed
                          ? (l10n?.seasonPassTierClaimed ?? 'Claimed')
                          : claimable
                              ? (l10n?.seasonPassReady ?? 'Ready')
                              : (l10n?.locked ?? 'Locked'),
                      background: claimed
                          ? AppTheme.retroDark
                          : claimable
                              ? AppTheme.retroGrass
                              : Colors.white,
                      foreground:
                          reached ? Colors.white : AppTheme.textSecondary,
                      fontFunction: fontFunction,
                      textDirection: textDirection,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // The piece itself, given the whole middle of the card. An
                // unreached one is dimmed rather than hidden: a track you cannot
                // see is a track with nothing to work towards.
                Expanded(
                  // A square case rather than whatever height is left over.
                  // The accessory drawings sit on the pet's own tall canvas,
                  // so a full-height window is mostly the empty air above a
                  // hat.
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _PieceWindow(
                        accessory: accessory,
                        scene: scene,
                        dimmed: !lit,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: fontFunction(
                    fontSize: 9,
                    height: 1.4,
                    color: AppTheme.retroDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n?.seasonPassTierCost(tier.xpFromPurchase) ??
                      '${tier.xpFromPurchase} XP',
                  textDirection: textDirection,
                  textAlign: TextAlign.center,
                  style: fontFunction(
                    fontSize: 7,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                if (accessory != null || scene != null)
                  _TryOnButton(
                    accessory: accessory,
                    scene: scene,
                    label: l10n?.seasonPassTryOn ?? 'Try it on',
                    owned: claimed,
                    fontFunction: fontFunction,
                    textDirection: textDirection,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The rung's number, in the square box the level track uses.
class _TierNumber extends StatelessWidget {
  const _TierNumber({required this.index, required this.fontFunction});

  final int index;
  final _PassFontFn fontFunction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: AppTheme.retroLight,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.retroDark, offset: Offset(3, 3)),
        ],
      ),
      child: Center(
        child: Text(
          '${index + 1}',
          // Always the Western digit sequence, like the level track: this is
          // an index into a list, not a quantity being read aloud.
          textDirection: TextDirection.ltr,
          style: fontFunction(
            fontSize: 14,
            color: AppTheme.retroDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// The display case the tier's art sits in — an accessory, or a world.
///
/// A scene fills the case rather than sitting inside its padding: it is a
/// place, and a picture of a place with a border of wall around it reads as a
/// postcard of one.
class _PieceWindow extends StatelessWidget {
  const _PieceWindow({
    required this.accessory,
    required this.scene,
    required this.dimmed,
  });

  final AccessoryDef? accessory;
  final SceneTheme? scene;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final world = scene;
    return Container(
      width: double.infinity,
      padding: world == null ? const EdgeInsets.all(10) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: dimmed ? AppTheme.retroLight : AppTheme.retroSkyLight,
        border: Border.all(color: AppTheme.retroDark, width: 3),
      ),
      child: Opacity(
        opacity: dimmed ? 0.55 : 1,
        child: world != null
            ? LayoutBuilder(
                builder: (context, constraints) => SceneThumbnail(
                  scene: world,
                  size: constraints.maxWidth,
                ),
              )
            : accessory == null
                ? const SizedBox.shrink()
                : AccessoryIcon(accessory: accessory!),
      ),
    );
  }
}

/// Opens the fitting room for one tier — a piece, or a world.
class _TryOnButton extends StatelessWidget {
  const _TryOnButton({
    required this.accessory,
    required this.scene,
    required this.label,
    required this.owned,
    required this.fontFunction,
    required this.textDirection,
  });

  final AccessoryDef? accessory;
  final SceneTheme? scene;
  final String label;
  final bool owned;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        barrierColor: AppTheme.retroDark.withValues(alpha: 0.72),
        // The providers sit above MaterialApp (see `main.dart`), so the
        // dialog's own route can read them.
        builder: (_) => _FittingRoom(
          accessory: accessory,
          scene: scene,
          owned: owned,
          fontFunction: fontFunction,
          textDirection: textDirection,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: AppTheme.retroAccent,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.retroDark, offset: Offset(3, 3)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.visibility, size: 14, color: AppTheme.retroDark),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label.toUpperCase(),
                textDirection: textDirection,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: fontFunction(
                  fontSize: 8,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tier on the player's own pet, before they own it.
///
/// For a piece, the pet is drawn wearing whatever it already has on plus this
/// one thing in its slot, which is the only honest answer to "how will this
/// look" — a hat shown alone tells you nothing about a pet that is already
/// wearing goggles. For a world, the pet is drawn standing in it, dressed as
/// it is now, for the same reason: a scene shown empty is a swatch.
///
/// Nothing here is saved: [CharacterSprite.previewAccessories] draws a set
/// without touching the design, and the backdrop is a [SceneThumbnail] rather
/// than the equipped scene — so backing out leaves the pet exactly as it was
/// found, in the world it was found in.
class _FittingRoom extends StatelessWidget {
  const _FittingRoom({
    required this.accessory,
    required this.scene,
    required this.owned,
    required this.fontFunction,
    required this.textDirection,
  });

  final AccessoryDef? accessory;
  final SceneTheme? scene;
  final bool owned;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  /// What the pet wears in the preview: everything it has on now except
  /// whatever occupies this piece's slot, plus this piece. A world changes
  /// nothing about the outfit, so the pet keeps exactly what it is wearing.
  List<AccessoryDef> _outfit(CharacterProvider provider) {
    var worn = const <AccessoryDef>[];
    try {
      worn = provider.equippedAccessoriesFor(provider.currentCharacterType);
    } catch (_) {
      // A pet whose design has not loaded wears the piece on its own, which
      // is still the answer to the question being asked.
    }
    final piece = accessory;
    if (piece == null) return worn;
    return [
      for (final def in worn)
        if (def.slot != piece.slot) def,
      piece,
    ];
  }

  String _title(AppLocalizations? l10n) {
    final world = scene;
    if (world != null) {
      return l10n == null ? world.name : sceneName(l10n, world);
    }
    final piece = accessory;
    if (piece == null) return '';
    return l10n == null ? piece.name : accessoryName(l10n, piece);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<CharacterProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: _RetroPanel(
        background: AppTheme.retroDark,
        borderWidth: 5,
        shadowOffset: const Offset(6, 6),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(l10n).toUpperCase(),
                    textDirection: textDirection,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: fontFunction(
                      fontSize: 9,
                      height: 1.4,
                      color: AppTheme.retroLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.retroLight,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                    ),
                    child: const Icon(Icons.close,
                        size: 16, color: AppTheme.retroDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // The wardrobe's mirror, borrowed: the same inset frame the closet
            // shows the pet in, so trying a piece on here and trying one on
            // there are visibly the same act.
            Container(
              padding:
                  scene == null ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: AppTheme.wardrobeInterior,
                border: Border.all(color: AppTheme.retroLight, width: 4),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth.clamp(120.0, 240.0);
                  final world = scene;
                  return Center(
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Stack(
                        children: [
                          // The world behind the pet, inside the same frame
                          // the closet shows a hat in — so looking at a scene
                          // and trying on a piece are visibly the same act.
                          if (world != null)
                            Positioned.fill(
                              child: SceneThumbnail(scene: world, size: size),
                            ),
                          CharacterSprite(
                            width: size,
                            height: size,
                            fit: BoxFit.contain,
                            motionProfile: CharacterMotionProfile.full,
                            previewAccessories: _outfit(provider),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Text(
              !owned
                  ? (l10n?.seasonPassPreviewLocked ??
                      'Not yours yet — this is only a look.')
                  : scene != null
                      ? (l10n?.seasonPassScenePreviewOwned ??
                          'Yours. Change worlds any time in the wardrobe.')
                      : (l10n?.seasonPassPreviewOwned ??
                          'Yours. Put it on in the wardrobe.'),
              textDirection: textDirection,
              textAlign: TextAlign.center,
              style: fontFunction(
                fontSize: 7,
                height: 1.7,
                color: AppTheme.retroLight.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ten pips under the carousel: how long the track is, how much of it is
/// reached, and which rung is being looked at.
class _TrackPips extends StatelessWidget {
  const _TrackPips({
    required this.count,
    required this.page,
    required this.reached,
  });

  final int count;
  final int page;
  final int reached;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == page ? 16 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: i <= reached
                  ? AppTheme.retroGrass
                  : AppTheme.retroLight.withValues(alpha: 0.6),
              border: Border.all(color: AppTheme.retroDark, width: 2),
            ),
          ),
      ],
    );
  }
}

/// The chunky bar the rest of the app draws progress with: a hard border, a
/// hard shadow and a flat fill, rather than a rounded Material one.
class _RetroBar extends StatelessWidget {
  const _RetroBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      decoration: BoxDecoration(
        color: AppTheme.retroLight,
        border: Border.all(color: AppTheme.retroDark, width: 3),
      ),
      child: ClipRect(
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(color: AppTheme.retroGrass),
          ),
        ),
      ),
    );
  }
}

/// A small labelled tag — status on a card, backlog count on the summary.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.fontFunction,
    required this.textDirection,
  });

  final String label;
  final Color background;
  final Color foreground;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: AppTheme.retroDark, width: 3),
      ),
      child: Text(
        label.toUpperCase(),
        textDirection: textDirection,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: fontFunction(
          fontSize: 7,
          height: 1.4,
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The app's card: flat fill, hard border, hard offset shadow.
class _RetroPanel extends StatelessWidget {
  const _RetroPanel({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.background = Colors.white,
    this.borderColor = AppTheme.retroDark,
    this.borderWidth = 3,
    this.shadowOffset = const Offset(4, 4),
  });

  final Widget child;
  final EdgeInsets padding;
  final Color background;
  final Color borderColor;
  final double borderWidth;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppTheme.retroDark,
            offset: shadowOffset,
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Back button with the app's raised-border treatment, as the level track and
/// the wardrobe draw it.
class _RetroIconButton extends StatelessWidget {
  const _RetroIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.retroDark, width: 3),
        boxShadow: const [
          BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.retroDark, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        // No round ink ripple inside the square retro frame.
        style: const ButtonStyle(
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.onTap,
    required this.fontFunction,
    required this.textDirection,
  });

  final String label;
  final VoidCallback? onTap;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: onTap == null ? AppTheme.retroGrassDark : AppTheme.retroGrass,
          border: Border.all(color: AppTheme.retroDark, width: 3),
          boxShadow: const [
            BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4)),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          textDirection: textDirection,
          style: fontFunction(
            fontSize: 10,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.label,
    required this.fontFunction,
    required this.textDirection,
  });

  final String label;
  final _PassFontFn fontFunction;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    return _RetroPanel(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        textAlign: TextAlign.center,
        textDirection: textDirection,
        style: fontFunction(
          fontSize: 8,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

typedef _PassFontFn = TextStyle Function({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? height,
});
