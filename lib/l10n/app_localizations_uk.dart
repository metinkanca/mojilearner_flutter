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
  String get quizDesc => 'Перевір свої знання.';

  @override
  String get scenarios => 'Місто';

  @override
  String get scenariosDesc => 'Практикуй реальні розмови.';

  @override
  String get townSchool => 'Школа';

  @override
  String get townTab => 'Місто';

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
  String get shopItemDonutName => 'Пончик';

  @override
  String get shopItemDonutDescription => 'Солодкий і липкий.';

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
  String get sceneryTitle => 'Пейзаж';

  @override
  String get shopItemBgMeadowName => 'Лука';

  @override
  String get sceneInUse => 'Використовується';

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
  String get mojiSleepNight =>
      'Тсс... Модзі спить. Торкнися Модзі, щоб розбудити.';

  @override
  String get mojiWakeSuccess =>
      'Позіх... Модзі вже прокинувся! Давай практикуватися!';

  @override
  String mojiAwakeFor(int minutes) {
    return 'Не спить ще $minutes хв';
  }

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
  String get characterRabbit => 'Кролик';

  @override
  String get characterHamster => 'Хом\'як';

  @override
  String get characterParrot => 'Папуга';

  @override
  String get characterFox => 'Лисиця';

  @override
  String get characterRaccoon => 'Єнот';

  @override
  String get characterRedPanda => 'Червона панда';

  @override
  String get characterSkunk => 'Скунс';

  @override
  String get characterOtter => 'Видра';

  @override
  String get characterBeaver => 'Бобер';

  @override
  String get characterSquirrel => 'Білка';

  @override
  String get characterChinchilla => 'Шиншила';

  @override
  String get characterMouse => 'Миша';

  @override
  String get characterHedgehog => 'Їжак';

  @override
  String get characterBat => 'Кажан';

  @override
  String get characterFennec => 'Фенек';

  @override
  String get characterKoala => 'Коала';

  @override
  String get characterWombat => 'Вомбат';

  @override
  String get characterPanda => 'Панда';

  @override
  String get characterSloth => 'Лінивець';

  @override
  String get characterCapybara => 'Капібара';

  @override
  String get characterPiglet => 'Порося';

  @override
  String get characterSeal => 'Тюлень';

  @override
  String get characterPenguin => 'Пінгвін';

  @override
  String get characterFrog => 'Жаба';

  @override
  String get characterAxolotl => 'Аксолотль';

  @override
  String get characterGecko => 'Гекон';

  @override
  String get characterChameleon => 'Хамелеон';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Moji дрімає, поки відновлюється мовний зв\'язок. Спробуй ще раз трохи згодом.';

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
  String get beakColor => 'Колір дзьоба';

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
  String get scenarioFinish => 'Завершити';

  @override
  String get scenarioFinishTitle => 'Завершити сцену?';

  @override
  String get scenarioFinishBody =>
      'Деякі цілі ще не виконані. Якщо завершити зараз, нагорода буде частковою, а сценарій залишиться незавершеним — зможеш пройти його як слід пізніше.';

  @override
  String get scenarioFinishConfirm => 'Усе одно завершити';

  @override
  String get scenarioFinishCancel => 'Продовжити розмову';

  @override
  String get scenarioPartialTitle => 'Сцену завершено';

  @override
  String get scenarioPartialNote =>
      'Часткова нагорода — виконай усі цілі, щоб отримати повну.';

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
  String get playCatch => 'Пограти в м\'яч';

  @override
  String get playCatchAgain => 'Зіграти ще';

  @override
  String get playToyChest => 'Скриня з іграшками';

  @override
  String get playBubbleBath => 'Ванна з бульбашками';

  @override
  String get playPounce => 'Злови крота';

  @override
  String get playPondHop => 'Стрибки ставком';

  @override
  String get playFetchWords => 'Принеси слова';

  @override
  String get playNeedsWords => 'Вивчи ще кілька слів, щоб грати';

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

  @override
  String get bondStageCurious => 'Допитливий';

  @override
  String get bondStageFriendly => 'Дружній';

  @override
  String get bondStageAttached => 'Прив\'язаний';

  @override
  String get bondStageDevoted => 'Відданий';

  @override
  String get bondStageInseparable => 'Нерозлучні';

  @override
  String get bondMissesYou => 'Моджі сумує за тобою';

  @override
  String get bondLonely => 'Моджі давно на тебе чекає';

  @override
  String get aiLimitQuizTitle => 'Сьогоднішні ШІ-тести вичерпано';

  @override
  String get aiLimitMessageTitle => 'Сьогоднішні ШІ-повідомлення вичерпано';

  @override
  String aiLimitUsage(int used, int total) {
    return 'Використано $used із $total сьогодні';
  }

  @override
  String get aiLimitResets => 'Твій ліміт повернеться завтра.';

  @override
  String get aiLimitReviewOpen =>
      'Повторенню не потрібен наставник — твої картки завжди тут.';

  @override
  String get aiLimitQuizOpen => 'Тести з твоїх власних слів все ще доступні.';

  @override
  String get aiLimitWatchAd => 'Переглянь рекламу заради ще одного';

  @override
  String get aiLimitGoPlus => 'Отримати Mimikin Plus';

  @override
  String get premiumColumnFree => 'Безкоштовно';

  @override
  String get premiumColumnPlus => 'Plus';

  @override
  String get premiumRowQuizzes => 'ШІ-тестів на день';

  @override
  String get premiumRowMessages => 'ШІ-повідомлень на день';

  @override
  String get premiumRowAds => 'Міжсторінкова реклама';

  @override
  String get premiumValueShown => 'Показується';

  @override
  String get premiumValueNone => 'Немає';

  @override
  String get premiumRowRollover => 'Невикористані тести';

  @override
  String get premiumValueExpire => 'Згорають';

  @override
  String get premiumValueRollOver => 'Переносяться';

  @override
  String get premiumRowPetStats => 'Стан улюбленця';

  @override
  String get premiumValueDecay => 'Падає';

  @override
  String get premiumValueDecaySlower => 'Падає повільніше';

  @override
  String get premiumComingSoon => 'Підписки ще не відкриті.';

  @override
  String get premiumActive => 'Mimikin Plus активний.';

  @override
  String get premiumRestore => 'Відновити покупку';

  @override
  String get premiumRestoreDone => 'На цьому акаунті немає чого відновлювати.';

  @override
  String get premiumPurchasePending => 'Завершення в магазині…';

  @override
  String get categoryStyle => 'Стиль';

  @override
  String get accessoryDescription => 'Дрібничка для Моджі.';

  @override
  String accessoryUnlocksAt(String stage) {
    return 'Відкриється на етапі $stage';
  }

  @override
  String get accessoryEarnedNotSold => 'Заслуговується, а не купується';

  @override
  String get accessoryCapName => 'Кепка';

  @override
  String get accessoryTopHatName => 'Циліндр';

  @override
  String get accessoryCowboyHatName => 'Ковбойський капелюх';

  @override
  String get accessoryCrownName => 'Корона';

  @override
  String get accessoryPartyHatName => 'Святковий ковпак';

  @override
  String get accessoryBowTieName => 'Метелик';

  @override
  String get accessoryNecklaceName => 'Намисто';

  @override
  String get accessoryMustacheName => 'Вуса';

  @override
  String get accessoryBeanieName => 'Шапка';

  @override
  String get accessoryMortarboardName => 'Академічна шапочка';

  @override
  String get accessoryCollarName => 'Нашийник із дзвіночком';

  @override
  String get accessoryGlassesName => 'Окуляри';

  @override
  String get accessorySunglassesName => 'Темні окуляри';

  @override
  String get accessoryMaskName => 'Карнавальна маска';

  @override
  String get accessoryMedalName => 'Медаль';

  @override
  String get accessoryScarfName => 'Шарф';

  @override
  String get accessoryHeadphonesName => 'Навушники';

  @override
  String get accessoryWizardHatName => 'Капелюх чарівника';

  @override
  String get accessoryFlowerCrownName => 'Вінок із квітів';

  @override
  String get onboardingLanguageQuestion => 'Якою мовою ти розмовляєш?';

  @override
  String get onboardingLanguageConfirm => 'Продовжити';

  @override
  String get onboardingPetQuestion => 'Кого ти забереш додому?';

  @override
  String get onboardingPetConfirm => 'Обрати';

  @override
  String get onboardingLoginTitle => 'Збережи улюбленця';

  @override
  String get onboardingLoginGoogle => 'Продовжити з Google';

  @override
  String get onboardingLoginEmail => 'Продовжити поштою';

  @override
  String get onboardingLoginSkip => 'Можливо, пізніше';

  @override
  String get onboardingLoginSubtitle => 'Увійди, щоб ніколи їх не втратити.';

  @override
  String get accountEmailLabel => 'Пошта';

  @override
  String get accountPasswordLabel => 'Пароль';

  @override
  String get accountContinueAction => 'Продовжити';

  @override
  String get accountConflictTitle => 'Два улюбленці';

  @override
  String accountConflictBody(String email) {
    return 'У $email вже є улюбленець, і в цього телефона теж. Лишити можна тільки одного.';
  }

  @override
  String get accountConflictKeepThisDevice =>
      'Лишити улюбленця з цього телефона';

  @override
  String get accountConflictUseSaved => 'Взяти збереженого улюбленця';

  @override
  String get accountErrorInvalidEmail => 'Це недійсна адреса пошти.';

  @override
  String get accountErrorWeakPassword => 'Використай щонайменше 6 символів.';

  @override
  String get accountErrorSignIn =>
      'Не вдалося увійти. Перевір дані та спробуй ще раз.';

  @override
  String get adsFreeCoins => 'Безкоштовні монети';

  @override
  String adsWatchForCoins(int coins) {
    return 'Переглянь відео за +$coins';
  }

  @override
  String adsLeftToday(int remaining, int total) {
    return 'Сьогодні лишилось $remaining з $total';
  }

  @override
  String get adsNoneLeftToday => 'На сьогодні все';

  @override
  String get adsNotReady => 'Зараз немає доступних відео';

  @override
  String adsEarnedCoins(int coins) {
    return '+$coins монет!';
  }

  @override
  String get privacyRedactedNotice =>
      'Особисті дані приховано перед надсиланням.';

  @override
  String quizQuestionCounter(int current, int total) {
    return 'ПИТАННЯ $current/$total';
  }

  @override
  String get quizPreparing => 'ПІДГОТОВКА...';

  @override
  String get quizPickAnswer => 'Обери правильну відповідь';

  @override
  String get quizWellDone => 'Чудово!';

  @override
  String get quizEncouragement => 'У тебе вийде!';

  @override
  String petTutorialWelcome(String name) {
    return 'Приємно познайомитися, $name! Вчімося разом.';
  }

  @override
  String get tutorialOfferTitle => 'ПОКАЗАТИ, ЩО ДЕ?';

  @override
  String get tutorialWatch => 'ПОКАЗАТИ';

  @override
  String get tutorialSkip => 'ПРОПУСТИТИ';

  @override
  String get tutorialNext => 'ДАЛІ';

  @override
  String get tutorialBack => 'НАЗАД';

  @override
  String get tutorialDone => 'ГОТОВО';

  @override
  String get tutorialReplay => 'Показати навчання знову';

  @override
  String get tutorialOfferHome =>
      'Показати коротко, що де на головному екрані?';

  @override
  String get tutorialOfferQuiz => 'Твій перший квіз. Показати коротко?';

  @override
  String get tutorialOfferChat => 'Твій перший чат. Показати коротко?';

  @override
  String get tutorialOfferShop =>
      'Твій перший візит до крамниці. Показати коротко?';

  @override
  String get tutorialOfferProfile => 'Показати коротко, що де у профілі?';

  @override
  String get tutorialOfferReview => 'Твоє перше повторення. Показати коротко?';

  @override
  String get tutorialHomePet =>
      'Це Моджі. Торкнись його або проведи пальцем по голові, щоб почухати.';

  @override
  String get tutorialHomeLevel =>
      'Твій рівень і досвід. Торкнись, щоб побачити, що відкриють наступні рівні.';

  @override
  String get tutorialHomeFeed =>
      'Твоя їжа. Обери смаколик і перетягни його на Моджі.';

  @override
  String get tutorialHomeCare =>
      'З\'являється, коли Моджі щось потрібно. Торкнись і подивись.';

  @override
  String get tutorialHomeReview =>
      'Навчання: повтори слова, яким настав час, і поглянь ще раз на свої помилки.';

  @override
  String get tutorialHomeSettings =>
      'Налаштування: піксельний шрифт, нагадування та повтор цих підказок.';

  @override
  String get tutorialNavTown =>
      'Місто: заходь до будівлі, щоб потренувати розмову, або завітай до школи на квіз.';

  @override
  String get tutorialNavChat => 'Чати: довші розмови й рольові сценарії.';

  @override
  String get tutorialNavShop =>
      'Крамниця: витрачай монети на їжу, вбрання та нові світи.';

  @override
  String get tutorialNavProfile =>
      'Профіль: твоя статистика, мови й обліковий запис.';

  @override
  String get tutorialQuizHeader =>
      'Твій рівень і кнопка паузи, якщо треба спинитись.';

  @override
  String get tutorialQuizQuestion =>
      'Питання. Позначка згори каже, що саме перевіряється.';

  @override
  String get tutorialQuizOptions =>
      'Обери відповідь. Хибні зберігаються, щоб повторити їх пізніше.';

  @override
  String get tutorialQuizContinue => 'Рухайся далі, щойно відповіси.';

  @override
  String get tutorialChatMenu =>
      'Минулі чати й рольові сценарії — за цією кнопкою.';

  @override
  String get tutorialChatMessages =>
      'Ваша розмова. Помилки м\'яко виправляються дорогою.';

  @override
  String get tutorialChatInput =>
      'Пиши тут. Не хвилюйся, що вийде не ідеально.';

  @override
  String get tutorialShopCoins =>
      'Твої монети. Ти заробляєш їх тренуванням і турботою про Моджі.';

  @override
  String get tutorialShopTabs =>
      'Відфільтруй за тим, що шукаєш: їжа, оздоблення чи вбрання.';

  @override
  String get tutorialShopGrid =>
      'Торкнись будь-чого, щоб купити. Їжа витрачається, решта лишається тобі.';

  @override
  String get tutorialShopFreeCoins =>
      'Скінчились монети? Переглянь короткий ролик і поповни запас.';

  @override
  String get tutorialProfileAvatar =>
      'Торкнись Моджі, щоб змінити його вигляд і гардероб.';

  @override
  String get tutorialProfileStats =>
      'Твій рівень і скільки лишилось до наступного.';

  @override
  String get tutorialProfileDaily =>
      'Заходь щодня по нагороду. Довші серії дають більше.';

  @override
  String get tutorialProfileLanguages =>
      'Якою мовою ти говориш і яку вчиш. І те, і те можна змінити будь-коли.';

  @override
  String get tutorialProfileAccount =>
      'Прив\'яжи обліковий запис, щоб Моджі пережив зміну телефона.';

  @override
  String get tutorialReviewCard =>
      'Спробуй пригадати відповідь, потім торкнись картки й перевір.';

  @override
  String get tutorialReviewGrades =>
      'Покажи відповідь і скажи, як пішло. Складні картки повернуться раніше.';

  @override
  String get tutorialReviewCount => 'Скільки карток лишилось у цьому підході.';

  @override
  String get seasonPassNotOnSale => 'Цей пропуск ще не продається.';

  @override
  String seasonPassBuy(String price) {
    return 'Купити $price';
  }

  @override
  String seasonPassClaim(int count) {
    return 'Забрати ($count)';
  }

  @override
  String get seasonPassClaiming => 'Отримання…';

  @override
  String seasonPassClaimedToast(int count) {
    return 'Отримано: $count';
  }

  @override
  String seasonPassTierOf(int tier, int total) {
    return 'Рівень $tier / $total';
  }

  @override
  String seasonPassTrackLength(int count, int xp) {
    return '$count предметів · $xp XP';
  }

  @override
  String get seasonPassComplete => 'Шлях пройдено.';

  @override
  String seasonPassXpToNext(int xp) {
    return '$xp XP до наступного предмета';
  }

  @override
  String seasonPassTierCost(int xp) {
    return '$xp XP';
  }

  @override
  String get seasonPassReady => 'Готово';

  @override
  String get seasonPassTierClaimed => 'Отримано';

  @override
  String get seasonPassTryOn => 'Приміряти';

  @override
  String get sceneAirfieldName => 'Виліт';

  @override
  String get sceneCozyRoomName => 'Затишна кімната';

  @override
  String get sceneEnchantedMeadowName => 'Чарівна галявина';

  @override
  String get sceneMushroomGladeName => 'Грибна галявина';

  @override
  String get scenePumpkinPatchName => 'Гарбузове поле';

  @override
  String get seasonPassScenePreviewOwned =>
      'Твій. Змінюй світи будь-коли в гардеробі.';

  @override
  String get seasonPassPreviewOwned => 'Твоє. Одягни в гардеробі.';

  @override
  String get seasonPassPreviewLocked => 'Ще не твоє — це лише погляд.';

  @override
  String get seasonPassPromise =>
      'Рівні рахують досвід, здобутий після купівлі пропуску, тож купити його пізніше нічого не коштує. Тут ніщо не згорає: досягнутий рівень лишається, а недосягнутий чекає на вас.';

  @override
  String seasonPassWaitingToClaim(int count) {
    return 'Чекають отримання: $count';
  }

  @override
  String get seasonPassEarnedByStudying => 'Заробляється навчанням';

  @override
  String get accessoryBandanaName => 'Бандана світанку';

  @override
  String get accessoryBandanaCloudName => 'Хмарна бандана';

  @override
  String get accessoryScarfDuskName => 'Присмерковий шарф';

  @override
  String get accessoryGogglesName => 'Льотні окуляри';

  @override
  String get accessoryGogglesBrassName => 'Латунні окуляри';

  @override
  String get accessoryBeanieDuskName => 'Присмеркова шапка';

  @override
  String get accessoryFlightCapName => 'Льотний шолом';

  @override
  String get accessoryFlightCapCloudName => 'Хмарний льотний шолом';

  @override
  String get accessoryCowboyHatCharcoalName => 'Вугільний ковбойський капелюх';

  @override
  String get accessoryFlightScarfName => 'Розмаяний шарф';

  @override
  String get accessoryPumpkinWitchName => 'Відьомський капелюх із гарбузом';

  @override
  String get accessoryDevilBandName => 'Обруч із чортівськими ріжками';

  @override
  String get accessoryGhostBandanaName => 'Бандана з привидом';

  @override
  String get accessoryBatChokerName => 'Чокер кажана';

  @override
  String get shopSectionTopUp => 'Поповнення';

  @override
  String get shopSectionPlus => 'Plus';

  @override
  String get shopSectionPass => 'Сезонний пропуск';

  @override
  String get shopSectionItems => 'Предмети';

  @override
  String get topUpTitle => 'Поповнення';

  @override
  String topUpCoins(int coins) {
    return '$coins монет';
  }

  @override
  String topUpBonus(int percent) {
    return '+$percent% монет';
  }

  @override
  String get topUpBestValue => 'Найвигідніше';

  @override
  String get topUpNotOpen => 'Набори монет ще не відкриті.';

  @override
  String topUpThanks(int coins) {
    return 'Додано монет: $coins.';
  }
}
