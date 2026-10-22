import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../constants/bond.dart';
import '../l10n/app_localizations.dart';
import '../providers/user_provider.dart';
import 'bond_progress.dart';

/// Resolves the pet's bond stage from the XP the player has earned.
///
/// Exists so the lookup has one home: the bond meter and the wardrobe both
/// need the stage, and two lookups would eventually disagree.
BondStatus bondStatusOf(BuildContext context, {bool listen = true}) {
  final user = listen
      ? context.watch<UserProvider>()
      : context.read<UserProvider>();
  return BondProgress.statusFor(totalXP: user.totalXP);
}

/// The stage alone, for callers that only need to know what is unlocked.
PetStage petStageOf(BuildContext context, {bool listen = true}) =>
    bondStatusOf(context, listen: listen).stage;

/// The player-facing name of a stage.
///
/// Shared because the bond meter and the wardrobe both name stages, and a
/// stage called one thing on the home screen and another on the shelf that
/// unlocks at it would read as two different systems.
String petStageName(AppLocalizations? l10n, PetStage stage) {
  switch (stage) {
    case PetStage.curious:
      return l10n?.bondStageCurious ?? 'Curious';
    case PetStage.friendly:
      return l10n?.bondStageFriendly ?? 'Friendly';
    case PetStage.attached:
      return l10n?.bondStageAttached ?? 'Attached';
    case PetStage.devoted:
      return l10n?.bondStageDevoted ?? 'Devoted';
    case PetStage.inseparable:
      return l10n?.bondStageInseparable ?? 'Inseparable';
  }
}
