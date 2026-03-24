// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get header => 'Ustawienia języka';

  @override
  String get iSpeak => 'Mówię po';

  @override
  String get imLearning => 'Uczę się';

  @override
  String get currentSelection => 'Obecny wybór:';

  @override
  String get level => 'Poziom';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Seria';

  @override
  String get audio => 'Głos bota';

  @override
  String get designMojiBtn => 'Zaprojektuj Moji';

  @override
  String get quizMode => 'Quiz';

  @override
  String get quizDesc => 'Sprawdź swoją wiedzę.';

  @override
  String get scenarios => 'Scenariusze';

  @override
  String get scenariosDesc => 'Ćwicz prawdziwe rozmowy.';

  @override
  String get profile => 'Profil';

  @override
  String get shop => 'Sklep';

  @override
  String get mistakes => 'BŁĘDY';

  @override
  String get noMistakesYet => 'JESZCZE BRAK BŁĘDÓW!';

  @override
  String get profileDesc => 'Zobacz statystyki i ustawienia.';

  @override
  String get voiceCall => 'Rozmowa głosowa';

  @override
  String get voiceCallDesc => 'Ćwicz mówienie w czasie rzeczywistym.';

  @override
  String get practiceRealLife => 'Ćwicz prawdziwe życie';

  @override
  String get chooseSituation => 'Wybierz sytuację';

  @override
  String get createYourOwn => 'Stwórz własną';

  @override
  String get startCustom => 'Rozpocznij własny scenariusz';

  @override
  String get customPlaceholder => 'Np. Jesteś taksówkarzem...';

  @override
  String get orderingCoffee => 'Zamawianie kawy';

  @override
  String get jobInterview => 'Rozmowa o pracę';

  @override
  String get askingDirections => 'Pytanie o drogę';

  @override
  String get atTheDoctor => 'U lekarza';

  @override
  String get shopping => 'Zakupy';

  @override
  String get restaurant => 'Restauracja';

  @override
  String get chats => 'Czaty';

  @override
  String get searchPlaceholder => 'Szukaj wiadomości...';

  @override
  String get newChat => 'Nowy czat';

  @override
  String get noChats => 'Brak czatów';

  @override
  String get startNewConversation => 'Rozpocznij nową rozmowę';

  @override
  String get blankChat => 'Pusty czat';

  @override
  String get blankChatDesc => 'Rozpocznij bez kontekstu';

  @override
  String get roleplayScenario => 'Scenariusz ról';

  @override
  String get roleplayScenarioDesc => 'Ćwicz konkretne sytuacje';

  @override
  String get chooseChatType => 'Wybierz typ czatu';

  @override
  String get cancel => 'Anuluj';

  @override
  String get typeMessage => 'Wpisz wiadomość...';

  @override
  String get designMoji => 'Projektuj Moji';

  @override
  String get fullCustomization => 'Pełna personalizacja';

  @override
  String get tapToChange => 'Dotknij, aby zmienić';

  @override
  String get mascotColor => 'Kolor maskotki';

  @override
  String get backgroundColor => 'Kolor tła';

  @override
  String get faceExpressions => 'Wyrazy twarzy';

  @override
  String get personalityFaces => 'Osobowość i twarze';

  @override
  String get selectFaces => 'Wybierz twarze.';

  @override
  String get locked => 'Zablokowane';

  @override
  String unlockMessage(Object level) {
    return 'Osiągnij poziom $level, aby odblokować!';
  }

  @override
  String get yourMistakes => 'Twoje błędy';

  @override
  String get learnFromWrong => 'Ucz się na błędach';

  @override
  String get all => 'Wszystkie';

  @override
  String get grammar => 'Gramatyka';

  @override
  String get grammarBreakdown => 'Analiza Gramatyczna';

  @override
  String get close => 'Zamknij';

  @override
  String get noGrammarAnalysis => 'Analiza gramatyczna niedostępna.';

  @override
  String get vocabulary => 'Słownictwo';

  @override
  String get noMistakes => 'Nie znaleziono błędów!';

  @override
  String get yourAnswer => 'Twoja odpowiedź';

  @override
  String get correctAnswer => 'Poprawna odpowiedź';

  @override
  String get explanation => 'Wyjaśnienie';

  @override
  String get story => 'Scenariusze';

  @override
  String get drills => 'Błędy';

  @override
  String get typeHere => 'Wpisz tutaj...';

  @override
  String get shopTitle => 'Sklep';

  @override
  String get categoryAll => 'Wszystko';

  @override
  String get categoryFood => 'Jedzenie';

  @override
  String get categoryDecor => 'Dekoracja';

  @override
  String get hideOwnedCosmetics => 'Ukryj Posiadane Kosmetyki';

  @override
  String get noItems => 'Brak Przedmiotów';

  @override
  String get owned => 'Posiadane';

  @override
  String get alreadyOwned => 'Już Posiadane';

  @override
  String get alreadyOwnedMessage => 'Już posiadasz ten przedmiot!';

  @override
  String get quantity => 'Ilość';

  @override
  String get totalPrice => 'Całkowita Cena';

  @override
  String get notEnoughCoins => 'Niewystarczające Monety!';

  @override
  String get purchaseFailed => 'Zakup Nieudany';

  @override
  String get notEnoughCoinsMessage => 'Niewystarczające monety!';

  @override
  String get buy => 'Kup';

  @override
  String get tooPoor => 'Zbyt Biedny';

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
  String get whatsYourName => 'JAK MASZ NA IMIĘ?';

  @override
  String get enterYourName => 'Wpisz swoje imię';

  @override
  String get continueBtn => 'KONTYNUUJ';

  @override
  String get howWouldYouRate => 'JAK OCENIASZ';

  @override
  String get yourLevel => 'SWÓJ POZIOM?';

  @override
  String get beginner => 'POCZĄTKUJĄCY';

  @override
  String get intermediate => 'ŚREDNIOZAAWANSOWANY';

  @override
  String get advanced => 'ZAAWANSOWANY';

  @override
  String get beginnerDesc => 'Dopiero zaczynam. Znam bardzo mało słów.';

  @override
  String get intermediateDesc =>
      'Mogę prowadzić podstawowe rozmowy i rozumieć proste teksty.';

  @override
  String get advancedDesc =>
      'Jestem biegły lub prawie biegły. Mogę dyskutować o złożonych tematach.';

  @override
  String get whichLanguage => 'KTÓREGO JĘZYKA';

  @override
  String get doYouWantToLearn => 'CHCESZ SIĘ UCZYĆ?';

  @override
  String get changeAnytime =>
      'Możesz to zmienić w każdej chwili w ustawieniach';

  @override
  String get dontWorryVerify =>
      'Nie martw się, zweryfikujemy to szybkim czatem!';

  @override
  String get startAssessment => 'ROZPOCZNIJ OCENĘ';

  @override
  String get chatAssessment => 'OCENA CZATU';

  @override
  String get typeYourAnswer => 'Wpisz swoją odpowiedź...';

  @override
  String get mojiIsTyping => 'Moji pisze...';

  @override
  String get send => 'WYŚLIJ';

  @override
  String get calibrationComplete => 'Kalibracja Zakończona!';

  @override
  String get basedOnYourAnswers =>
      'Na podstawie Twoich odpowiedzi zalecany poziom startowy to:';

  @override
  String get proficiencyLevel => 'Poziom Biegłości';

  @override
  String get shopItemAppleName => 'Jabłko';

  @override
  String get shopItemAppleDescription => 'Zdrowa przekąska.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Masłana dobroć.';

  @override
  String get shopItemPizzaName => 'Plasterek pizzy';

  @override
  String get shopItemPizzaDescription => 'Serowy i sycący.';

  @override
  String get shopItemSushiName => 'Zestaw sushi';

  @override
  String get shopItemSushiDescription => 'Rybka premium.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Szybki zastrzyk energii.';

  @override
  String get shopItemBgBlueName => 'Niebieski ocean';

  @override
  String get shopItemBgBlueDescription => 'Uspokajające niebieskie wibracje.';

  @override
  String get shopItemBgForestName => 'Zielony las';

  @override
  String get shopItemBgForestDescription => 'Naturalne uczucie.';

  @override
  String get shopItemBgSunsetName => 'Pomarańczowy zachód słońca';

  @override
  String get shopItemBgSunsetDescription => 'Ciepły i przytulny.';

  @override
  String get shopItemBgGalaxyName => 'Fioletowa galaktyka';

  @override
  String get shopItemBgGalaxyDescription => 'Poza tym światem.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName zakupiony!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity zakupiony!';
  }
}
