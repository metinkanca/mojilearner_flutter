// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get header => 'Настройки языка';

  @override
  String get iSpeak => 'Я говорю';

  @override
  String get imLearning => 'Я учу';

  @override
  String get currentSelection => 'Текущий выбор:';

  @override
  String get level => 'Уровень';

  @override
  String get xp => 'Опыт';

  @override
  String get streak => 'Серия';

  @override
  String get audio => 'Голос бота';

  @override
  String get designMojiBtn => 'Создать Модзи';

  @override
  String get quizMode => 'Викторина';

  @override
  String get quizDesc => 'Проверь свои знания.';

  @override
  String get scenarios => 'Сценарии';

  @override
  String get scenariosDesc => 'Практика реальных диалогов.';

  @override
  String get profile => 'Профиль';

  @override
  String get shop => 'Магазин';

  @override
  String get mistakes => 'ОШИБКИ';

  @override
  String get noMistakesYet => 'ОШИБОК ЕЩЁ НЕТ!';

  @override
  String get profileDesc => 'Статистика и настройки.';

  @override
  String get voiceCall => 'Голосовой звонок';

  @override
  String get voiceCallDesc => 'Практика речи в реальном времени.';

  @override
  String get practiceRealLife => 'Практика из жизни';

  @override
  String get chooseSituation => 'Выберите ситуацию';

  @override
  String get createYourOwn => 'Создать свой';

  @override
  String get startCustom => 'Начать свой сценарий';

  @override
  String get customPlaceholder => 'Напр. Вы таксист...';

  @override
  String get orderingCoffee => 'Заказ кофе';

  @override
  String get jobInterview => 'Собеседование';

  @override
  String get askingDirections => 'Спросить дорогу';

  @override
  String get atTheDoctor => 'У врача';

  @override
  String get shopping => 'Покупки';

  @override
  String get restaurant => 'Ресторан';

  @override
  String get chats => 'Чаты';

  @override
  String get searchPlaceholder => 'Поиск сообщений...';

  @override
  String get newChat => 'Новый чат';

  @override
  String get noChats => 'Пока нет чатов';

  @override
  String get startNewConversation => 'Начать новый разговор';

  @override
  String get blankChat => 'Пустой чат';

  @override
  String get blankChatDesc => 'Начать без контекста';

  @override
  String get roleplayScenario => 'Ролевой сценарий';

  @override
  String get roleplayScenarioDesc => 'Практика конкретных ситуаций';

  @override
  String get chooseChatType => 'Выберите тип чата';

  @override
  String get cancel => 'Отмена';

  @override
  String get typeMessage => 'Введите сообщение...';

  @override
  String get designMoji => 'Дизайн Модзи';

  @override
  String get fullCustomization => 'Полная настройка';

  @override
  String get tapToChange => 'Нажмите для изменения';

  @override
  String get mascotColor => 'Цвет маскота';

  @override
  String get backgroundColor => 'Цвет фона';

  @override
  String get faceExpressions => 'Выражения лица';

  @override
  String get personalityFaces => 'Личность и Лица';

  @override
  String get selectFaces => 'Выберите лица.';

  @override
  String get locked => 'Закрыто';

  @override
  String unlockMessage(Object level) {
    return 'Достигните уровня $level!';
  }

  @override
  String get yourMistakes => 'Ваши ошибки';

  @override
  String get learnFromWrong => 'Учитесь на ошибках';

  @override
  String get all => 'Все';

  @override
  String get grammar => 'Грамматика';

  @override
  String get grammarBreakdown => 'Грамматический разбор';

  @override
  String get close => 'Закрыть';

  @override
  String get noGrammarAnalysis => 'Нет доступного грамматического анализа.';

  @override
  String get vocabulary => 'Словарь';

  @override
  String get noMistakes => 'Ошибок нет!';

  @override
  String get yourAnswer => 'Ваш ответ';

  @override
  String get correctAnswer => 'Правильный ответ';

  @override
  String get explanation => 'Объяснение';

  @override
  String get story => 'Сценарии';

  @override
  String get drills => 'Ошибки';

  @override
  String get typeHere => 'Введите текст...';

  @override
  String get shopTitle => 'Магазин';

  @override
  String get categoryAll => 'Все';

  @override
  String get categoryFood => 'Еда';

  @override
  String get categoryDecor => 'Декор';

  @override
  String get hideOwnedCosmetics => 'Скрыть Приобретенную Косметику';

  @override
  String get noItems => 'Нет Предметов';

  @override
  String get owned => 'Владение';

  @override
  String get alreadyOwned => 'Уже Владеете';

  @override
  String get alreadyOwnedMessage => 'У вас уже есть этот предмет!';

  @override
  String get quantity => 'Количество';

  @override
  String get totalPrice => 'Общая Цена';

  @override
  String get notEnoughCoins => 'Недостаточно Монет!';

  @override
  String get purchaseFailed => 'Покупка Не Удалась';

  @override
  String get notEnoughCoinsMessage => 'Недостаточно монет!';

  @override
  String get buy => 'Купить';

  @override
  String get tooPoor => 'Слишком Беден';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'Ежедневная Награда';

  @override
  String get claim_reward => 'Получить Награду';

  @override
  String day_streak(Object X) {
    return 'Серия $X дней';
  }

  @override
  String get come_back_tomorrow => 'Возвращайтесь завтра!';

  @override
  String get streak_broken => 'С возвращением! Начинаем заново';

  @override
  String get keep_going => 'Продолжайте!';

  @override
  String get reward_claimed => 'Награда Получена!';

  @override
  String amazing_streak(Object X) {
    return 'Потрясающе! Серия $X дней!';
  }

  @override
  String get whatsYourName => 'КАК ТЕБЯ ЗОВУТ?';

  @override
  String get enterYourName => 'Введите ваше имя';

  @override
  String get continueBtn => 'ПРОДОЛЖИТЬ';

  @override
  String get howWouldYouRate => 'КАК БЫ ВЫ ОЦЕНИЛИ';

  @override
  String get yourLevel => 'ВАШ УРОВЕНЬ?';

  @override
  String get beginner => 'НАЧИНАЮЩИЙ';

  @override
  String get intermediate => 'СРЕДНИЙ';

  @override
  String get advanced => 'ПРОДВИНУТЫЙ';

  @override
  String get beginnerDesc => 'Только начинаю. Знаю очень мало слов.';

  @override
  String get intermediateDesc =>
      'Могу вести простые беседы и понимать простые тексты.';

  @override
  String get advancedDesc =>
      'Свободно владею языком. Могу обсуждать сложные темы.';

  @override
  String get whichLanguage => 'КАКОЙ ЯЗЫК';

  @override
  String get doYouWantToLearn => 'ТЫ ХОЧЕШЬ ВЫУЧИТЬ?';

  @override
  String get changeAnytime =>
      'Вы можете изменить это в любое время в настройках';

  @override
  String get dontWorryVerify =>
      'Не волнуйтесь, мы проверим это с помощью быстрого чата!';

  @override
  String get startAssessment => 'НАЧАТЬ ОЦЕНКУ';

  @override
  String get chatAssessment => 'ОЦЕНКА ЧАТ';

  @override
  String get typeYourAnswer => 'Введите свой ответ...';

  @override
  String get mojiIsTyping => 'Моджи печатает...';

  @override
  String get send => 'ОТПРАВИТЬ';

  @override
  String get calibrationComplete => 'Калибровка Завершена!';

  @override
  String get basedOnYourAnswers =>
      'На основании ваших ответов рекомендуемый начальный уровень:';

  @override
  String get proficiencyLevel => 'Уровень Владения';

  @override
  String get shopItemAppleName => 'Яблоко';

  @override
  String get shopItemAppleDescription => 'Здоровый перекус.';

  @override
  String get shopItemCroissantName => 'Круассан';

  @override
  String get shopItemCroissantDescription => 'Сливочная благодать.';

  @override
  String get shopItemPizzaName => 'Кусочек пиццы';

  @override
  String get shopItemPizzaDescription => 'Сыр и сытная.';

  @override
  String get shopItemSushiName => 'Набор суши';

  @override
  String get shopItemSushiDescription => 'Премиум рыба.';

  @override
  String get shopItemCoffeeName => 'Эспрессо';

  @override
  String get shopItemCoffeeDescription => 'Быстрый прилив энергии.';

  @override
  String get shopItemBgBlueName => 'Океан синий';

  @override
  String get shopItemBgBlueDescription => 'Успокаивающие синие волны.';

  @override
  String get shopItemBgForestName => 'Лес зеленый';

  @override
  String get shopItemBgForestDescription => 'Природное ощущение.';

  @override
  String get shopItemBgSunsetName => 'Закат оранжевый';

  @override
  String get shopItemBgSunsetDescription => 'Тепло и уют.';

  @override
  String get shopItemBgGalaxyName => 'Галактика фиолетовая';

  @override
  String get shopItemBgGalaxyDescription => 'Потусторонний мир.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName куплен!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity куплена!';
  }
}
