// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get header => 'Nyelvi beállítások';

  @override
  String get iSpeak => 'Beszélek';

  @override
  String get imLearning => 'Tanulok';

  @override
  String get currentSelection => 'Jelenlegi kiválasztás:';

  @override
  String get level => 'Szint';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Sorozat';

  @override
  String get audio => 'Bot Hang';

  @override
  String get designMojiBtn => 'Moji tervezés';

  @override
  String get quizMode => 'Kvíz';

  @override
  String get quizDesc => 'Teszteld a tudásod.';

  @override
  String get scenarios => 'Szerepek';

  @override
  String get scenariosDesc => 'Gyakorolj valós párbeszédeket.';

  @override
  String get profile => 'Profil';

  @override
  String get shop => 'Shop';

  @override
  String get mistakes => 'MISTAKES';

  @override
  String get noMistakesYet => 'NO MISTAKES YET!';

  @override
  String get profileDesc => 'Statisztikák és beállítások.';

  @override
  String get voiceCall => 'Hanghívás';

  @override
  String get voiceCallDesc => 'Gyakorolj valós időben beszélni.';

  @override
  String get practiceRealLife => 'Gyakorlat a való életből';

  @override
  String get chooseSituation => 'Válassz helyzetet';

  @override
  String get createYourOwn => 'Készíts sajátot';

  @override
  String get startCustom => 'Egyéni forgatókönyv indítása';

  @override
  String get customPlaceholder => 'Pl. Taxisofőr vagy...';

  @override
  String get orderingCoffee => 'Kávé rendelés';

  @override
  String get jobInterview => 'Állásinterjú';

  @override
  String get askingDirections => 'Útbaigazítás kérése';

  @override
  String get atTheDoctor => 'Az orvosnál';

  @override
  String get shopping => 'Vásárlás';

  @override
  String get restaurant => 'Étterem';

  @override
  String get chats => 'Beszélgetések';

  @override
  String get searchPlaceholder => 'Üzenetek keresése...';

  @override
  String get newChat => 'Új beszélgetés';

  @override
  String get noChats => 'Még nincs beszélgetés';

  @override
  String get startNewConversation => 'Kezdj új beszélgetést';

  @override
  String get blankChat => 'Üres beszélgetés';

  @override
  String get blankChatDesc => 'Kezdés kontextus nélkül';

  @override
  String get roleplayScenario => 'Szerepjáték forgatókönyv';

  @override
  String get roleplayScenarioDesc => 'Gyakorolj konkrét helyzeteket';

  @override
  String get chooseChatType => 'Válassz csevegési típust';

  @override
  String get cancel => 'Mégse';

  @override
  String get typeMessage => 'Írd be az üzeneted...';

  @override
  String get designMoji => 'Moji Tervezés';

  @override
  String get fullCustomization => 'Teljes testreszabás';

  @override
  String get tapToChange => 'Érintsd meg a váltáshoz';

  @override
  String get mascotColor => 'Kabala színe';

  @override
  String get backgroundColor => 'Háttér színe';

  @override
  String get faceExpressions => 'Arckifejezések';

  @override
  String get personalityFaces => 'Személyiség és Arcok';

  @override
  String get selectFaces => 'Válassz arcokat.';

  @override
  String get locked => 'Zárolva';

  @override
  String unlockMessage(Object level) {
    return 'Érd el a(z) $level. szintet a feloldáshoz!';
  }

  @override
  String get yourMistakes => 'Hibáid';

  @override
  String get learnFromWrong => 'Tanulj a hibákból';

  @override
  String get all => 'Összes';

  @override
  String get grammar => 'Nyelvtan';

  @override
  String get grammarBreakdown => 'Nyelvtani Elemzés';

  @override
  String get close => 'Bezárás';

  @override
  String get noGrammarAnalysis => 'Nincs elérhető nyelvtani elemzés.';

  @override
  String get vocabulary => 'Szókincs';

  @override
  String get noMistakes => 'Nem található hiba!';

  @override
  String get yourAnswer => 'Válaszod';

  @override
  String get correctAnswer => 'Helyes válasz';

  @override
  String get explanation => 'Magyarázat';

  @override
  String get story => 'Forgatókönyvek';

  @override
  String get drills => 'Hibák';

  @override
  String get typeHere => 'Írjon ide...';

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
  String get whatsYourName => 'WHAT\'S YOUR NAME?';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get continueBtn => 'CONTINUE';

  @override
  String get howWouldYouRate => 'HOW WOULD YOU RATE';

  @override
  String get yourLevel => 'YOUR LEVEL?';

  @override
  String get beginner => 'BEGINNER';

  @override
  String get intermediate => 'INTERMEDIATE';

  @override
  String get advanced => 'ADVANCED';

  @override
  String get beginnerDesc => 'Just starting. I know very few words.';

  @override
  String get intermediateDesc =>
      'I can hold basic conversations and understand simple texts.';

  @override
  String get advancedDesc =>
      'I\'m fluent or near-fluent. I can discuss complex topics.';

  @override
  String get whichLanguage => 'WHICH LANGUAGE';

  @override
  String get doYouWantToLearn => 'DO YOU WANT TO LEARN?';

  @override
  String get changeAnytime => 'You can change this anytime in settings';

  @override
  String get dontWorryVerify =>
      'Don\'t worry, we\'ll verify this with a quick chat!';

  @override
  String get startAssessment => 'START ASSESSMENT';

  @override
  String get chatAssessment => 'CHAT ASSESSMENT';

  @override
  String get typeYourAnswer => 'Type your answer...';

  @override
  String get mojiIsTyping => 'Moji is typing...';

  @override
  String get send => 'SEND';

  @override
  String get calibrationComplete => 'Calibration Complete!';

  @override
  String get basedOnYourAnswers =>
      'Based on your answers, your recommended starting level is:';

  @override
  String get proficiencyLevel => 'Proficiency Level';

  @override
  String get shopItemAppleName => 'Alma';

  @override
  String get shopItemAppleDescription => 'Egy egészséges snack.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Vajas jóság.';

  @override
  String get shopItemPizzaName => 'Pizza szelet';

  @override
  String get shopItemPizzaDescription => 'Sajtos és teltető.';

  @override
  String get shopItemSushiName => 'Szusi szett';

  @override
  String get shopItemSushiDescription => 'Prémium hal.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Gyors energialökét.';

  @override
  String get shopItemBgBlueName => 'Óceán kék';

  @override
  String get shopItemBgBlueDescription => 'Megnyugtató kék vibrációk.';

  @override
  String get shopItemBgForestName => 'Erdő zöld';

  @override
  String get shopItemBgForestDescription => 'Természetes érzés.';

  @override
  String get shopItemBgSunsetName => 'Napnyugta narancs';

  @override
  String get shopItemBgSunsetDescription => 'Meleg és kényelmes.';

  @override
  String get shopItemBgGalaxyName => 'Galaxis lila';

  @override
  String get shopItemBgGalaxyDescription => 'Kívül az ezen a világon.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName megvásárolt!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity megvásárolt!';
  }
}
