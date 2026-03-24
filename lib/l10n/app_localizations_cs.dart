// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get header => 'Nastavení jazyka';

  @override
  String get iSpeak => 'Mluvím';

  @override
  String get imLearning => 'Učím se';

  @override
  String get currentSelection => 'Aktuální výběr:';

  @override
  String get level => 'Úroveň';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Řada';

  @override
  String get audio => 'Hlas bota';

  @override
  String get designMojiBtn => 'Navrhni Moji';

  @override
  String get quizMode => 'Kvíz';

  @override
  String get quizDesc => 'Otestuj své znalosti.';

  @override
  String get scenarios => 'Scénáře';

  @override
  String get scenariosDesc => 'Procvičuj reálné konverzace.';

  @override
  String get profile => 'Profil';

  @override
  String get shop => 'Obchod';

  @override
  String get mistakes => 'CHYBY';

  @override
  String get noMistakesYet => 'ZATÍM ŽÁDNÉ CHYBY!';

  @override
  String get profileDesc => 'Zobrazit statistiky a nastavení.';

  @override
  String get voiceCall => 'Hlasový hovor';

  @override
  String get voiceCallDesc => 'Procvičuj mluvení v reálném čase.';

  @override
  String get practiceRealLife => 'Procvičuj reálný život';

  @override
  String get chooseSituation => 'Vyber situaci';

  @override
  String get createYourOwn => 'Vytvoř vlastní';

  @override
  String get startCustom => 'Spustit vlastní scénář';

  @override
  String get customPlaceholder => 'Např. Jsi taxikář...';

  @override
  String get orderingCoffee => 'Objednání kávy';

  @override
  String get jobInterview => 'Pracovní pohovor';

  @override
  String get askingDirections => 'Ptát se na cestu';

  @override
  String get atTheDoctor => 'U doktora';

  @override
  String get shopping => 'Nakupování';

  @override
  String get restaurant => 'Restaurace';

  @override
  String get chats => 'Chaty';

  @override
  String get searchPlaceholder => 'Hledat zprávy...';

  @override
  String get newChat => 'Nový chat';

  @override
  String get noChats => 'Žádné chaty';

  @override
  String get startNewConversation => 'Začni novou konverzaci';

  @override
  String get blankChat => 'Prázdný chat';

  @override
  String get blankChatDesc => 'Začni bez kontextu';

  @override
  String get roleplayScenario => 'Scénář hraní rolí';

  @override
  String get roleplayScenarioDesc => 'Procvičuj konkrétní situace';

  @override
  String get chooseChatType => 'Vyber typ chatu';

  @override
  String get cancel => 'Zrušit';

  @override
  String get typeMessage => 'Napiš zprávu...';

  @override
  String get designMoji => 'Design Moji';

  @override
  String get fullCustomization => 'Plné přizpůsobení';

  @override
  String get tapToChange => 'Klepni pro změnu';

  @override
  String get mascotColor => 'Barva maskota';

  @override
  String get backgroundColor => 'Barva pozadí';

  @override
  String get faceExpressions => 'Výrazy obličeje';

  @override
  String get personalityFaces => 'Osobnost a Tváře';

  @override
  String get selectFaces => 'Vyber tváře.';

  @override
  String get locked => 'Zamčeno';

  @override
  String unlockMessage(Object level) {
    return 'Dosáhni úrovně $level pro odemčení!';
  }

  @override
  String get yourMistakes => 'Tvé chyby';

  @override
  String get learnFromWrong => 'Uč se z chyb';

  @override
  String get all => 'Vše';

  @override
  String get grammar => 'Gramatika';

  @override
  String get grammarBreakdown => 'Gramatický rozbor';

  @override
  String get close => 'Zavřít';

  @override
  String get noGrammarAnalysis => 'Žádný gramatický rozbor není k dispozici.';

  @override
  String get vocabulary => 'Slovní zásoba';

  @override
  String get noMistakes => 'Nebyly nalezeny žádné chyby!';

  @override
  String get yourAnswer => 'Tvá odpověď';

  @override
  String get correctAnswer => 'Správná odpověď';

  @override
  String get explanation => 'Vysvětlení';

  @override
  String get story => 'Scénáře';

  @override
  String get drills => 'Chyby';

  @override
  String get typeHere => 'Pište zde...';

  @override
  String get shopTitle => 'Shop';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryDecor => 'Decor';

  @override
  String get hideOwnedCosmetics => 'Hide Owned Cosmetics';

  @override
  String get noItems => 'No Items';

  @override
  String get owned => 'Owned';

  @override
  String get alreadyOwned => 'Already Owned';

  @override
  String get alreadyOwnedMessage => 'You already own this item!';

  @override
  String get quantity => 'Quantity';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get notEnoughCoins => 'Not Enough Coins!';

  @override
  String get purchaseFailed => 'Purchase Failed';

  @override
  String get notEnoughCoinsMessage => 'Not enough coins!';

  @override
  String get buy => 'Buy';

  @override
  String get tooPoor => 'Too Poor';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'Daily Reward';

  @override
  String get claim_reward => 'Claim Reward';

  @override
  String day_streak(Object X) {
    return 'Day $X Streak';
  }

  @override
  String get come_back_tomorrow => 'Come back tomorrow!';

  @override
  String get streak_broken => 'Welcome back! Starting fresh';

  @override
  String get keep_going => 'Keep it going!';

  @override
  String get reward_claimed => 'Reward Claimed!';

  @override
  String amazing_streak(Object X) {
    return 'Amazing! Day $X streak!';
  }

  @override
  String get whatsYourName => 'JAK SE JMENUJEŠ?';

  @override
  String get enterYourName => 'Zadejte své jméno';

  @override
  String get continueBtn => 'POKRAČOVAT';

  @override
  String get howWouldYouRate => 'JAK BYSTE HODNOTIL';

  @override
  String get yourLevel => 'SVOU ÚROVEŇ?';

  @override
  String get beginner => 'ZAČÁTEČNÍK';

  @override
  String get intermediate => 'STŘEDNĚ POKROČILÝ';

  @override
  String get advanced => 'POKROČILÝ';

  @override
  String get beginnerDesc => 'Právě začínám. Znám velmi málo slov.';

  @override
  String get intermediateDesc =>
      'Mohu vést základní konverzace a rozumím jednoduchým textům.';

  @override
  String get advancedDesc =>
      'Jsem plynný nebo téměř plynný. Mohu diskutovat o složitých tématech.';

  @override
  String get whichLanguage => 'KTERÝ JAZYK';

  @override
  String get doYouWantToLearn => 'SE CHCEŠ NAUČIT?';

  @override
  String get changeAnytime => 'Můžete to kdykoli změnit v nastavení';

  @override
  String get dontWorryVerify => 'Neboj se, ověříme to rychlým chatem!';

  @override
  String get startAssessment => 'ZAHÁJIT HODNOCENÍ';

  @override
  String get chatAssessment => 'CHAT HODNOCENÍ';

  @override
  String get typeYourAnswer => 'Napiš svou odpověď...';

  @override
  String get mojiIsTyping => 'Moji píše...';

  @override
  String get send => 'ODESLAT';

  @override
  String get calibrationComplete => 'Kalibrace Dokončena!';

  @override
  String get basedOnYourAnswers =>
      'Na základě vašich odpovědí je vaše doporučená počáteční úroveň:';

  @override
  String get proficiencyLevel => 'Úrověň Dovedností';

  @override
  String get shopItemAppleName => 'Jablko';

  @override
  String get shopItemAppleDescription => 'Zdravá svačinka.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Máslová dobrota.';

  @override
  String get shopItemPizzaName => 'Kousek pizzy';

  @override
  String get shopItemPizzaDescription => 'Sýrová a sytá.';

  @override
  String get shopItemSushiName => 'Sada sushi';

  @override
  String get shopItemSushiDescription => 'Prémiová ryba.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Rychlý nárůst energie.';

  @override
  String get shopItemBgBlueName => 'Oceánská modř';

  @override
  String get shopItemBgBlueDescription => 'Uklidňující modré vibrace.';

  @override
  String get shopItemBgForestName => 'Lesní zelená';

  @override
  String get shopItemBgForestDescription => 'Přírodní pocit.';

  @override
  String get shopItemBgSunsetName => 'Západní oranžová';

  @override
  String get shopItemBgSunsetDescription => 'Teplá a pohodlná.';

  @override
  String get shopItemBgGalaxyName => 'Galaxie fialová';

  @override
  String get shopItemBgGalaxyDescription => 'Mimo tento svět.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return 'Zakoupen $itemName!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return 'Zakoupen $itemName x$quantity!';
  }
}
