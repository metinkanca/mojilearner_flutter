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
  String get shopTitle => 'Obchod';

  @override
  String get categoryAll => 'Vše';

  @override
  String get categoryFood => 'Jídlo';

  @override
  String get categoryDecor => 'Dekorace';

  @override
  String get hideOwnedCosmetics => 'Skrýt vlastněné doplňky';

  @override
  String get noItems => 'Žádné předměty';

  @override
  String get owned => 'Vlastněno';

  @override
  String get alreadyOwned => 'Již vlastníš';

  @override
  String get alreadyOwnedMessage => 'Tento předmět už vlastníš!';

  @override
  String get quantity => 'Množství';

  @override
  String get totalPrice => 'Celková cena';

  @override
  String get notEnoughCoins => 'Nedostatek mincí!';

  @override
  String get purchaseFailed => 'Nákup se nezdařil';

  @override
  String get notEnoughCoinsMessage => 'Nemáš dost mincí!';

  @override
  String get buy => 'Koupit';

  @override
  String get tooPoor => 'Málo mincí';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'Denní odměna';

  @override
  String get claim_reward => 'Vyzvednout odměnu';

  @override
  String day_streak(Object X) {
    return 'Série: den $X';
  }

  @override
  String get come_back_tomorrow => 'Vrať se zítra!';

  @override
  String get streak_broken => 'Vítej zpět! Začínáme znovu';

  @override
  String get keep_going => 'Jen tak dál!';

  @override
  String get reward_claimed => 'Odměna vyzvednuta!';

  @override
  String amazing_streak(Object X) {
    return 'Úžasné! Série $X dní!';
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
  String get shopItemMedicineName => 'Lék';

  @override
  String get shopItemMedicineDescription => 'Vyléčí Mojiho.';

  @override
  String get review => 'Opakování';

  @override
  String reviewDueCount(int count) {
    return '$count k opakování';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$current z $total';
  }

  @override
  String get reviewShowAnswer => 'Zobrazit odpověď';

  @override
  String get reviewGradeAgain => 'Znovu';

  @override
  String get reviewGradeHard => 'Těžké';

  @override
  String get reviewGradeGood => 'Dobré';

  @override
  String get reviewGradeEasy => 'Snadné';

  @override
  String get reviewAllCaughtUp => 'Vše hotovo!';

  @override
  String get reviewNothingDue =>
      'Teď není co opakovat. Popovídej si nebo si dej kvíz a Moji si zapamatuje, co ti nejde.';

  @override
  String get reviewSessionComplete => 'Opakování dokončeno!';

  @override
  String reviewSessionSummary(int count) {
    return 'Zopakováno: $count';
  }

  @override
  String get reviewDone => 'Hotovo';

  @override
  String get reviewCorrectionPrompt => 'Jak to má být správně?';

  @override
  String get reviewVocabularyPrompt => 'Co to znamená?';

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

  @override
  String get youLabel => 'Ty';

  @override
  String get mojiSleepReconnect =>
      'Zzz... Moji podřimuje, zatímco se znovu připojuje jazykové spojení. Zkus to brzy znovu.';

  @override
  String get mojiSleepNight => 'Pšš... Moji spí. Klepni na Mojiho a probuď ho.';

  @override
  String get mojiSleepHintReconnect =>
      'MOJI PODŘIMUJE... JAZYKOVÉ SPOJENÍ SE OBNOVUJE';

  @override
  String get mojiSleepHintNight => 'MOJI SPÍ... KLEPNI PRO PROBUZENÍ';

  @override
  String get mojiWakeSuccess => 'Zív... Moji je teď vzhůru! Pojďme trénovat!';

  @override
  String mojiAwakeFor(int minutes) {
    return 'Vzhůru ještě $minutes min';
  }

  @override
  String get mojiSleepReasonReconnect =>
      'Moji podřimuje, zatímco se jazykové spojení obnovuje.';

  @override
  String get mojiSleepReasonNight => 'Moji spí. Klepni pro probuzení.';

  @override
  String get levelsScreenTitle => 'Úrovně';

  @override
  String get levelStatusCurrent => 'Aktuální úroveň';

  @override
  String get levelStatusCompleted => 'Dokončeno';

  @override
  String get levelRewardLabel => 'Odměna';

  @override
  String get quizPausedTitle => 'Pozastaveno';

  @override
  String get quizPausedPrompt => 'Chcete pokračovat nebo skončit?';

  @override
  String get quizPlay => 'Hrát';

  @override
  String get quizPause => 'Pozastavit';

  @override
  String get quizExit => 'Ukončit';

  @override
  String get weeklyProgressTitle => 'Týdenní pokrok';

  @override
  String dayLabel(int dayNum) {
    return 'Den $dayNum';
  }

  @override
  String get dailyRewardHint => 'Vraťte se zítra na denní odměnu';

  @override
  String get resetAppButton => 'Obnovit';

  @override
  String get resetAppTitle => 'Obnovit aplikaci';

  @override
  String get resetAppWarning =>
      'Odstraní veškerý váš pokrok.\n\nJste si jisti?';

  @override
  String get resetAction => 'Obnovit';

  @override
  String get resetSuccessMessage => 'Aplikace byla úspěšně obnovena';

  @override
  String get selectYourCharacter => 'Vyberte si svou postavu';

  @override
  String get characterDog => 'Pes';

  @override
  String get characterCat => 'Kočka';

  @override
  String get characterBird => 'Pták';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Moji podřimuje, dokud se jazykové spojení neobnoví. Zkus to brzy znovu.';

  @override
  String get mojiDozingReconnect =>
      'Moji podřimuje, dokud se jazykové spojení neobnoví.';

  @override
  String get mojiSleepingTapWake => 'Moji spí. Klepnutím ho probudíš.';

  @override
  String get mojiAwakeReady => 'Moji je vzhůru a připraven!';

  @override
  String get wardrobeTitle => 'Šatník';

  @override
  String get slotHat => 'Klobouk';

  @override
  String get slotNeck => 'Krk';

  @override
  String get slotFace => 'Obličej';

  @override
  String get bodyTailColor => 'Barva těla a ocasu';

  @override
  String get eyeColor => 'Barva očí';

  @override
  String get eyeStyleSolid => 'Jednobarevné';

  @override
  String get eyeStyleOddEyed => 'Různobarevné';

  @override
  String get leftEye => 'Levé oko';

  @override
  String get rightEye => 'Pravé oko';

  @override
  String get colorLabel => 'Barva';

  @override
  String get scenarioObjectives => 'Cíle';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'Splněno';

  @override
  String get scenarioBonusLabel => 'Bonus';

  @override
  String get scenarioCompleteTitle => 'Scénář dokončen!';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '$done z $total cílů';
  }

  @override
  String get scenarioFirstClear => 'Poprvé splněno!';

  @override
  String get scenarioReplayNote =>
      'Odměna za opakování — poprvé je odměna vyšší.';

  @override
  String get scenarioContinue => 'Pokračovat';

  @override
  String get objCoffeeOrder => 'Objednej si nápoj';

  @override
  String get objCoffeeCustomize => 'Uprav si objednávku';

  @override
  String get objCoffeePrice => 'Zjisti, kolik to stojí';

  @override
  String get objCoffeeSmallTalk => 'Prohoď pár slov s baristou';

  @override
  String get objInterviewGreet => 'Představ se';

  @override
  String get objInterviewExperience => 'Popiš své zkušenosti';

  @override
  String get objInterviewStrength => 'Vysvětli, proč se hodíš';

  @override
  String get objInterviewAsk => 'Zeptej se na tu pozici';

  @override
  String get objDirectionsAsk => 'Zjisti, jak se někam dostat';

  @override
  String get objDirectionsClarify => 'Popros o zopakování nebo zpomalení';

  @override
  String get objDirectionsDistance => 'Zjisti, jak je to daleko';

  @override
  String get objDirectionsThank => 'Slušně poděkuj';

  @override
  String get objDoctorSymptom => 'Popiš své potíže';

  @override
  String get objDoctorDuration => 'Řekni, jak dlouho to trvá';

  @override
  String get objDoctorQuestion => 'Zeptej se, co máš dělat';

  @override
  String get objDoctorAllergy => 'Zmiň alergii nebo léky';

  @override
  String get objShoppingFind => 'Zeptej se, kde něco najdeš';

  @override
  String get objShoppingSize => 'Zeptej se na velikost, barvu nebo střih';

  @override
  String get objShoppingPrice => 'Zeptej se na cenu';

  @override
  String get objShoppingPay => 'Zaplať za to';

  @override
  String get objRestaurantTable => 'Popros o stůl';

  @override
  String get objRestaurantOrder => 'Objednej si jídlo';

  @override
  String get objRestaurantDrink => 'Objednej si něco k pití';

  @override
  String get objRestaurantBill => 'Popros o účet';

  @override
  String get notificationsTitle => 'Oznámení';

  @override
  String get notificationsEnable => 'Připomínej mi Mojiho';

  @override
  String get notificationsDesc =>
      'Moji ti dá vědět, když tě potřebuje, když je čas na opakování a když je připravená denní odměna.';

  @override
  String get notificationsBlocked =>
      'Oznámení jsou vypnutá v nastavení zařízení.';

  @override
  String get notifPetChannelName => 'Moji tě potřebuje';

  @override
  String get notifPetChannelDesc =>
      'Připomínky, když má mazlíček hlad nebo je smutný';

  @override
  String get notifReviewChannelName => 'Připomínky opakování';

  @override
  String get notifReviewChannelDesc =>
      'Připomínky, když je čas opakovat slovíčka';

  @override
  String get notifRewardChannelName => 'Denní odměna';

  @override
  String get notifRewardChannelDesc =>
      'Připomínky, když je připravená denní odměna';

  @override
  String get notifPetHungryTitle => 'Moji má hlad';

  @override
  String get notifPetHungryBody => 'Tvůj mazlíček by teď fakt uvítal svačinu.';

  @override
  String get notifPetSadTitle => 'Mojimu chybíš';

  @override
  String get notifPetSadBody => 'Bez tebe je tu ticho. Nestavíš se pozdravit?';

  @override
  String get notifReviewTitle => 'Čas na opakování';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count slov na tebe čeká.',
      many: '$count slova na tebe čekají.',
      few: '$count slova na tebe čekají.',
      one: '$count slovo na tebe čeká.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'Denní odměna je připravená';

  @override
  String get notifRewardBody => 'Moji pro tebe něco má. Přijď si pro to!';

  @override
  String get careTitle => 'Jak se má Moji?';

  @override
  String get careStatFullness => 'Sytost';

  @override
  String get careStatHappiness => 'Radost';

  @override
  String get careStatHealth => 'Zdraví';

  @override
  String get careAllWell => 'Mojimu se daří skvěle.';

  @override
  String get careNeedHungry => 'Moji má hlad';

  @override
  String get careNeedLonely => 'Moji je posmutnělý';

  @override
  String get careNeedSick => 'Moji je nemocný';

  @override
  String get careSickPenalty =>
      'Dokud je Moji nemocný, XP i mince jsou poloviční.';

  @override
  String get careFeedTitle => 'Nakrm Mojiho';

  @override
  String get careNoFood => 'Došlo jídlo. Zajdi do obchodu doplnit zásoby.';

  @override
  String get careGoToShop => 'Do obchodu';

  @override
  String get carePlay => 'Pohlaď Mojiho';

  @override
  String get carePlayCooldown => 'Moji už má mazlení pro tuto chvíli dost.';

  @override
  String get careClose => 'Zavřít';

  @override
  String careFedItem(String item) {
    return 'Moji snědl $item.';
  }

  @override
  String careCurrentFullness(int value) {
    return 'Sytost teď: $value %';
  }

  @override
  String get scenarioSickPenalty => 'Moji je nemocný — odměny poloviční';

  @override
  String get careDragToFeed => 'Přetáhni na Mojiho a nakrm ho';

  @override
  String get bondLabel => 'POUTO';

  @override
  String get bondStageCurious => 'Zvědavý';

  @override
  String get bondStageFriendly => 'Přátelský';

  @override
  String get bondStageAttached => 'Připoutaný';

  @override
  String get bondStageDevoted => 'Oddaný';

  @override
  String get bondStageInseparable => 'Nerozluční';

  @override
  String bondToNextStage(int points, String stage) {
    return '$points do $stage';
  }

  @override
  String get bondKeepLearning => 'Uč se dál, ať se sblížíte';

  @override
  String get bondMissesYou => 'Mojimu chybíš';

  @override
  String get bondLonely => 'Moji na tebe už dlouho čeká';

  @override
  String get categoryStyle => 'Styl';

  @override
  String get accessoryDescription => 'Drobnost, kterou si Moji vezme na sebe.';

  @override
  String accessoryUnlocksAt(String stage) {
    return 'Odemkne se na $stage';
  }

  @override
  String get accessoryEarnedNotSold => 'Získává se, neprodává';

  @override
  String get accessoryCapName => 'Kšiltovka';

  @override
  String get accessoryTopHatName => 'Cylindr';

  @override
  String get accessoryCowboyHatName => 'Kovbojský klobouk';

  @override
  String get accessoryCrownName => 'Koruna';

  @override
  String get accessoryPartyHatName => 'Party čepice';

  @override
  String get accessoryBowTieName => 'Motýlek';

  @override
  String get accessoryNecklaceName => 'Náhrdelník';

  @override
  String get accessoryMustacheName => 'Knír';

  @override
  String get accessoryBeanieName => 'Čepice';

  @override
  String get accessoryMortarboardName => 'Absolventský klobouk';

  @override
  String get accessoryCollarName => 'Obojek se zvonkem';

  @override
  String get accessoryGlassesName => 'Brýle';

  @override
  String get accessorySunglassesName => 'Sluneční brýle';

  @override
  String get accessoryMaskName => 'Škraboška';

  @override
  String get accessoryMedalName => 'Medaile';

  @override
  String get accessoryScarfName => 'Šála';

  @override
  String get accessoryHeadphonesName => 'Sluchátka';

  @override
  String get accessoryWizardHatName => 'Čarodějnický klobouk';

  @override
  String get accessoryFlowerCrownName => 'Věnec z květin';

  @override
  String get accessoryDevilHornsName => 'Čertovské rohy';

  @override
  String get onboardingLanguageQuestion => 'Jakým jazykem mluvíš?';

  @override
  String get onboardingLanguageConfirm => 'Pokračovat';

  @override
  String get onboardingPetQuestion => 'Koho si vezmeš domů?';

  @override
  String get onboardingPetConfirm => 'Vybrat';

  @override
  String get onboardingLoginTitle => 'Ulož si mazlíčka';

  @override
  String get onboardingLoginGoogle => 'Pokračovat přes Google';

  @override
  String get onboardingLoginEmail => 'Pokračovat e-mailem';

  @override
  String get onboardingLoginSkip => 'Možná později';

  @override
  String get onboardingLoginSubtitle => 'Přihlas se, ať o ně nikdy nepřijdeš.';

  @override
  String get accountEmailLabel => 'E-mail';

  @override
  String get accountPasswordLabel => 'Heslo';

  @override
  String get accountContinueAction => 'Pokračovat';

  @override
  String get accountConflictTitle => 'Dva mazlíčci';

  @override
  String accountConflictBody(String email) {
    return 'Účet $email už mazlíčka má a tenhle telefon taky. Zůstat může jen jeden.';
  }

  @override
  String get accountConflictKeepThisDevice =>
      'Nechat mazlíčka z tohoto telefonu';

  @override
  String get accountConflictUseSaved => 'Použít uloženého mazlíčka';

  @override
  String get accountErrorInvalidEmail => 'Tohle není platná e-mailová adresa.';

  @override
  String get accountErrorWeakPassword => 'Použij aspoň 6 znaků.';

  @override
  String get accountErrorSignIn =>
      'Přihlášení se nezdařilo. Zkontroluj údaje a zkus to znovu.';
}
