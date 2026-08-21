// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get header => '言語設定';

  @override
  String get iSpeak => '私の言語';

  @override
  String get imLearning => '学習言語';

  @override
  String get currentSelection => '現在の選択:';

  @override
  String get level => 'レベル';

  @override
  String get xp => '経験値';

  @override
  String get streak => '連続日数';

  @override
  String get audio => 'ボット音声';

  @override
  String get designMojiBtn => 'Mojiをデザイン';

  @override
  String get quizMode => 'クイズ';

  @override
  String get quizDesc => '知識をテストしましょう。';

  @override
  String get scenarios => 'シナリオ';

  @override
  String get scenariosDesc => '実際の会話を練習します。';

  @override
  String get profile => 'プロフィール';

  @override
  String get shop => 'ショップ';

  @override
  String get mistakes => '間違い';

  @override
  String get noMistakesYet => 'まだ間違いはありません!';

  @override
  String get profileDesc => '統計と設定を表示。';

  @override
  String get voiceCall => '音声通話';

  @override
  String get voiceCallDesc => 'リアルタイムで会話練習。';

  @override
  String get practiceRealLife => '実践練習';

  @override
  String get chooseSituation => '状況を選んで練習';

  @override
  String get createYourOwn => 'オリジナル作成';

  @override
  String get startCustom => 'カスタムシナリオ開始';

  @override
  String get customPlaceholder => '例: あなたはタクシー運転手...';

  @override
  String get orderingCoffee => 'コーヒーを注文';

  @override
  String get jobInterview => '就職面接';

  @override
  String get askingDirections => '道を尋ねる';

  @override
  String get atTheDoctor => '医者にて';

  @override
  String get shopping => '買い物';

  @override
  String get restaurant => 'レストラン';

  @override
  String get chats => 'チャット';

  @override
  String get searchPlaceholder => 'メッセージ検索...';

  @override
  String get newChat => '新規チャット';

  @override
  String get noChats => 'チャットはまだありません';

  @override
  String get startNewConversation => '新しい会話を始める';

  @override
  String get blankChat => 'ブランクチャット';

  @override
  String get blankChatDesc => '文脈なしで開始';

  @override
  String get roleplayScenario => 'ロールプレイシナリオ';

  @override
  String get roleplayScenarioDesc => '特定の状況を練習';

  @override
  String get chooseChatType => 'チャットタイプ選択';

  @override
  String get cancel => 'キャンセル';

  @override
  String get typeMessage => 'メッセージを入力...';

  @override
  String get designMoji => 'Mojiデザイン';

  @override
  String get fullCustomization => '完全カスタマイズ';

  @override
  String get tapToChange => 'タップして変更';

  @override
  String get mascotColor => 'マスコット色';

  @override
  String get backgroundColor => '背景色';

  @override
  String get faceExpressions => '表情';

  @override
  String get personalityFaces => '性格と顔';

  @override
  String get selectFaces => '顔を選択してください。';

  @override
  String get locked => 'ロック中';

  @override
  String unlockMessage(Object level) {
    return 'レベル$levelで解除！';
  }

  @override
  String get yourMistakes => 'あなたの間違い';

  @override
  String get learnFromWrong => '間違いから学ぶ';

  @override
  String get all => 'すべて';

  @override
  String get grammar => '文法';

  @override
  String get grammarBreakdown => '文法分析';

  @override
  String get close => '閉じる';

  @override
  String get noGrammarAnalysis => '文法分析はありません。';

  @override
  String get vocabulary => '語彙';

  @override
  String get noMistakes => '間違いはありません！';

  @override
  String get yourAnswer => 'あなたの答え';

  @override
  String get correctAnswer => '正解';

  @override
  String get explanation => '解説';

  @override
  String get story => 'シナリオ';

  @override
  String get drills => '間違い';

  @override
  String get typeHere => 'ここに入力...';

  @override
  String get shopTitle => 'ショップ';

  @override
  String get categoryAll => 'すべて';

  @override
  String get categoryFood => '食べ物';

  @override
  String get categoryDecor => '装飾';

  @override
  String get hideOwnedCosmetics => '所有コスメを非表示';

  @override
  String get noItems => 'アイテムなし';

  @override
  String get owned => '所有済み';

  @override
  String get alreadyOwned => '既に所有';

  @override
  String get alreadyOwnedMessage => 'このアイテムは既に所有しています！';

  @override
  String get quantity => '数量';

  @override
  String get totalPrice => '合計金額';

  @override
  String get notEnoughCoins => 'コイン不足！';

  @override
  String get purchaseFailed => '購入失敗';

  @override
  String get notEnoughCoinsMessage => 'コインが足りません！';

  @override
  String get buy => '購入';

  @override
  String get tooPoor => '貧乏';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'デイリー報酬';

  @override
  String get claim_reward => '報酬を受け取る';

  @override
  String day_streak(Object X) {
    return '$X日連続';
  }

  @override
  String get come_back_tomorrow => 'また明日来てね！';

  @override
  String get streak_broken => 'おかえり！新しくスタート';

  @override
  String get keep_going => '続けよう！';

  @override
  String get reward_claimed => '報酬受け取り済み！';

  @override
  String amazing_streak(Object X) {
    return 'すごい！$X日連続！';
  }

  @override
  String get whatsYourName => 'お名前は?';

  @override
  String get enterYourName => '名前を入力してください';

  @override
  String get continueBtn => '続ける';

  @override
  String get howWouldYouRate => 'あなたのレベルは';

  @override
  String get yourLevel => 'どのくらい?';

  @override
  String get beginner => '初心者';

  @override
  String get intermediate => '中級';

  @override
  String get advanced => '上級';

  @override
  String get beginnerDesc => '初心者です。ほとんど語彙を知りません。';

  @override
  String get intermediateDesc => '基本的な会話ができ、簡単な文章を理解できます。';

  @override
  String get advancedDesc => '流暢または流暢に近いです。複雑なトピックを話せます。';

  @override
  String get whichLanguage => 'どの言語を';

  @override
  String get doYouWantToLearn => '学びたいですか？';

  @override
  String get changeAnytime => 'これはいつでも設定で変更できます';

  @override
  String get dontWorryVerify => '心配いりません、簡単なチャットで確認します！';

  @override
  String get startAssessment => '評価を開始';

  @override
  String get chatAssessment => 'チャット評価';

  @override
  String get typeYourAnswer => '答えを入力...';

  @override
  String get mojiIsTyping => 'モジは入力中...';

  @override
  String get send => '送信';

  @override
  String get calibrationComplete => 'キャリブレーション完了！';

  @override
  String get basedOnYourAnswers => 'あなたの回答に基づいて、推奨開始レベルは:';

  @override
  String get proficiencyLevel => '習熟度レベル';

  @override
  String get shopItemAppleName => 'Apple';

  @override
  String get shopItemAppleDescription => 'A healthy snack.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Buttery goodness.';

  @override
  String get shopItemPizzaName => 'ピザスライス';

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
  String get shopItemMedicineName => 'くすり';

  @override
  String get shopItemMedicineDescription => 'モジを元気にします。';

  @override
  String get review => '復習';

  @override
  String reviewDueCount(int count) {
    return '$count件';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get reviewShowAnswer => '答えを見る';

  @override
  String get reviewGradeAgain => 'もう一度';

  @override
  String get reviewGradeHard => '難しい';

  @override
  String get reviewGradeGood => 'ふつう';

  @override
  String get reviewGradeEasy => 'かんたん';

  @override
  String get reviewAllCaughtUp => 'すべて完了！';

  @override
  String get reviewNothingDue =>
      '今は復習するものがありません。チャットやクイズをすれば、モジがあなたの苦手を覚えてくれます。';

  @override
  String get reviewSessionComplete => '復習完了！';

  @override
  String reviewSessionSummary(int count) {
    return '$count件を復習';
  }

  @override
  String get reviewDone => '完了';

  @override
  String get reviewCorrectionPrompt => '正しい言い方は？';

  @override
  String get reviewVocabularyPrompt => 'これはどういう意味？';

  @override
  String get shopItemBgBlueName => 'Ocean Blue';

  @override
  String get shopItemBgBlueDescription => 'Calming blue vibes.';

  @override
  String get shopItemBgForestName => 'Forest Green';

  @override
  String get shopItemBgForestDescription => 'Natural feeling.';

  @override
  String get shopItemBgSunsetName => 'サンセットオレンジ';

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
  String get youLabel => 'あなた';

  @override
  String get mojiSleepReconnect =>
      'Zzz... 言語リンクの再接続中、Mojiはうとうとしています。しばらくしてからもう一度お試しください。';

  @override
  String get mojiSleepNight => 'シーッ... Mojiは眠っています。Mojiをタップして起こしてください。';

  @override
  String get mojiSleepHintReconnect => 'MOJI はうとうと中... 言語リンクを再接続しています';

  @override
  String get mojiSleepHintNight => 'MOJI はおやすみ中... タップして起こす';

  @override
  String get mojiWakeSuccess => 'ふぁぁ... Mojiは起きました！練習しよう！';

  @override
  String mojiAwakeFor(int minutes) {
    return 'あと$minutes分おきてる';
  }

  @override
  String get mojiSleepReasonReconnect => '言語リンクの再接続中、Mojiはうとうとしています。';

  @override
  String get mojiSleepReasonNight => 'Mojiは眠っています。タップして起こしてください。';

  @override
  String get levelsScreenTitle => 'レベル';

  @override
  String get levelStatusCurrent => '現在のレベル';

  @override
  String get levelStatusCompleted => '完了';

  @override
  String get levelRewardLabel => '報酬';

  @override
  String get quizPausedTitle => '一時停止中';

  @override
  String get quizPausedPrompt => '続けますか、それとも終了しますか?';

  @override
  String get quizPlay => 'プレイ';

  @override
  String get quizPause => '一時停止';

  @override
  String get quizExit => '終了';

  @override
  String get weeklyProgressTitle => '週間プログレス';

  @override
  String dayLabel(int dayNum) {
    return '日 $dayNum';
  }

  @override
  String get dailyRewardHint => '明日戻って来て毎日報酬を受け取ってください';

  @override
  String get resetAppButton => 'リセット';

  @override
  String get resetAppTitle => 'アプリをリセット';

  @override
  String get resetAppWarning => 'これはすべてのプログレスを削除します。\n\nよろしいですか?';

  @override
  String get resetAction => 'リセット';

  @override
  String get resetSuccessMessage => 'アプリが正常にリセットされました';

  @override
  String get selectYourCharacter => 'あなたのキャラクターを選択';

  @override
  String get characterDog => '犬';

  @override
  String get characterCat => '猫';

  @override
  String get characterBird => '鳥';

  @override
  String get aiUnavailableMessage =>
      'Zzz... 言語リンクの再接続中、Mojiはうたた寝しています。また後で試してね。';

  @override
  String get mojiDozingReconnect => '言語リンクの再接続中、Mojiはうたた寝しています。';

  @override
  String get mojiSleepingTapWake => 'Mojiは眠っています。タップして起こしてね。';

  @override
  String get mojiAwakeReady => 'Mojiは起きていて準備万端！';

  @override
  String get wardrobeTitle => 'クローゼット';

  @override
  String get slotHat => 'ぼうし';

  @override
  String get slotNeck => 'くび';

  @override
  String get slotFace => 'かお';

  @override
  String get bodyTailColor => '体としっぽの色';

  @override
  String get eyeColor => '目の色';

  @override
  String get eyeStyleSolid => '単色';

  @override
  String get eyeStyleOddEyed => 'オッドアイ';

  @override
  String get leftEye => '左目';

  @override
  String get rightEye => '右目';

  @override
  String get colorLabel => '色';

  @override
  String get scenarioObjectives => '目標';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'クリア';

  @override
  String get scenarioBonusLabel => 'ボーナス';

  @override
  String get scenarioCompleteTitle => 'シナリオクリア！';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '目標 $done/$total';
  }

  @override
  String get scenarioFirstClear => '初クリア！';

  @override
  String get scenarioReplayNote => 'リプレイ報酬 — 初クリアのほうが多くもらえます。';

  @override
  String get scenarioContinue => '続ける';

  @override
  String get objCoffeeOrder => '飲み物を注文する';

  @override
  String get objCoffeeCustomize => '注文をカスタマイズする';

  @override
  String get objCoffeePrice => '値段を聞く';

  @override
  String get objCoffeeSmallTalk => '店員と少し雑談する';

  @override
  String get objInterviewGreet => '自己紹介をする';

  @override
  String get objInterviewExperience => '経験を説明する';

  @override
  String get objInterviewStrength => '自分が適任である理由を説明する';

  @override
  String get objInterviewAsk => '仕事について質問する';

  @override
  String get objDirectionsAsk => '道をたずねる';

  @override
  String get objDirectionsClarify => 'もう一度言ってもらう、ゆっくり話してもらう';

  @override
  String get objDirectionsDistance => 'どのくらい遠いか確認する';

  @override
  String get objDirectionsThank => 'きちんとお礼を言う';

  @override
  String get objDoctorSymptom => '症状を説明する';

  @override
  String get objDoctorDuration => 'いつからそうなのか伝える';

  @override
  String get objDoctorQuestion => 'どうすればいいか聞く';

  @override
  String get objDoctorAllergy => 'アレルギーや飲んでいる薬を伝える';

  @override
  String get objShoppingFind => '商品がどこにあるか聞く';

  @override
  String get objShoppingSize => 'サイズや色、着心地について聞く';

  @override
  String get objShoppingPrice => '値段を聞く';

  @override
  String get objShoppingPay => '支払いをする';

  @override
  String get objRestaurantTable => '席をお願いする';

  @override
  String get objRestaurantOrder => '料理を注文する';

  @override
  String get objRestaurantDrink => '飲み物を注文する';

  @override
  String get objRestaurantBill => '会計をお願いする';

  @override
  String get notificationsTitle => '通知';

  @override
  String get notificationsEnable => 'モジのことを知らせる';

  @override
  String get notificationsDesc =>
      'モジがあなたを必要としているとき、復習の時間、デイリー報酬の準備ができたときにお知らせします。';

  @override
  String get notificationsBlocked => '端末の設定で通知がオフになっています。';

  @override
  String get notifPetChannelName => 'モジがあなたを待っています';

  @override
  String get notifPetChannelDesc => 'ペットが空腹または元気がないときのお知らせ';

  @override
  String get notifReviewChannelName => '復習のお知らせ';

  @override
  String get notifReviewChannelDesc => '復習する単語があるときのお知らせ';

  @override
  String get notifRewardChannelName => 'デイリー報酬';

  @override
  String get notifRewardChannelDesc => 'デイリー報酬の準備ができたときのお知らせ';

  @override
  String get notifPetHungryTitle => 'モジがお腹をすかせています';

  @override
  String get notifPetHungryBody => 'ペットが今すぐおやつを欲しがっています。';

  @override
  String get notifPetSadTitle => 'モジがさみしがっています';

  @override
  String get notifPetSadBody => 'あなたがいなくて静かです。ちょっと顔を見せませんか？';

  @override
  String get notifReviewTitle => '復習の時間です';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件の単語が待っています。',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'デイリー報酬の準備ができました';

  @override
  String get notifRewardBody => 'モジがあなたに何か用意しています。受け取りに来てください！';

  @override
  String get careTitle => 'モジの様子';

  @override
  String get careStatFullness => '満腹度';

  @override
  String get careStatHappiness => 'きげん';

  @override
  String get careStatHealth => '体調';

  @override
  String get careAllWell => 'モジは元気いっぱいです。';

  @override
  String get careNeedHungry => 'モジはお腹がすいています';

  @override
  String get careNeedLonely => 'モジは元気がありません';

  @override
  String get careNeedSick => 'モジは体調が悪いです';

  @override
  String get careSickPenalty => 'モジが体調を崩している間は、XPとコインが半分になります。';

  @override
  String get careFeedTitle => 'モジにごはんをあげる';

  @override
  String get careNoFood => '食べ物がありません。ショップで補充しましょう。';

  @override
  String get careGoToShop => 'ショップへ';

  @override
  String get carePlay => 'モジをなでる';

  @override
  String get carePlayCooldown => 'モジは今はもう十分かまってもらいました。';

  @override
  String get careClose => '閉じる';

  @override
  String careFedItem(String item) {
    return 'モジは$itemを食べました。';
  }

  @override
  String careCurrentFullness(int value) {
    return '現在の満腹度：$value%';
  }

  @override
  String get scenarioSickPenalty => 'モジは体調不良 — 報酬は半分';

  @override
  String get careDragToFeed => 'モジにドラッグしてあげよう';

  @override
  String get bondLabel => 'きずな';

  @override
  String get bondStageCurious => 'きになる';

  @override
  String get bondStageFriendly => 'なかよし';

  @override
  String get bondStageAttached => 'なついた';

  @override
  String get bondStageDevoted => 'しんらい';

  @override
  String get bondStageInseparable => 'いつもいっしょ';

  @override
  String bondToNextStage(int points, String stage) {
    return '$stageまで あと$points';
  }

  @override
  String get bondKeepLearning => '学び続けて もっと仲良くなろう';

  @override
  String get bondMissesYou => 'モジがさみしがっています';

  @override
  String get bondLonely => 'モジはずっと待っています';

  @override
  String get categoryStyle => 'スタイル';

  @override
  String get accessoryDescription => 'モジに似合う小物です。';

  @override
  String accessoryUnlocksAt(String stage) {
    return '$stageで解放';
  }

  @override
  String get accessoryEarnedNotSold => '買えません、きずなで手に入ります';

  @override
  String get accessoryCapName => 'キャップ';

  @override
  String get accessoryTopHatName => 'シルクハット';

  @override
  String get accessoryCowboyHatName => 'カウボーイハット';

  @override
  String get accessoryCrownName => '王冠';

  @override
  String get accessoryPartyHatName => 'パーティー帽';

  @override
  String get accessoryBowTieName => 'ちょうネクタイ';

  @override
  String get accessoryNecklaceName => 'ネックレス';

  @override
  String get accessoryMustacheName => 'くちひげ';

  @override
  String get accessoryBeanieName => 'ニット帽';

  @override
  String get accessoryMortarboardName => '角帽';

  @override
  String get accessoryCollarName => '鈴の首輪';

  @override
  String get accessoryGlassesName => 'めがね';

  @override
  String get accessorySunglassesName => 'サングラス';

  @override
  String get accessoryMaskName => '仮面';

  @override
  String get accessoryMedalName => 'メダル';

  @override
  String get accessoryScarfName => 'マフラー';

  @override
  String get accessoryHeadphonesName => 'ヘッドホン';

  @override
  String get accessoryWizardHatName => 'まほうつかいの帽子';

  @override
  String get accessoryFlowerCrownName => '花かんむり';

  @override
  String get accessoryDevilHornsName => 'あくまのツノ';

  @override
  String get onboardingLanguageQuestion => '何語を話しますか？';

  @override
  String get onboardingLanguageConfirm => 'つづける';

  @override
  String get onboardingPetQuestion => 'だれをつれて帰る？';

  @override
  String get onboardingPetConfirm => 'きめる';

  @override
  String get onboardingLoginTitle => 'ペットを保存しよう';

  @override
  String get onboardingLoginGoogle => 'Googleでつづける';

  @override
  String get onboardingLoginEmail => 'メールでつづける';

  @override
  String get onboardingLoginSkip => 'あとで';

  @override
  String get onboardingLoginSubtitle => 'ログインすれば、ずっといっしょ。';

  @override
  String get accountEmailLabel => 'メール';

  @override
  String get accountPasswordLabel => 'パスワード';

  @override
  String get accountContinueAction => 'つづける';

  @override
  String get accountConflictTitle => 'ペットが2ひき';

  @override
  String accountConflictBody(String email) {
    return '$email にもこのスマホにもペットがいます。のこせるのは1ひきだけ。';
  }

  @override
  String get accountConflictKeepThisDevice => 'このスマホのペットをのこす';

  @override
  String get accountConflictUseSaved => 'ほぞんされたペットをつかう';

  @override
  String get accountErrorInvalidEmail => 'メールアドレスがただしくありません。';

  @override
  String get accountErrorWeakPassword => '6もじいじょうにしてください。';

  @override
  String get accountErrorSignIn => 'ログインできませんでした。もういちどためしてください。';
}
