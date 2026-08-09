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
  String get shop => 'Крамниця';

  @override
  String get mistakes => 'ПОМИЛКИ';

  @override
  String get noMistakesYet => 'ЩЕ НЕМАЄ ПОМИЛОК!';

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
  String get shopTitle => 'Крамниця';

  @override
  String get categoryAll => 'Усі';

  @override
  String get categoryFood => 'Їжа';

  @override
  String get categoryDecor => 'Декор';

  @override
  String get hideOwnedCosmetics => 'Приховати придбані аксесуари';

  @override
  String get noItems => 'Немає предметів';

  @override
  String get owned => 'Придбано';

  @override
  String get alreadyOwned => 'Вже придбано';

  @override
  String get alreadyOwnedMessage => 'Ти вже маєш цей предмет!';

  @override
  String get quantity => 'Кількість';

  @override
  String get totalPrice => 'Загальна ціна';

  @override
  String get notEnoughCoins => 'Недостатньо монет!';

  @override
  String get purchaseFailed => 'Покупка не вдалася';

  @override
  String get notEnoughCoinsMessage => 'Недостатньо монет!';

  @override
  String get buy => 'Купити';

  @override
  String get tooPoor => 'Замало монет';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'Щоденна нагорода';

  @override
  String get claim_reward => 'Отримати нагороду';

  @override
  String day_streak(Object X) {
    return 'День $X серії';
  }

  @override
  String get come_back_tomorrow => 'Повертайся завтра!';

  @override
  String get streak_broken => 'З поверненням! Починаємо спочатку';

  @override
  String get keep_going => 'Так тримати!';

  @override
  String get reward_claimed => 'Нагороду отримано!';

  @override
  String amazing_streak(Object X) {
    return 'Чудово! Серія $X днів!';
  }

  @override
  String get whatsYourName => 'ЯК ТЕБЕ ЗВАТИ?';

  @override
  String get enterYourName => 'Введи своє ім\'я';

  @override
  String get continueBtn => 'ДАЛІ';

  @override
  String get howWouldYouRate => 'ЯК ТИ ОЦІНЮЄШ';

  @override
  String get yourLevel => 'СВІЙ РІВЕНЬ?';

  @override
  String get beginner => 'ПОЧАТКІВЕЦЬ';

  @override
  String get intermediate => 'СЕРЕДНІЙ';

  @override
  String get advanced => 'ПРОСУНУТИЙ';

  @override
  String get beginnerDesc => 'Тільки починаю. Знаю дуже мало слів.';

  @override
  String get intermediateDesc =>
      'Можу вести прості розмови й розумію прості тексти.';

  @override
  String get advancedDesc =>
      'Володію вільно або майже вільно. Можу обговорювати складні теми.';

  @override
  String get whichLanguage => 'ЯКУ МОВУ';

  @override
  String get doYouWantToLearn => 'ТИ ХОЧЕШ ВИВЧАТИ?';

  @override
  String get changeAnytime => 'Це можна змінити будь-коли в налаштуваннях';

  @override
  String get dontWorryVerify =>
      'Не хвилюйся, ми перевіримо це в короткій розмові!';

  @override
  String get startAssessment => 'ПОЧАТИ ОЦІНЮВАННЯ';

  @override
  String get chatAssessment => 'ОЦІНЮВАННЯ В ЧАТІ';

  @override
  String get typeYourAnswer => 'Введи свою відповідь...';

  @override
  String get mojiIsTyping => 'Moji друкує...';

  @override
  String get send => 'НАДІСЛАТИ';

  @override
  String get calibrationComplete => 'Калібрування завершено!';

  @override
  String get basedOnYourAnswers =>
      'На основі твоїх відповідей рекомендований початковий рівень:';

  @override
  String get proficiencyLevel => 'Рівень володіння';

  @override
  String get shopItemAppleName => 'Apple';

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
  String get shopItemMedicineName => 'Ліки';

  @override
  String get shopItemMedicineDescription => 'Повертає Моджі здоровʼя.';

  @override
  String get review => 'Повторення';

  @override
  String reviewDueCount(int count) {
    return '$count до повтору';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$current з $total';
  }

  @override
  String get reviewShowAnswer => 'Показати відповідь';

  @override
  String get reviewGradeAgain => 'Ще раз';

  @override
  String get reviewGradeHard => 'Важко';

  @override
  String get reviewGradeGood => 'Добре';

  @override
  String get reviewGradeEasy => 'Легко';

  @override
  String get reviewAllCaughtUp => 'Усе повторено!';

  @override
  String get reviewNothingDue =>
      'Зараз немає чого повторювати. Поспілкуйся або пройди тест — Моджі запамʼятає, що дається тобі важко.';

  @override
  String get reviewSessionComplete => 'Повторення завершено!';

  @override
  String reviewSessionSummary(int count) {
    return 'Повторено: $count';
  }

  @override
  String get reviewDone => 'Готово';

  @override
  String get reviewCorrectionPrompt => 'Як правильно?';

  @override
  String get reviewVocabularyPrompt => 'Що це означає?';

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
  String get youLabel => 'Ти';

  @override
  String get mojiSleepReconnect =>
      'Zzz... Модзі дрімає, поки мовний звязок перепідключається. Спробуй ще раз незабаром.';

  @override
  String get mojiSleepNight =>
      'Тсс... Модзі спить. Торкнися Модзі, щоб розбудити.';

  @override
  String get mojiSleepHintReconnect =>
      'MOJI ДРІМАЄ... МОВНИЙ ЗВЯЗОК ПЕРЕПІДКЛЮЧАЄТЬСЯ';

  @override
  String get mojiSleepHintNight => 'MOJI СПИТЬ... ТОРКНИСЯ, ЩОБ РОЗБУДИТИ';

  @override
  String get mojiWakeSuccess =>
      'Позіх... Модзі вже прокинувся! Давай практикуватися!';

  @override
  String get mojiSleepReasonReconnect =>
      'Модзі дрімає, поки мовний звязок перепідключається.';

  @override
  String get mojiSleepReasonNight => 'Модзі спить. Торкнися, щоб розбудити.';

  @override
  String get levelsScreenTitle => 'Рівні';

  @override
  String get levelStatusCurrent => 'Поточний рівень';

  @override
  String get levelStatusCompleted => 'Завершено';

  @override
  String get levelRewardLabel => 'Винагорода';

  @override
  String get quizPausedTitle => 'На паузі';

  @override
  String get quizPausedPrompt => 'Продовжити чи вийти?';

  @override
  String get quizPlay => 'Грати';

  @override
  String get quizPause => 'Пауза';

  @override
  String get quizExit => 'Вихід';

  @override
  String get weeklyProgressTitle => 'Тижневий прогрес';

  @override
  String dayLabel(int dayNum) {
    return 'День $dayNum';
  }

  @override
  String get dailyRewardHint => 'Повернись завтра для щоденної винагороди';

  @override
  String get resetAppButton => 'Скидання';

  @override
  String get resetAppTitle => 'Скинути додаток';

  @override
  String get resetAppWarning => 'Це видалить весь ваш прогрес.\n\nВи впевнені?';

  @override
  String get resetAction => 'Скидання';

  @override
  String get resetSuccessMessage => 'Додаток успішно скинуто';

  @override
  String get selectYourCharacter => 'Виберіть свого персонажа';

  @override
  String get characterDog => 'Собака';

  @override
  String get characterCat => 'Кіт';

  @override
  String get characterBird => 'Птах';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Moji дрімає, поки відновлюється мовний зв\'язок. Спробуй ще раз трохи згодом.';

  @override
  String get mojiDozingReconnect =>
      'Moji дрімає, поки відновлюється мовний зв\'язок.';

  @override
  String get mojiSleepingTapWake => 'Moji спить. Торкнись, щоб розбудити.';

  @override
  String get mojiAwakeReady => 'Moji прокинувся і готовий!';

  @override
  String get wardrobeTitle => 'Гардероб';

  @override
  String get slotHat => 'Капелюх';

  @override
  String get slotNeck => 'Шия';

  @override
  String get slotFace => 'Обличчя';

  @override
  String get bodyTailColor => 'Колір тіла й хвоста';

  @override
  String get eyeColor => 'Колір очей';

  @override
  String get eyeStyleSolid => 'Однотонні';

  @override
  String get eyeStyleOddEyed => 'Різні очі';

  @override
  String get leftEye => 'Ліве око';

  @override
  String get rightEye => 'Праве око';

  @override
  String get colorLabel => 'Колір';

  @override
  String get scenarioObjectives => 'Цілі';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'Пройдено';

  @override
  String get scenarioBonusLabel => 'Бонус';

  @override
  String get scenarioCompleteTitle => 'Сценарій пройдено!';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '$done з $total цілей';
  }

  @override
  String get scenarioFirstClear => 'Перше проходження!';

  @override
  String get scenarioReplayNote =>
      'Нагорода за повтор — перше проходження дає більше.';

  @override
  String get scenarioContinue => 'Продовжити';

  @override
  String get objCoffeeOrder => 'Замов напій';

  @override
  String get objCoffeeCustomize => 'Зміни своє замовлення';

  @override
  String get objCoffeePrice => 'Запитай, скільки коштує';

  @override
  String get objCoffeeSmallTalk => 'Поговори трохи з баристою';

  @override
  String get objInterviewGreet => 'Представся';

  @override
  String get objInterviewExperience => 'Розкажи про свій досвід';

  @override
  String get objInterviewStrength => 'Поясни, чому ти підходиш';

  @override
  String get objInterviewAsk => 'Задай питання про посаду';

  @override
  String get objDirectionsAsk => 'Запитай, як кудись дістатися';

  @override
  String get objDirectionsClarify =>
      'Попроси повторити або говорити повільніше';

  @override
  String get objDirectionsDistance => 'Дізнайся, як далеко це';

  @override
  String get objDirectionsThank => 'Належно подякуй';

  @override
  String get objDoctorSymptom => 'Опиши свої симптоми';

  @override
  String get objDoctorDuration => 'Скажи, як давно це триває';

  @override
  String get objDoctorQuestion => 'Запитай, що тобі робити';

  @override
  String get objDoctorAllergy => 'Згадай алергію або ліки';

  @override
  String get objShoppingFind => 'Запитай, де лежить товар';

  @override
  String get objShoppingSize => 'Запитай про розмір, колір або як сидить';

  @override
  String get objShoppingPrice => 'Запитай ціну';

  @override
  String get objShoppingPay => 'Оплати покупку';

  @override
  String get objRestaurantTable => 'Попроси столик';

  @override
  String get objRestaurantOrder => 'Замов їжу';

  @override
  String get objRestaurantDrink => 'Замов щось випити';

  @override
  String get objRestaurantBill => 'Попроси рахунок';

  @override
  String get notificationsTitle => 'Сповіщення';

  @override
  String get notificationsEnable => 'Нагадувати про Моджі';

  @override
  String get notificationsDesc =>
      'Моджі повідомить, коли ти йому потрібен, коли час повторювати і коли готова щоденна нагорода.';

  @override
  String get notificationsBlocked =>
      'Сповіщення вимкнено в налаштуваннях пристрою.';

  @override
  String get notifPetChannelName => 'Моджі потребує тебе';

  @override
  String get notifPetChannelDesc =>
      'Нагадування, коли улюбленець голодний або сумує';

  @override
  String get notifReviewChannelName => 'Нагадування про повторення';

  @override
  String get notifReviewChannelDesc => 'Нагадування, коли слова час повторити';

  @override
  String get notifRewardChannelName => 'Щоденна нагорода';

  @override
  String get notifRewardChannelDesc =>
      'Нагадування, коли готова щоденна нагорода';

  @override
  String get notifPetHungryTitle => 'Моджі зголоднів';

  @override
  String get notifPetHungryBody =>
      'Твоєму улюбленцю зараз дуже не завадив би перекус.';

  @override
  String get notifPetSadTitle => 'Моджі сумує за тобою';

  @override
  String get notifPetSadBody => 'Без тебе стало тихо. Зазирнеш привітатися?';

  @override
  String get notifReviewTitle => 'Час повторити';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова чекають на тебе.',
      many: '$count слів чекають на тебе.',
      few: '$count слова чекають на тебе.',
      one: '$count слово чекає на тебе.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'Твоя щоденна нагорода готова';

  @override
  String get notifRewardBody => 'У Моджі дещо є для тебе. Заходь забрати!';

  @override
  String get careTitle => 'Як справи у Моджі?';

  @override
  String get careStatFullness => 'Ситість';

  @override
  String get careStatHappiness => 'Настрій';

  @override
  String get careStatHealth => 'Здоровʼя';

  @override
  String get careAllWell => 'У Моджі все чудово.';

  @override
  String get careNeedHungry => 'Моджі голодний';

  @override
  String get careNeedLonely => 'Моджі засумував';

  @override
  String get careNeedSick => 'Моджі хворіє';

  @override
  String get careSickPenalty =>
      'Поки Моджі хворіє, увесь досвід і монети зменшуються вдвічі.';

  @override
  String get careFeedTitle => 'Погодувати Моджі';

  @override
  String get careNoFood => 'Їжа скінчилася. Загляни до магазину.';

  @override
  String get careGoToShop => 'До магазину';

  @override
  String get carePlay => 'Погладити Моджі';

  @override
  String get carePlayCooldown => 'Моджі поки досить пестощів.';

  @override
  String get careClose => 'Закрити';

  @override
  String careFedItem(String item) {
    return 'Моджі зʼїв: $item.';
  }

  @override
  String careCurrentFullness(int value) {
    return 'Ситість зараз: $value%';
  }

  @override
  String get scenarioSickPenalty => 'Моджі хворіє — нагороди вдвічі менші';

  @override
  String get careDragToFeed => 'Перетягни на Моджі, щоб погодувати';
}
