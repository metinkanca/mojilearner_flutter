// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get header => 'Налаштування мови';

  @override
  String get iSpeak => 'Я розмовляю';

  @override
  String get imLearning => 'Я вивчаю';

  @override
  String get currentSelection => 'Поточний вибір:';

  @override
  String get level => 'Рівень';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Стрік';

  @override
  String get audio => 'Голос бота';

  @override
  String get designMojiBtn => 'Створити Moji';

  @override
  String get quizMode => 'Вікторина';

  @override
  String get quizDesc => 'Перевір свої знання.';

  @override
  String get scenarios => 'Сценарії';

  @override
  String get scenariosDesc => 'Практикуй реальні розмови.';

  @override
  String get profile => 'Профіль';

  @override
  String get shop => 'Shop';

  @override
  String get mistakes => 'MISTAKES';

  @override
  String get noMistakesYet => 'NO MISTAKES YET!';

  @override
  String get profileDesc => 'Статистика та налаштування.';

  @override
  String get voiceCall => 'Голосовий дзвінок';

  @override
  String get voiceCallDesc => 'Практика мовлення в реальному часі.';

  @override
  String get practiceRealLife => 'Практика з життя';

  @override
  String get chooseSituation => 'Обери ситуацію';

  @override
  String get createYourOwn => 'Створити власний';

  @override
  String get startCustom => 'Почати власний сценарій';

  @override
  String get customPlaceholder => 'Напр. Ви водій таксі...';

  @override
  String get orderingCoffee => 'Замовлення кави';

  @override
  String get jobInterview => 'Співбесіда';

  @override
  String get askingDirections => 'Запитати дорогу';

  @override
  String get atTheDoctor => 'У лікаря';

  @override
  String get shopping => 'Покупки';

  @override
  String get restaurant => 'Ресторан';

  @override
  String get chats => 'Чати';

  @override
  String get searchPlaceholder => 'Пошук повідомлень...';

  @override
  String get newChat => 'Новий чат';

  @override
  String get noChats => 'Поки немає чатів';

  @override
  String get startNewConversation => 'Почати нову розмову';

  @override
  String get blankChat => 'Порожній чат';

  @override
  String get blankChatDesc => 'Почати без контексту';

  @override
  String get roleplayScenario => 'Рольовий сценарій';

  @override
  String get roleplayScenarioDesc => 'Практика конкретних ситуацій';

  @override
  String get chooseChatType => 'Обери тип чату';

  @override
  String get cancel => 'Скасувати';

  @override
  String get typeMessage => 'Ваше повідомлення...';

  @override
  String get designMoji => 'Дизайн Moji';

  @override
  String get fullCustomization => 'Повне налаштування';

  @override
  String get tapToChange => 'Натисніть для зміни';

  @override
  String get mascotColor => 'Колір маскота';

  @override
  String get backgroundColor => 'Колір фону';

  @override
  String get faceExpressions => 'Вирази обличчя';

  @override
  String get personalityFaces => 'Особистість та Обличчя';

  @override
  String get selectFaces => 'Обери обличчя.';

  @override
  String get locked => 'Заблоковано';

  @override
  String unlockMessage(Object level) {
    return 'Досягни вівня $level!';
  }

  @override
  String get yourMistakes => 'Твої помилки';

  @override
  String get learnFromWrong => 'Вчись на помилках';

  @override
  String get all => 'Все';

  @override
  String get grammar => 'Граматика';

  @override
  String get grammarBreakdown => 'Граматичний аналіз';

  @override
  String get close => 'Закрити';

  @override
  String get noGrammarAnalysis => 'Граматичний аналіз недоступний.';

  @override
  String get vocabulary => 'Словник';

  @override
  String get noMistakes => 'Помилок не знайдено!';

  @override
  String get yourAnswer => 'Твоя відповідь';

  @override
  String get correctAnswer => 'Правильна відповідь';

  @override
  String get explanation => 'Пояснення';

  @override
  String get story => 'Сценарії';

  @override
  String get drills => 'Помилки';

  @override
  String get typeHere => 'Введіть тут...';

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
  String get shopItemAppleName => 'Яблуко';

  @override
  String get shopItemAppleDescription => 'Здорова закуска.';

  @override
  String get shopItemCroissantName => 'Круасан';

  @override
  String get shopItemCroissantDescription => 'Масляна доброта.';

  @override
  String get shopItemPizzaName => 'Шматок піци';

  @override
  String get shopItemPizzaDescription => 'Сирна та заситна.';

  @override
  String get shopItemSushiName => 'Набір суші';

  @override
  String get shopItemSushiDescription => 'Преміум риба.';

  @override
  String get shopItemCoffeeName => 'Еспресо';

  @override
  String get shopItemCoffeeDescription => 'Швидкий поштовх енергії.';

  @override
  String get shopItemBgBlueName => 'Блакитний океан';

  @override
  String get shopItemBgBlueDescription => 'Заспокійливі блакитні волни.';

  @override
  String get shopItemBgForestName => 'Зелена гойдалка';

  @override
  String get shopItemBgForestDescription => 'Природне відчуття.';

  @override
  String get shopItemBgSunsetName => 'Помаранчевий закат';

  @override
  String get shopItemBgSunsetDescription => 'Тепло та затишно.';

  @override
  String get shopItemBgGalaxyName => 'Фіолетова галактика';

  @override
  String get shopItemBgGalaxyDescription => 'За межами цього світу.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName куплено!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity куплено!';
  }
}
