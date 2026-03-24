// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get header => 'Kieliasetukset';

  @override
  String get iSpeak => 'Puhun';

  @override
  String get imLearning => 'Opiskelen';

  @override
  String get currentSelection => 'Nykyinen valinta:';

  @override
  String get level => 'Taso';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Putki';

  @override
  String get audio => 'Botin ääni';

  @override
  String get designMojiBtn => 'Suunnittele Moji';

  @override
  String get quizMode => 'Visa';

  @override
  String get quizDesc => 'Testaa tietosi.';

  @override
  String get scenarios => 'Skenaariot';

  @override
  String get scenariosDesc => 'Harjoittele oikeita keskusteluja.';

  @override
  String get profile => 'Profiili';

  @override
  String get shop => 'Kauppa';

  @override
  String get mistakes => 'VIRHEET';

  @override
  String get noMistakesYet => 'EI VIELÄ VIRHEITÄ!';

  @override
  String get profileDesc => 'Katso tilastot ja asetukset.';

  @override
  String get voiceCall => 'Puhelu';

  @override
  String get voiceCallDesc => 'Harjoittele puhumista reaaliajassa.';

  @override
  String get practiceRealLife => 'Harjoittele elämää';

  @override
  String get chooseSituation => 'Valitse tilanne';

  @override
  String get createYourOwn => 'Luo oma';

  @override
  String get startCustom => 'Aloita oma skenaario';

  @override
  String get customPlaceholder => 'Esim. Olet taksinkuljettaja...';

  @override
  String get orderingCoffee => 'Kahvin tilaaminen';

  @override
  String get jobInterview => 'Työhaastattelu';

  @override
  String get askingDirections => 'Tien kysyminen';

  @override
  String get atTheDoctor => 'Lääkärissä';

  @override
  String get shopping => 'Ostokset';

  @override
  String get restaurant => 'Ravintola';

  @override
  String get chats => 'Chatit';

  @override
  String get searchPlaceholder => 'Etsi viestejä...';

  @override
  String get newChat => 'Uusi Chat';

  @override
  String get noChats => 'Ei chatteja vielä';

  @override
  String get startNewConversation => 'Aloita uusi keskustelu';

  @override
  String get blankChat => 'Tyhjä Chat';

  @override
  String get blankChatDesc => 'Aloita ilman kontekstia';

  @override
  String get roleplayScenario => 'Roolipeliskenaario';

  @override
  String get roleplayScenarioDesc => 'Harjoittele tiettyjä tilanteita';

  @override
  String get chooseChatType => 'Valitse chat-tyyppi';

  @override
  String get cancel => 'Peruuta';

  @override
  String get typeMessage => 'Kirjoita viestisi...';

  @override
  String get designMoji => 'Suunnittele Moji';

  @override
  String get fullCustomization => 'Täysi muokkaus';

  @override
  String get tapToChange => 'Napauta vaihtaaksesi';

  @override
  String get mascotColor => 'Maskotin väri';

  @override
  String get backgroundColor => 'Taustaväri';

  @override
  String get faceExpressions => 'Kasvonilmeet';

  @override
  String get personalityFaces => 'Persoonallisuus & Kasvot';

  @override
  String get selectFaces => 'Valitse kasvot.';

  @override
  String get locked => 'Lukittu';

  @override
  String unlockMessage(Object level) {
    return 'Saavuta taso $level avataksesi!';
  }

  @override
  String get yourMistakes => 'Virheesi';

  @override
  String get learnFromWrong => 'Opi virheistä';

  @override
  String get all => 'Kaikki';

  @override
  String get grammar => 'Kielioppi';

  @override
  String get grammarBreakdown => 'Kielioppianalyysi';

  @override
  String get close => 'Sulje';

  @override
  String get noGrammarAnalysis => 'Ei kielioppianalyysiä saatavilla.';

  @override
  String get vocabulary => 'Sanasto';

  @override
  String get noMistakes => 'Ei virheitä löytynyt!';

  @override
  String get yourAnswer => 'Vastauksesi';

  @override
  String get correctAnswer => 'Oikea vastaus';

  @override
  String get explanation => 'Selitys';

  @override
  String get story => 'Skenaariot';

  @override
  String get drills => 'Virheet';

  @override
  String get typeHere => 'Kirjoita tähän...';

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
  String get whatsYourName => 'MIKÄ SINUN NIMESI ON?';

  @override
  String get enterYourName => 'Kirjoita nimesi';

  @override
  String get continueBtn => 'JATKA';

  @override
  String get howWouldYouRate => 'MITEN ARVIOISIT';

  @override
  String get yourLevel => 'TASOSI?';

  @override
  String get beginner => 'ALOITTELIJA';

  @override
  String get intermediate => 'KESKITASO';

  @override
  String get advanced => 'EDISTYNYT';

  @override
  String get beginnerDesc =>
      'Olen juuri aloittanut. Tiedän hyvin vähän sanoja.';

  @override
  String get intermediateDesc =>
      'Osaan käydä perustavanlaatuisia keskusteluja ja ymmärrän yksinkertaisia tekstejä.';

  @override
  String get advancedDesc =>
      'Olen sujuva tai lähes sujuva. Voin keskustella monimutkaisista aiheista.';

  @override
  String get whichLanguage => 'MIKÄ KIELI';

  @override
  String get doYouWantToLearn => 'HALUAT OPPIA?';

  @override
  String get changeAnytime => 'Voit muuttaa tämän milloin tahansa asetuksista';

  @override
  String get dontWorryVerify =>
      'Älä huoli, vahvistamme tämän nopealla chatillä!';

  @override
  String get startAssessment => 'ALOITA ARVIOINTI';

  @override
  String get chatAssessment => 'CHAT ARVIOINTI';

  @override
  String get typeYourAnswer => 'Kirjoita vastauksesi...';

  @override
  String get mojiIsTyping => 'Moji kirjoittaa...';

  @override
  String get send => 'LÄHETÄ';

  @override
  String get calibrationComplete => 'Kalibrointi Valmis!';

  @override
  String get basedOnYourAnswers =>
      'Vastauksiesi perusteella suositeltu aloitustasosi on:';

  @override
  String get proficiencyLevel => 'Taitotaso';

  @override
  String get shopItemAppleName => 'Omena';

  @override
  String get shopItemAppleDescription => 'Terveellinen välipalat.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Tervallisuutta.';

  @override
  String get shopItemPizzaName => 'Pizzapala';

  @override
  String get shopItemPizzaDescription => 'Juustoa ja täyttävä.';

  @override
  String get shopItemSushiName => 'Sushi-setti';

  @override
  String get shopItemSushiDescription => 'Huippuluokkaa kalaa.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Nopea energiapohja.';

  @override
  String get shopItemBgBlueName => 'Valtameren sininen';

  @override
  String get shopItemBgBlueDescription => 'Rauhoittavat siniset vibat.';

  @override
  String get shopItemBgForestName => 'Metsän vihreä';

  @override
  String get shopItemBgForestDescription => 'Luonnonmukainen tunnelma.';

  @override
  String get shopItemBgSunsetName => 'Auringonlaskun oranssi';

  @override
  String get shopItemBgSunsetDescription => 'Lämmin ja viihtyisä.';

  @override
  String get shopItemBgGalaxyName => 'Galaksin violetti';

  @override
  String get shopItemBgGalaxyDescription => 'Tämän maailman ulkopuolella.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName ostettu!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity ostettu!';
  }
}
