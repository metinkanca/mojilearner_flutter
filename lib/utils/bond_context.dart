import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../constants/bond.dart';
import '../l10n/app_localizations.dart';
import '../providers/calibration_provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import 'bond_progress.dart';

/// Resolves the pet's bond stage from the three providers that each hold a
/// piece of it: the bond points ([CharacterProvider]), the language being
/// learned ([LanguageProvider]) and the assessed level for that language
/// ([CalibrationProvider]).
///
/// Exists so the assembly has one home. Two screens need the stage, and if
/// each did its own lookup they would eventually disagree about what happens
/// when no language is selected or no assessment has been run.
BondStatus bondStatusOf(BuildContext context, {bool listen = true}) {
  final character = listen
      ? context.watch<CharacterProvider>()
      : context.read<CharacterProvider>();
  final calibration = listen
      ? context.watch<CalibrationProvider>()
      : context.read<CalibrationProvider>();
  final language = listen
      ? context.watch<LanguageProvider>()
      : context.read<LanguageProvider>();

  final code = language.targetLanguage?.code;
  final assessedLevel = code == null
      ? null
      : calibration.getLanguageProficiency(code)?.aiDeterminedLevel;

  return character.bondStatusFor(assessedLevel);
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
