// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get header => '언어 설정';

  @override
  String get iSpeak => '사용 언어';

  @override
  String get imLearning => '학습 언어';

  @override
  String get currentSelection => '현재 선택:';

  @override
  String get level => '레벨';

  @override
  String get xp => '경험치';

  @override
  String get streak => '연속';

  @override
  String get audio => '봇 음성';

  @override
  String get designMojiBtn => 'Moji 디자인';

  @override
  String get quizDesc => '지식을 테스트하세요.';

  @override
  String get scenarios => '마을';

  @override
  String get scenariosDesc => '실제 대화를 연습하세요.';

  @override
  String get townSchool => '학교';

  @override
  String get placeCafe => '카페';

  @override
  String get placeTownHall => '시청';

  @override
  String get placeGazebo => '정자';

  @override
  String get placeHospital => '병원';

  @override
  String get placeShop => '가게';

  @override
  String get townTab => '마을';

  @override
  String get profile => '프로필';

  @override
  String get shop => '상점';

  @override
  String get mistakes => '실수';

  @override
  String get noMistakesYet => '아직 실수가 없습니다!';

  @override
  String get profileDesc => '통계 및 설정 보기.';

  @override
  String get voiceCall => '음성 통화';

  @override
  String get voiceCallDesc => '실시간 음성 연습.';

  @override
  String get practiceRealLife => '실전 연습';

  @override
  String get chooseSituation => '상황을 선택하세요';

  @override
  String get createYourOwn => '직접 만들기';

  @override
  String get startCustom => '커스텀 시나리오 시작';

  @override
  String get customPlaceholder => '예: 당신은 택시 운전사입니다...';

  @override
  String get orderingCoffee => '커피 주문';

  @override
  String get jobInterview => '면접';

  @override
  String get askingDirections => '길 묻기';

  @override
  String get atTheDoctor => '병원에서';

  @override
  String get shopping => '쇼핑';

  @override
  String get restaurant => '레스토랑';

  @override
  String get chats => '채팅';

  @override
  String get searchPlaceholder => '메시지 검색...';

  @override
  String get newChat => '새 채팅';

  @override
  String get noChats => '채팅 없음';

  @override
  String get startNewConversation => '새 대화 시작';

  @override
  String get cancel => '취소';

  @override
  String get typeMessage => '메시지 입력...';

  @override
  String get designMoji => 'Moji 디자인';

  @override
  String get fullCustomization => '전체 맞춤 설정';

  @override
  String get tapToChange => '탭하여 변경';

  @override
  String get mascotColor => '마스코트 색상';

  @override
  String get backgroundColor => '배경 색상';

  @override
  String get faceExpressions => '얼굴 표정';

  @override
  String get personalityFaces => '성격 및 얼굴';

  @override
  String get selectFaces => '얼굴을 선택하세요.';

  @override
  String get locked => '잠김';

  @override
  String unlockMessage(Object level) {
    return '레벨 $level 달성 시 잠금 해제!';
  }

  @override
  String get yourMistakes => '오답 노트';

  @override
  String get learnFromWrong => '틀린 문제 복습';

  @override
  String get all => '전체';

  @override
  String get grammar => '문법';

  @override
  String get grammarBreakdown => '문법 분석';

  @override
  String get close => '닫기';

  @override
  String get noGrammarAnalysis => '문법 분석을 이용할 수 없습니다.';

  @override
  String get vocabulary => '어휘';

  @override
  String get noMistakes => '오류가 없습니다!';

  @override
  String get yourAnswer => '당신의 답변';

  @override
  String get correctAnswer => '정답';

  @override
  String get explanation => '설명';

  @override
  String get story => '시나리오';

  @override
  String get drills => '오답';

  @override
  String get shopTitle => '상점';

  @override
  String get categoryAll => '전체';

  @override
  String get categoryFood => '음식';

  @override
  String get categoryDecor => '장식';

  @override
  String get hideOwnedCosmetics => '소유한 화장품 숨기기';

  @override
  String get noItems => '항목 없음';

  @override
  String get owned => '소유';

  @override
  String get alreadyOwned => '이미 소유';

  @override
  String get alreadyOwnedMessage => '이미 이 항목을 소유하고 있습니다!';

  @override
  String get quantity => '수량';

  @override
  String get totalPrice => '총 가격';

  @override
  String get notEnoughCoins => '코인 부족!';

  @override
  String get purchaseFailed => '구매 실패';

  @override
  String get notEnoughCoinsMessage => '코인이 충분하지 않습니다!';

  @override
  String get buy => '구매';

  @override
  String get tooPoor => '너무 가난함';

  @override
  String get ok => '확인';

  @override
  String get daily_reward => '일일 보상';

  @override
  String get claim_reward => '보상 받기';

  @override
  String day_streak(Object X) {
    return '$X일 연속';
  }

  @override
  String get come_back_tomorrow => '내일 다시 오세요!';

  @override
  String get keep_going => '계속 가세요!';

  @override
  String get reward_claimed => '보상 받음!';

  @override
  String amazing_streak(Object X) {
    return '놀라워요! $X일 연속!';
  }

  @override
  String get whatsYourName => '이름이 뭐예요?';

  @override
  String get enterYourName => '이름을 입력하세요';

  @override
  String get continueBtn => '계속';

  @override
  String get howWouldYouRate => '당신의 수준을';

  @override
  String get yourLevel => '어떻게 평가하세요?';

  @override
  String get beginner => '초급';

  @override
  String get intermediate => '중급';

  @override
  String get advanced => '고급';

  @override
  String get beginnerDesc => '이제 막 시작했습니다. 아는 단어가 거의 없습니다.';

  @override
  String get intermediateDesc => '기본적인 대화를 하고 간단한 글을 이해할 수 있습니다.';

  @override
  String get advancedDesc => '유창하거나 그에 가깝습니다. 복잡한 주제를 논의할 수 있습니다.';

  @override
  String get whichLanguage => '어떤 언어를';

  @override
  String get doYouWantToLearn => '배우고 싶으세요?';

  @override
  String get changeAnytime => '설정에서 언제든지 변경할 수 있습니다';

  @override
  String get dontWorryVerify => '걱정 마세요, 빠른 채팅으로 확인하겠습니다!';

  @override
  String get startAssessment => '평가 시작';

  @override
  String get chatAssessment => '챗 평가';

  @override
  String get typeYourAnswer => '답변을 입력하세요...';

  @override
  String get mojiIsTyping => '모지가 입력 중...';

  @override
  String get send => '보내기';

  @override
  String get calibrationComplete => '보정 완료!';

  @override
  String get basedOnYourAnswers => '답변에 따라 권장 시작 레벨은:';

  @override
  String get proficiencyLevel => '숙련도 레벨';

  @override
  String get shopItemAppleName => '사과';

  @override
  String get shopItemAppleDescription => '건강한 간식.';

  @override
  String get shopItemDonutName => '도넛';

  @override
  String get shopItemDonutDescription => '달콤하고 끈적해요.';

  @override
  String get shopItemPizzaName => '피자 슬라이스';

  @override
  String get shopItemPizzaDescription => '치즈와 푸짐한.';

  @override
  String get shopItemSushiName => '초밥 세트';

  @override
  String get shopItemSushiDescription => '프리미엄 생선.';

  @override
  String get shopItemCoffeeName => '에스프레소';

  @override
  String get shopItemCoffeeDescription => '빠른 에너지 부스트.';

  @override
  String get shopItemMedicineName => '약';

  @override
  String get shopItemMedicineDescription => '모지를 건강하게 돌봐줍니다.';

  @override
  String get review => '복습';

  @override
  String reviewDueCount(int count) {
    return '$count개 대기';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$total개 중 $current개';
  }

  @override
  String get reviewShowAnswer => '정답 보기';

  @override
  String get reviewGradeAgain => '다시';

  @override
  String get reviewGradeHard => '어려움';

  @override
  String get reviewGradeGood => '보통';

  @override
  String get reviewGradeEasy => '쉬움';

  @override
  String get reviewAllCaughtUp => '모두 끝났어요!';

  @override
  String get reviewNothingDue =>
      '지금은 복습할 것이 없어요. 대화하거나 퀴즈를 풀면 모지가 어려워하는 부분을 기억해요.';

  @override
  String get reviewSessionComplete => '복습 완료!';

  @override
  String reviewSessionSummary(int count) {
    return '$count개 복습함';
  }

  @override
  String get reviewDone => '완료';

  @override
  String get reviewCorrectionPrompt => '올바른 표현은?';

  @override
  String get reviewVocabularyPrompt => '무슨 뜻일까요?';

  @override
  String get sceneryTitle => '배경';

  @override
  String get shopItemBgMeadowName => '초원';

  @override
  String get sceneInUse => '사용 중';

  @override
  String get shopItemBgBlueName => '대양 파란색';

  @override
  String get shopItemBgBlueDescription => '진정하는 파란 분위기.';

  @override
  String get shopItemBgForestName => '숲 녹색';

  @override
  String get shopItemBgForestDescription => '자연스러운 느낌.';

  @override
  String get shopItemBgSunsetName => '석양 주황색';

  @override
  String get shopItemBgSunsetDescription => '따뜻하고 편안한.';

  @override
  String get shopItemBgGalaxyName => '은하 보라색';

  @override
  String get shopItemBgGalaxyDescription => '이 세상 밖의.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName 구매됨!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity 구매됨!';
  }

  @override
  String get mojiSleepNight => '쉿... Moji가 자고 있어요. Moji를 탭해서 깨워 주세요.';

  @override
  String get mojiWakeSuccess => '하암... Moji가 이제 깼어요! 연습해요!';

  @override
  String mojiAwakeFor(int minutes) {
    return '$minutes분 더 깨어 있음';
  }

  @override
  String get levelsScreenTitle => '레벨';

  @override
  String get levelStatusCurrent => '현재 레벨';

  @override
  String get levelStatusCompleted => '완료됨';

  @override
  String get levelRewardLabel => '보상';

  @override
  String get quizPausedTitle => '일시 중지됨';

  @override
  String get quizPausedPrompt => '계속하거나 종료하시겠습니까?';

  @override
  String get quizPlay => '재생';

  @override
  String get quizPause => '일시 중지';

  @override
  String get quizExit => '종료';

  @override
  String get weeklyProgressTitle => '주간 진행 상황';

  @override
  String dayLabel(int dayNum) {
    return '$dayNum일';
  }

  @override
  String get dailyRewardHint => '내일 돌아와서 일일 보상을 받으세요';

  @override
  String get resetAppButton => '재설정';

  @override
  String get resetAppTitle => '앱 재설정';

  @override
  String get resetAppWarning => '이렇게 하면 모든 진행 상황이 삭제됩니다.\n\n계속하시겠습니까?';

  @override
  String get resetAction => '재설정';

  @override
  String get resetSuccessMessage => '앱이 성공적으로 재설정되었습니다';

  @override
  String get selectYourCharacter => '캐릭터를 선택하세요';

  @override
  String get characterDog => '개';

  @override
  String get characterCat => '고양이';

  @override
  String get characterBird => '새';

  @override
  String get characterRabbit => '토끼';

  @override
  String get characterHamster => '햄스터';

  @override
  String get characterParrot => '앵무새';

  @override
  String get characterFox => '여우';

  @override
  String get characterRaccoon => '너구리';

  @override
  String get characterRedPanda => '레서판다';

  @override
  String get characterSkunk => '스컹크';

  @override
  String get characterOtter => '수달';

  @override
  String get characterBeaver => '비버';

  @override
  String get characterSquirrel => '다람쥐';

  @override
  String get characterChinchilla => '친칠라';

  @override
  String get characterMouse => '쥐';

  @override
  String get characterHedgehog => '고슴도치';

  @override
  String get characterBat => '박쥐';

  @override
  String get characterFennec => '페넥여우';

  @override
  String get characterKoala => '코알라';

  @override
  String get characterWombat => '웜뱃';

  @override
  String get characterPanda => '판다';

  @override
  String get characterSloth => '나무늘보';

  @override
  String get characterCapybara => '카피바라';

  @override
  String get characterPiglet => '아기돼지';

  @override
  String get characterSeal => '물범';

  @override
  String get characterPenguin => '펭귄';

  @override
  String get characterFrog => '개구리';

  @override
  String get characterAxolotl => '아홀로틀';

  @override
  String get characterGecko => '도마뱀붙이';

  @override
  String get characterChameleon => '카멜레온';

  @override
  String get aiUnavailableMessage =>
      'Zzz... 언어 연결이 복구되는 동안 Moji가 졸고 있어요. 잠시 후 다시 시도해 주세요.';

  @override
  String get wardrobeTitle => '옷장';

  @override
  String get slotHat => '모자';

  @override
  String get slotNeck => '목';

  @override
  String get slotFace => '얼굴';

  @override
  String get bodyTailColor => '몸통과 꼬리 색';

  @override
  String get eyeColor => '눈 색';

  @override
  String get beakColor => '부리 색';

  @override
  String get eyeStyleSolid => '단색';

  @override
  String get eyeStyleOddEyed => '오드아이';

  @override
  String get leftEye => '왼쪽 눈';

  @override
  String get rightEye => '오른쪽 눈';

  @override
  String get colorLabel => '색상';

  @override
  String get scenarioObjectives => '목표';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => '완료';

  @override
  String get scenarioBonusLabel => '보너스';

  @override
  String get scenarioCompleteTitle => '시나리오 완료!';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '목표 $total개 중 $done개';
  }

  @override
  String get scenarioFirstClear => '첫 완료!';

  @override
  String get scenarioReplayNote => '재도전 보상 — 첫 완료가 더 많이 줍니다.';

  @override
  String get scenarioContinue => '계속';

  @override
  String get scenarioFinish => '끝내기';

  @override
  String get scenarioFinishTitle => '장면을 끝낼까요?';

  @override
  String get scenarioFinishBody =>
      '아직 남은 목표가 있어요. 지금 끝내면 보상의 일부만 받고 시나리오는 미완료로 남아, 나중에 제대로 클리어할 수 있어요.';

  @override
  String get scenarioFinishConfirm => '그래도 끝내기';

  @override
  String get scenarioFinishCancel => '계속 대화하기';

  @override
  String get scenarioPartialTitle => '장면 종료';

  @override
  String get scenarioPartialNote => '부분 보상 — 모든 목표를 달성하면 전체 보상을 받아요.';

  @override
  String get objCoffeeOrder => '음료 주문하기';

  @override
  String get objCoffeeCustomize => '주문을 원하는 대로 바꾸기';

  @override
  String get objCoffeePrice => '가격을 물어보기';

  @override
  String get objCoffeeSmallTalk => '바리스타와 가벼운 대화 나누기';

  @override
  String get objInterviewGreet => '자기소개하기';

  @override
  String get objInterviewExperience => '경험을 설명하기';

  @override
  String get objInterviewStrength => '왜 적합한지 설명하기';

  @override
  String get objInterviewAsk => '그 자리에 대해 질문하기';

  @override
  String get objDirectionsAsk => '길을 물어보기';

  @override
  String get objDirectionsClarify => '다시 말해 달라거나 천천히 말해 달라고 하기';

  @override
  String get objDirectionsDistance => '얼마나 먼지 알아보기';

  @override
  String get objDirectionsThank => '제대로 감사 인사하기';

  @override
  String get objDoctorSymptom => '증상을 설명하기';

  @override
  String get objDoctorDuration => '얼마나 오래됐는지 말하기';

  @override
  String get objDoctorQuestion => '어떻게 해야 하는지 물어보기';

  @override
  String get objDoctorAllergy => '알레르기나 복용 중인 약을 말하기';

  @override
  String get objShoppingFind => '물건이 어디 있는지 물어보기';

  @override
  String get objShoppingSize => '사이즈나 색, 잘 맞는지 물어보기';

  @override
  String get objShoppingPrice => '가격을 물어보기';

  @override
  String get objShoppingPay => '결제하기';

  @override
  String get objRestaurantTable => '자리를 요청하기';

  @override
  String get objRestaurantOrder => '음식을 주문하기';

  @override
  String get objRestaurantDrink => '마실 것을 주문하기';

  @override
  String get objRestaurantBill => '계산서를 부탁하기';

  @override
  String get notificationsTitle => '알림';

  @override
  String get notificationsEnable => '모지 소식 알림 받기';

  @override
  String get notificationsDesc =>
      '모지가 당신을 필요로 할 때, 복습할 때, 일일 보상이 준비됐을 때 알려줍니다.';

  @override
  String get notificationsBlocked => '기기 설정에서 알림이 꺼져 있습니다.';

  @override
  String get notifPetChannelName => '모지가 당신을 필요로 해요';

  @override
  String get notifPetChannelDesc => '펫이 배고프거나 기분이 안 좋을 때 알림';

  @override
  String get notifReviewChannelName => '복습 알림';

  @override
  String get notifReviewChannelDesc => '복습할 단어가 있을 때 알림';

  @override
  String get notifRewardChannelName => '일일 보상';

  @override
  String get notifRewardChannelDesc => '일일 보상이 준비됐을 때 알림';

  @override
  String get notifPetHungryTitle => '모지가 배고파요';

  @override
  String get notifPetHungryBody => '펫이 지금 간식이 아주 필요해요.';

  @override
  String get notifPetSadTitle => '모지가 보고 싶어 해요';

  @override
  String get notifPetSadBody => '당신이 없어서 조용했어요. 인사하러 올래요?';

  @override
  String get notifReviewTitle => '복습할 시간이에요';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '단어 $count개가 기다리고 있어요.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => '일일 보상이 준비됐어요';

  @override
  String get notifRewardBody => '모지가 당신에게 줄 것이 있어요. 받으러 오세요!';

  @override
  String get careTitle => '모지는 어때요?';

  @override
  String get careStatFullness => '포만감';

  @override
  String get careStatHappiness => '행복도';

  @override
  String get careStatHealth => '건강';

  @override
  String get careAllWell => '모지는 아주 잘 지내요.';

  @override
  String get careNeedHungry => '모지가 배고파요';

  @override
  String get careNeedLonely => '모지가 기운이 없어요';

  @override
  String get careNeedSick => '모지가 아파요';

  @override
  String get careSickPenalty => '모지가 아픈 동안에는 모든 XP와 코인이 절반이 됩니다.';

  @override
  String get careFeedTitle => '모지에게 먹이 주기';

  @override
  String get careNoFood => '먹이가 없어요. 상점에서 채워 오세요.';

  @override
  String get careGoToShop => '상점으로';

  @override
  String get carePlay => '모지 쓰다듬기';

  @override
  String get carePlayCooldown => '모지는 지금은 충분히 예뻐함을 받았어요.';

  @override
  String get playCatch => '공 받기 놀이';

  @override
  String get playCatchAgain => '다시 하기';

  @override
  String get playToyChest => '장난감 상자';

  @override
  String get playBubbleBath => '거품 목욕';

  @override
  String get playPounce => '두더지 덮치기';

  @override
  String get playPondHop => '연못 건너기';

  @override
  String get playFetchWords => '단어 물어오기';

  @override
  String get playNeedsWords => '놀려면 단어를 조금 더 배워요';

  @override
  String get careClose => '닫기';

  @override
  String careFedItem(String item) {
    return '모지가 $item을(를) 먹었어요.';
  }

  @override
  String careCurrentFullness(int value) {
    return '현재 포만감: $value%';
  }

  @override
  String get scenarioSickPenalty => '모지가 아픔 — 보상 절반';

  @override
  String get careDragToFeed => '모지에게 끌어다 놓아 먹이기';

  @override
  String get bondStageCurious => '호기심';

  @override
  String get bondStageFriendly => '친근함';

  @override
  String get bondStageAttached => '애착';

  @override
  String get bondStageDevoted => '헌신';

  @override
  String get bondStageInseparable => '단짝';

  @override
  String get bondMissesYou => '모지가 보고 싶어 해요';

  @override
  String get bondLonely => '모지가 오랫동안 기다렸어요';

  @override
  String get aiLimitQuizTitle => '오늘의 AI 퀴즈를 모두 사용했어요';

  @override
  String get aiLimitMessageTitle => '오늘의 AI 메시지를 모두 사용했어요';

  @override
  String aiLimitUsage(int used, int total) {
    return '오늘 $total개 중 $used개 사용';
  }

  @override
  String get aiLimitResets => '한도는 내일 다시 채워져요.';

  @override
  String get aiLimitReviewOpen => '복습은 선생님이 필요 없어요 — 카드는 언제나 있어요.';

  @override
  String get aiLimitQuizOpen => '직접 모은 단어로 만든 퀴즈는 그대로 있어요.';

  @override
  String get aiLimitWatchAd => '광고 보고 하나 더 받기';

  @override
  String get aiLimitGoPlus => 'Mimikin Plus 받기';

  @override
  String get premiumColumnFree => '무료';

  @override
  String get premiumColumnPlus => 'Plus';

  @override
  String get premiumRowQuizzes => '하루 AI 퀴즈';

  @override
  String get premiumRowMessages => '하루 AI 메시지';

  @override
  String get premiumRowAds => '전면 광고';

  @override
  String get premiumValueShown => '표시됨';

  @override
  String get premiumValueNone => '없음';

  @override
  String get premiumRowRollover => '사용하지 않은 퀴즈';

  @override
  String get premiumValueExpire => '소멸';

  @override
  String get premiumValueRollOver => '이월';

  @override
  String get premiumRowPetStats => '펫 상태';

  @override
  String get premiumValueDecay => '감소';

  @override
  String get premiumValueDecaySlower => '천천히 감소';

  @override
  String get premiumComingSoon => '구독은 아직 열리지 않았어요.';

  @override
  String get premiumActive => 'Mimikin Plus가 활성화되어 있어요.';

  @override
  String get premiumRestore => '구매 복원';

  @override
  String get premiumRestoreDone => '이 계정에 복원할 항목이 없어요.';

  @override
  String get premiumPurchasePending => '스토어에서 마무리하는 중…';

  @override
  String get categoryStyle => '스타일';

  @override
  String get accessoryDescription => '모지가 쓸 작은 소품이에요.';

  @override
  String accessoryUnlocksAt(String stage) {
    return '$stage에서 잠금 해제';
  }

  @override
  String get accessoryEarnedNotSold => '살 수 없어요, 유대로 얻어요';

  @override
  String get accessoryCapName => '모자';

  @override
  String get accessoryTopHatName => '실크햇';

  @override
  String get accessoryCowboyHatName => '카우보이 모자';

  @override
  String get accessoryCrownName => '왕관';

  @override
  String get accessoryPartyHatName => '파티 모자';

  @override
  String get accessoryBowTieName => '나비넥타이';

  @override
  String get accessoryNecklaceName => '목걸이';

  @override
  String get accessoryMustacheName => '콧수염';

  @override
  String get accessoryBeanieName => '비니';

  @override
  String get accessoryMortarboardName => '학사모';

  @override
  String get accessoryCollarName => '방울 목걸이';

  @override
  String get accessoryGlassesName => '안경';

  @override
  String get accessorySunglassesName => '선글라스';

  @override
  String get accessoryMaskName => '가면';

  @override
  String get accessoryMedalName => '메달';

  @override
  String get accessoryScarfName => '목도리';

  @override
  String get accessoryHeadphonesName => '헤드폰';

  @override
  String get accessoryWizardHatName => '마법사 모자';

  @override
  String get accessoryFlowerCrownName => '꽃 왕관';

  @override
  String get onboardingLanguageQuestion => '어떤 언어를 사용하나요?';

  @override
  String get onboardingLanguageConfirm => '계속하기';

  @override
  String get onboardingPetQuestion => '누구를 데려갈까요?';

  @override
  String get onboardingPetConfirm => '선택';

  @override
  String get onboardingLoginTitle => '반려동물 저장하기';

  @override
  String get onboardingLoginGoogle => 'Google로 계속하기';

  @override
  String get onboardingLoginEmail => '이메일로 계속하기';

  @override
  String get onboardingLoginSkip => '나중에';

  @override
  String get onboardingLoginSubtitle => '로그인하면 절대 잃어버리지 않아요.';

  @override
  String get accountEmailLabel => '이메일';

  @override
  String get accountPasswordLabel => '비밀번호';

  @override
  String get accountContinueAction => '계속하기';

  @override
  String get accountConflictTitle => '두 마리';

  @override
  String accountConflictBody(String email) {
    return '$email 계정에도 이 휴대폰에도 반려동물이 있어요. 한 마리만 남길 수 있어요.';
  }

  @override
  String get accountConflictKeepThisDevice => '이 휴대폰의 반려동물 남기기';

  @override
  String get accountConflictUseSaved => '저장된 반려동물 사용하기';

  @override
  String get accountErrorInvalidEmail => '올바른 이메일 주소가 아니에요.';

  @override
  String get accountErrorWeakPassword => '6자 이상 입력해 주세요.';

  @override
  String get accountErrorSignIn => '로그인하지 못했어요. 정보를 확인하고 다시 시도해 주세요.';

  @override
  String get adsFreeCoins => '무료 코인';

  @override
  String adsWatchForCoins(int coins) {
    return '동영상 보고 +$coins';
  }

  @override
  String adsLeftToday(int remaining, int total) {
    return '오늘 $total개 중 $remaining개 남음';
  }

  @override
  String get adsNoneLeftToday => '오늘은 여기까지';

  @override
  String get adsNotReady => '지금은 동영상이 없습니다';

  @override
  String adsEarnedCoins(int coins) {
    return '+$coins 코인!';
  }

  @override
  String get privacyRedactedNotice => '개인 정보는 보내기 전에 숨겨졌습니다.';

  @override
  String quizQuestionCounter(int current, int total) {
    return '문제 $current/$total';
  }

  @override
  String get quizPreparing => '준비 중...';

  @override
  String get quizPickAnswer => '알맞은 답을 고르세요';

  @override
  String get quizWellDone => '잘했어요!';

  @override
  String get quizEncouragement => '할 수 있어요!';

  @override
  String petTutorialWelcome(String name) {
    return '만나서 반가워요, $name! 같이 배워요.';
  }

  @override
  String get tutorialOfferTitle => '둘러볼까요?';

  @override
  String get tutorialWatch => '보여주세요';

  @override
  String get tutorialSkip => '건너뛰기';

  @override
  String get tutorialNext => '다음';

  @override
  String get tutorialBack => '뒤로';

  @override
  String get tutorialDone => '완료';

  @override
  String get tutorialReplay => '튜토리얼 다시 보기';

  @override
  String get tutorialOfferHome => '홈 화면을 간단히 둘러볼까요?';

  @override
  String get tutorialOfferQuiz => '첫 퀴즈예요. 간단히 둘러볼까요?';

  @override
  String get tutorialOfferChat => '첫 대화예요. 간단히 둘러볼까요?';

  @override
  String get tutorialOfferShop => '상점에 처음 오셨네요. 간단히 둘러볼까요?';

  @override
  String get tutorialOfferProfile => '프로필을 간단히 둘러볼까요?';

  @override
  String get tutorialOfferReview => '첫 복습이에요. 간단히 둘러볼까요?';

  @override
  String get tutorialHomePet => '이 아이가 모지예요. 톡 누르거나 머리를 옆으로 쓸어 쓰다듬어 주세요.';

  @override
  String get tutorialHomeLevel => '레벨과 경험치예요. 누르면 다음 레벨에서 뭐가 열리는지 볼 수 있어요.';

  @override
  String get tutorialHomeFeed => '가진 먹이예요. 간식을 골라 모지에게 끌어다 놓으세요.';

  @override
  String get tutorialHomeCare => '모지에게 뭔가 필요할 때 나타나요. 눌러서 살펴보세요.';

  @override
  String get tutorialHomeReview => '공부: 복습할 단어를 다시 보고, 틀린 것도 돌아봐요.';

  @override
  String get tutorialHomeSettings => '설정: 픽셀 글꼴, 알림, 그리고 이 안내 다시 보기예요.';

  @override
  String get tutorialNavTown => '마을: 건물에 들어가 대화를 연습하거나, 학교에서 퀴즈를 풀어요.';

  @override
  String get tutorialNavChat => '대화: 더 긴 이야기와 역할극 시나리오예요.';

  @override
  String get tutorialNavShop => '상점: 코인으로 먹이, 스타일, 새 세계를 사요.';

  @override
  String get tutorialNavProfile => '프로필: 기록, 언어, 계정이에요.';

  @override
  String get tutorialQuizHeader => '레벨과, 멈춰야 할 때 쓰는 일시정지 버튼이에요.';

  @override
  String get tutorialQuizQuestion => '문제예요. 위의 배지가 무엇을 묻는지 알려줘요.';

  @override
  String get tutorialQuizOptions => '답을 고르세요. 틀린 답은 저장돼서 나중에 복습할 수 있어요.';

  @override
  String get tutorialQuizContinue => '답했으면 다음으로 넘어가세요.';

  @override
  String get tutorialChatMenu => '지난 대화와 역할극은 이 버튼 뒤에 있어요.';

  @override
  String get tutorialChatMessages => '둘의 대화예요. 틀린 곳은 가는 길에 부드럽게 고쳐줘요.';

  @override
  String get tutorialChatInput => '여기에 쓰세요. 완벽하지 않아도 괜찮아요.';

  @override
  String get tutorialShopCoins => '코인이에요. 연습하고 모지를 돌보면 모여요.';

  @override
  String get tutorialShopTabs => '찾는 것으로 걸러 보세요: 먹이, 장식, 스타일.';

  @override
  String get tutorialShopGrid => '아무거나 눌러 사세요. 먹이는 소모되고 나머지는 계속 남아요.';

  @override
  String get tutorialShopFreeCoins => '코인이 떨어졌나요? 짧은 영상을 보고 채우세요.';

  @override
  String get tutorialProfileAvatar => '모지를 눌러 생김새와 옷을 바꿔 보세요.';

  @override
  String get tutorialProfileStats => '레벨과, 다음 레벨까지 얼마나 남았는지예요.';

  @override
  String get tutorialProfileDaily => '매일 돌아오면 보상이 있어요. 연속 기록이 길수록 많아져요.';

  @override
  String get tutorialProfileLanguages => '쓰는 말과 배우는 말이에요. 둘 다 언제든 바꿀 수 있어요.';

  @override
  String get tutorialProfileAccount => '계정을 연결하면 휴대폰을 바꿔도 모지가 남아요.';

  @override
  String get tutorialReviewCard => '답을 떠올려 본 뒤 카드를 눌러 확인하세요.';

  @override
  String get tutorialReviewGrades => '답을 보고 어땠는지 알려주세요. 어려웠던 카드는 더 일찍 돌아와요.';

  @override
  String get tutorialReviewCount => '이번 세션에 남은 카드 수예요.';

  @override
  String get seasonPassNotOnSale => '이 패스는 아직 판매하지 않습니다.';

  @override
  String seasonPassBuy(String price) {
    return '$price 구매';
  }

  @override
  String seasonPassClaim(int count) {
    return '받기 ($count)';
  }

  @override
  String get seasonPassClaiming => '받는 중…';

  @override
  String seasonPassClaimedToast(int count) {
    return '받음: $count';
  }

  @override
  String seasonPassTierOf(int tier, int total) {
    return '단계 $tier / $total';
  }

  @override
  String seasonPassTrackLength(int count, int xp) {
    return '$count개 · $xp XP';
  }

  @override
  String get seasonPassComplete => '트랙 완료.';

  @override
  String seasonPassXpToNext(int xp) {
    return '다음 아이템까지 $xp XP';
  }

  @override
  String seasonPassTierCost(int xp) {
    return '$xp XP';
  }

  @override
  String get seasonPassReady => '준비됨';

  @override
  String get seasonPassTierClaimed => '수령 완료';

  @override
  String get seasonPassTryOn => '입혀 보기';

  @override
  String get sceneAirfieldName => '출발';

  @override
  String get sceneCozyRoomName => '아늑한 방';

  @override
  String get sceneEnchantedMeadowName => '마법에 걸린 초원';

  @override
  String get sceneMushroomGladeName => '버섯 숲속 빈터';

  @override
  String get scenePumpkinPatchName => '호박밭';

  @override
  String get seasonPassScenePreviewOwned => '당신의 것입니다. 옷장에서 언제든 세계를 바꿀 수 있어요.';

  @override
  String get seasonPassPreviewOwned => '당신의 것입니다. 옷장에서 착용하세요.';

  @override
  String get seasonPassPreviewLocked => '아직 당신의 것이 아닙니다 — 미리 보기일 뿐입니다.';

  @override
  String get seasonPassPromise =>
      '단계는 패스를 구매한 뒤 얻은 XP로 채워지므로, 늦게 사도 손해가 없습니다. 여기서는 아무것도 만료되지 않습니다. 도달한 단계는 그대로 남고, 아직인 단계는 기다립니다.';

  @override
  String seasonPassWaitingToClaim(int count) {
    return '받을 항목: $count';
  }

  @override
  String get seasonPassEarnedByStudying => '학습으로 획득';

  @override
  String get accessoryBandanaName => '일출 반다나';

  @override
  String get accessoryBandanaCloudName => '구름 반다나';

  @override
  String get accessoryScarfDuskName => '황혼 목도리';

  @override
  String get accessoryGogglesName => '비행 고글';

  @override
  String get accessoryGogglesBrassName => '황동 고글';

  @override
  String get accessoryBeanieDuskName => '황혼 비니';

  @override
  String get accessoryFlightCapName => '비행 모자';

  @override
  String get accessoryFlightCapCloudName => '구름 비행 모자';

  @override
  String get accessoryCowboyHatCharcoalName => '차콜 카우보이 모자';

  @override
  String get accessoryFlightScarfName => '바람에 날리는 목도리';

  @override
  String get accessoryPumpkinWitchName => '호박 마녀 모자';

  @override
  String get accessoryDevilBandName => '악마 뿔 머리띠';

  @override
  String get accessoryGhostBandanaName => '유령 반다나';

  @override
  String get accessoryBatChokerName => '박쥐 초커';

  @override
  String get shopSectionTopUp => '코인 충전';

  @override
  String get shopSectionPlus => 'Plus';

  @override
  String get shopSectionPass => '시즌 패스';

  @override
  String get shopSectionItems => '아이템';

  @override
  String get topUpTitle => '코인 충전';

  @override
  String topUpCoins(int coins) {
    return '$coins 코인';
  }

  @override
  String topUpBonus(int percent) {
    return '코인 +$percent%';
  }

  @override
  String get topUpBestValue => '가장 이득';

  @override
  String get topUpNotOpen => '코인 팩은 아직 열리지 않았어요.';

  @override
  String topUpThanks(int coins) {
    return '$coins 코인을 넣었어요.';
  }

  @override
  String get deleteAccountButton => '계정 삭제';

  @override
  String get deleteAccountTitle => '계정을 삭제할까요?';

  @override
  String get deleteAccountWarning =>
      '이 휴대폰과 클라우드에서 펫, 진행 상황, 채팅, 계정이 영구적으로 삭제됩니다. 되돌릴 수 없습니다.';

  @override
  String get deleteAction => '삭제';

  @override
  String get deleteAccountDone => '계정과 데이터가 삭제되었습니다.';

  @override
  String get deleteAccountFailed => '계정을 삭제하지 못했습니다. 연결을 확인하고 다시 시도하세요.';

  @override
  String get privacyPolicyButton => '개인정보 처리방침';

  @override
  String get privacyPolicyOpenFailed => '링크를 열 수 없습니다.';

  @override
  String get reportReply => '이 답변 신고하기';

  @override
  String get reportReplyFailed => '이메일 앱을 열 수 없습니다.';
}
