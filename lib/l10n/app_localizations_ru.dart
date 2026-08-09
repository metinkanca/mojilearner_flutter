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
  String get shopItemAppleName => 'Ğ¯Ğ±Ğ»Ğ¾ĞºĞ¾';

  @override
  String get shopItemAppleDescription => 'A healthy snack.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Buttery goodness.';

  @override
  String get shopItemPizzaName => 'Pizza Slice';

  @override
  String get shopItemPizzaDescription => 'Cheesy and filling.';

  @override
  String get shopItemSushiName => 'Sushi Set';

  @override
  String get shopItemSushiDescription => 'Premium fish.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Quick energy boost.';

  @override
  String get shopItemMedicineName => 'Лекарство';

  @override
  String get shopItemMedicineDescription => 'Возвращает Моджи здоровье.';

  @override
  String get review => 'Повторение';

  @override
  String reviewDueCount(int count) {
    return '$count к повтору';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$current из $total';
  }

  @override
  String get reviewShowAnswer => 'Показать ответ';

  @override
  String get reviewGradeAgain => 'Ещё раз';

  @override
  String get reviewGradeHard => 'Трудно';

  @override
  String get reviewGradeGood => 'Хорошо';

  @override
  String get reviewGradeEasy => 'Легко';

  @override
  String get reviewAllCaughtUp => 'Всё повторено!';

  @override
  String get reviewNothingDue =>
      'Сейчас нечего повторять. Пообщайся или пройди тест — Моджи запомнит, что даётся тебе трудно.';

  @override
  String get reviewSessionComplete => 'Повторение завершено!';

  @override
  String reviewSessionSummary(int count) {
    return 'Повторено: $count';
  }

  @override
  String get reviewDone => 'Готово';

  @override
  String get reviewCorrectionPrompt => 'Как правильно?';

  @override
  String get reviewVocabularyPrompt => 'Что это значит?';

  @override
  String get shopItemBgBlueName => 'Ocean Blue';

  @override
  String get shopItemBgBlueDescription => 'Calming blue vibes.';

  @override
  String get shopItemBgForestName => 'Forest Green';

  @override
  String get shopItemBgForestDescription => 'Natural feeling.';

  @override
  String get shopItemBgSunsetName => 'Sunset Orange';

  @override
  String get shopItemBgSunsetDescription => 'Warm and cozy.';

  @override
  String get shopItemBgGalaxyName => 'Galaxy Purple';

  @override
  String get shopItemBgGalaxyDescription => 'Out of this world.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return 'Purchased $itemName!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return 'Purchased $itemName x$quantity!';
  }

  @override
  String get youLabel => 'Ты';

  @override
  String get mojiSleepReconnect =>
      'Zzz... Модзи дремлет, пока языковая связь переподключается. Попробуй снова чуть позже.';

  @override
  String get mojiSleepNight =>
      'Тсс... Модзи спит. Нажми на Модзи, чтобы разбудить его.';

  @override
  String get mojiSleepHintReconnect =>
      'MOJI ДРЕМЛЕТ... ЯЗЫКОВАЯ СВЯЗЬ ПЕРЕПОДКЛЮЧАЕТСЯ';

  @override
  String get mojiSleepHintNight => 'MOJI СПИТ... НАЖМИ, ЧТОБЫ РАЗБУДИТЬ';

  @override
  String get mojiWakeSuccess =>
      'Зевок... Модзи проснулся! Давай практиковаться!';

  @override
  String get mojiSleepReasonReconnect =>
      'Модзи дремлет, пока языковая связь переподключается.';

  @override
  String get mojiSleepReasonNight => 'Модзи спит. Нажми, чтобы разбудить.';

  @override
  String get levelsScreenTitle => 'Уровни';

  @override
  String get levelStatusCurrent => 'Текущий уровень';

  @override
  String get levelStatusCompleted => 'Завершено';

  @override
  String get levelRewardLabel => 'Награда';

  @override
  String get quizPausedTitle => 'На паузе';

  @override
  String get quizPausedPrompt => 'Продолжить или выйти?';

  @override
  String get quizPlay => 'Играть';

  @override
  String get quizPause => 'Пауза';

  @override
  String get quizExit => 'Выход';

  @override
  String get weeklyProgressTitle => 'Недельный прогресс';

  @override
  String dayLabel(int dayNum) {
    return 'День $dayNum';
  }

  @override
  String get dailyRewardHint => 'Вернитесь завтра за ежедневной наградой';

  @override
  String get resetAppButton => 'Сброс';

  @override
  String get resetAppTitle => 'Сброс приложения';

  @override
  String get resetAppWarning => 'Это удалит весь ваш прогресс.\n\nВы уверены?';

  @override
  String get resetAction => 'Сброс';

  @override
  String get resetSuccessMessage => 'Приложение успешно сброшено';

  @override
  String get selectYourCharacter => 'Выберите своего персонажа';

  @override
  String get characterDog => 'Собака';

  @override
  String get characterCat => 'Кошка';

  @override
  String get characterBird => 'Птица';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Moji дремлет, пока восстанавливается языковая связь. Попробуй ещё раз чуть позже.';

  @override
  String get mojiDozingReconnect =>
      'Moji дремлет, пока восстанавливается языковая связь.';

  @override
  String get mojiSleepingTapWake => 'Moji спит. Нажми, чтобы разбудить.';

  @override
  String get mojiAwakeReady => 'Moji проснулся и готов!';

  @override
  String get wardrobeTitle => 'Гардероб';

  @override
  String get slotHat => 'Шляпа';

  @override
  String get slotNeck => 'Шея';

  @override
  String get slotFace => 'Лицо';

  @override
  String get bodyTailColor => 'Цвет тела и хвоста';

  @override
  String get eyeColor => 'Цвет глаз';

  @override
  String get eyeStyleSolid => 'Однотонные';

  @override
  String get eyeStyleOddEyed => 'Разные глаза';

  @override
  String get leftEye => 'Левый глаз';

  @override
  String get rightEye => 'Правый глаз';

  @override
  String get colorLabel => 'Цвет';

  @override
  String get scenarioObjectives => 'Цели';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'Пройдено';

  @override
  String get scenarioBonusLabel => 'Бонус';

  @override
  String get scenarioCompleteTitle => 'Сценарий пройден!';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '$done из $total целей';
  }

  @override
  String get scenarioFirstClear => 'Первое прохождение!';

  @override
  String get scenarioReplayNote =>
      'Награда за повтор — за первое прохождение дают больше.';

  @override
  String get scenarioContinue => 'Продолжить';

  @override
  String get objCoffeeOrder => 'Закажи напиток';

  @override
  String get objCoffeeCustomize => 'Измени свой заказ';

  @override
  String get objCoffeePrice => 'Спроси, сколько стоит';

  @override
  String get objCoffeeSmallTalk => 'Поболтай с баристой';

  @override
  String get objInterviewGreet => 'Представься';

  @override
  String get objInterviewExperience => 'Расскажи о своём опыте';

  @override
  String get objInterviewStrength => 'Объясни, почему ты подходишь';

  @override
  String get objInterviewAsk => 'Задай вопрос о должности';

  @override
  String get objDirectionsAsk => 'Спроси, как куда-то добраться';

  @override
  String get objDirectionsClarify => 'Попроси повторить или говорить медленнее';

  @override
  String get objDirectionsDistance => 'Узнай, как далеко это';

  @override
  String get objDirectionsThank => 'Как следует поблагодари';

  @override
  String get objDoctorSymptom => 'Опиши свои симптомы';

  @override
  String get objDoctorDuration => 'Скажи, как давно это началось';

  @override
  String get objDoctorQuestion => 'Спроси, что тебе делать';

  @override
  String get objDoctorAllergy => 'Упомяни аллергию или лекарства';

  @override
  String get objShoppingFind => 'Спроси, где лежит товар';

  @override
  String get objShoppingSize => 'Спроси про размер, цвет или как сидит';

  @override
  String get objShoppingPrice => 'Спроси цену';

  @override
  String get objShoppingPay => 'Оплати покупку';

  @override
  String get objRestaurantTable => 'Попроси столик';

  @override
  String get objRestaurantOrder => 'Закажи еду';

  @override
  String get objRestaurantDrink => 'Закажи что-нибудь выпить';

  @override
  String get objRestaurantBill => 'Попроси счёт';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEnable => 'Напоминать о Моджи';

  @override
  String get notificationsDesc =>
      'Моджи сообщит, когда ты ему нужен, когда пора повторять и когда готова ежедневная награда.';

  @override
  String get notificationsBlocked =>
      'Уведомления отключены в настройках устройства.';

  @override
  String get notifPetChannelName => 'Моджи нужен ты';

  @override
  String get notifPetChannelDesc =>
      'Напоминания, когда питомец голоден или грустит';

  @override
  String get notifReviewChannelName => 'Напоминания о повторении';

  @override
  String get notifReviewChannelDesc =>
      'Напоминания, когда слова пора повторить';

  @override
  String get notifRewardChannelName => 'Ежедневная награда';

  @override
  String get notifRewardChannelDesc =>
      'Напоминания, когда готова ежедневная награда';

  @override
  String get notifPetHungryTitle => 'Моджи проголодался';

  @override
  String get notifPetHungryBody =>
      'Твоему питомцу сейчас очень пригодился бы перекус.';

  @override
  String get notifPetSadTitle => 'Моджи скучает';

  @override
  String get notifPetSadBody => 'Без тебя стало тихо. Заглянешь поздороваться?';

  @override
  String get notifReviewTitle => 'Пора повторить';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова ждут тебя.',
      many: '$count слов ждут тебя.',
      few: '$count слова ждут тебя.',
      one: '$count слово ждёт тебя.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'Ежедневная награда готова';

  @override
  String get notifRewardBody => 'У Моджи кое-что для тебя. Заходи забрать!';

  @override
  String get careTitle => 'Как дела у Моджи?';

  @override
  String get careStatFullness => 'Сытость';

  @override
  String get careStatHappiness => 'Настроение';

  @override
  String get careStatHealth => 'Здоровье';

  @override
  String get careAllWell => 'У Моджи всё отлично.';

  @override
  String get careNeedHungry => 'Моджи голоден';

  @override
  String get careNeedLonely => 'Моджи приуныл';

  @override
  String get careNeedSick => 'Моджи болеет';

  @override
  String get careSickPenalty =>
      'Пока Моджи болеет, весь опыт и монеты уменьшаются вдвое.';

  @override
  String get careFeedTitle => 'Покормить Моджи';

  @override
  String get careNoFood => 'Еда закончилась. Загляни в магазин.';

  @override
  String get careGoToShop => 'В магазин';

  @override
  String get carePlay => 'Погладить Моджи';

  @override
  String get carePlayCooldown => 'Моджи пока достаточно ласки.';

  @override
  String get careClose => 'Закрыть';

  @override
  String careFedItem(String item) {
    return 'Моджи съел: $item.';
  }

  @override
  String careCurrentFullness(int value) {
    return 'Сытость сейчас: $value%';
  }

  @override
  String get scenarioSickPenalty => 'Моджи болеет — награды вдвое меньше';

  @override
  String get careDragToFeed => 'Перетащи на Моджи, чтобы покормить';
}
