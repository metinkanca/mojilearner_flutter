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
  String get quizDesc => '知識をテストしましょう。';

  @override
  String get scenarios => 'まち';

  @override
  String get scenariosDesc => '実際の会話を練習します。';

  @override
  String get townSchool => '学校';

  @override
  String get townTab => 'まち';

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
  String get shopItemDonutName => 'ドーナツ';

  @override
  String get shopItemDonutDescription => '甘くてべたべた。';

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
  String get sceneryTitle => '背景';

  @override
  String get shopItemBgMeadowName => '草原';

  @override
  String get sceneInUse => '使用中';

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
  String get mojiSleepNight => 'シーッ... Mojiは眠っています。Mojiをタップして起こしてください。';

  @override
  String get mojiWakeSuccess => 'ふぁぁ... Mojiは起きました！練習しよう！';

  @override
  String mojiAwakeFor(int minutes) {
    return 'あと$minutes分おきてる';
  }

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
  String get characterRabbit => 'ウサギ';

  @override
  String get characterHamster => 'ハムスター';

  @override
  String get characterParrot => 'オウム';

  @override
  String get characterFox => 'キツネ';

  @override
  String get characterRaccoon => 'アライグマ';

  @override
  String get characterRedPanda => 'レッサーパンダ';

  @override
  String get characterSkunk => 'スカンク';

  @override
  String get characterOtter => 'カワウソ';

  @override
  String get characterBeaver => 'ビーバー';

  @override
  String get characterSquirrel => 'リス';

  @override
  String get characterChinchilla => 'チンチラ';

  @override
  String get characterMouse => 'ネズミ';

  @override
  String get characterHedgehog => 'ハリネズミ';

  @override
  String get characterBat => 'コウモリ';

  @override
  String get characterFennec => 'フェネック';

  @override
  String get characterKoala => 'コアラ';

  @override
  String get characterWombat => 'ウォンバット';

  @override
  String get characterPanda => 'パンダ';

  @override
  String get characterSloth => 'ナマケモノ';

  @override
  String get characterCapybara => 'カピバラ';

  @override
  String get characterPiglet => 'コブタ';

  @override
  String get characterSeal => 'アザラシ';

  @override
  String get characterPenguin => 'ペンギン';

  @override
  String get characterFrog => 'カエル';

  @override
  String get characterAxolotl => 'ウーパールーパー';

  @override
  String get characterGecko => 'ヤモリ';

  @override
  String get characterChameleon => 'カメレオン';

  @override
  String get aiUnavailableMessage =>
      'Zzz... 言語リンクの再接続中、Mojiはうたた寝しています。また後で試してね。';

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
  String get beakColor => 'くちばしの色';

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
  String get scenarioFinish => 'おわる';

  @override
  String get scenarioFinishTitle => 'シーンを終える？';

  @override
  String get scenarioFinishBody =>
      'まだ達成していない目標があります。ここで終えると報酬は一部だけになり、シナリオは未クリアのまま残るので、あとでしっかり達成できます。';

  @override
  String get scenarioFinishConfirm => 'それでも終える';

  @override
  String get scenarioFinishCancel => '会話を続ける';

  @override
  String get scenarioPartialTitle => 'シーン終了';

  @override
  String get scenarioPartialNote => '一部だけの報酬 — すべての目標を達成すると全額もらえます。';

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
  String get playCatch => 'キャッチボールで遊ぶ';

  @override
  String get playCatchAgain => 'もう一回';

  @override
  String get playToyChest => 'おもちゃばこ';

  @override
  String get playBubbleBath => 'あわあわおふろ';

  @override
  String get playPounce => 'もぐらにとびつけ';

  @override
  String get playPondHop => 'いけでぴょんぴょん';

  @override
  String get playFetchWords => 'ことばをとってこい';

  @override
  String get playNeedsWords => 'あそぶには、もう少し言葉をおぼえよう';

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
  String get bondMissesYou => 'モジがさみしがっています';

  @override
  String get bondLonely => 'モジはずっと待っています';

  @override
  String get aiLimitQuizTitle => '今日のAIクイズは使い切りました';

  @override
  String get aiLimitMessageTitle => '今日のAIメッセージは使い切りました';

  @override
  String aiLimitUsage(int used, int total) {
    return '本日 $total 中 $used 使用';
  }

  @override
  String get aiLimitResets => '制限は明日戻ります。';

  @override
  String get aiLimitReviewOpen => '復習に先生は不要です — カードはいつでもあります。';

  @override
  String get aiLimitQuizOpen => '自分の単語から作ったクイズはまだ使えます。';

  @override
  String get aiLimitWatchAd => '広告を見てもう1回';

  @override
  String get aiLimitGoPlus => 'Mimikin Plus を入手';

  @override
  String get premiumColumnFree => '無料';

  @override
  String get premiumColumnPlus => 'Plus';

  @override
  String get premiumRowQuizzes => '1日のAIクイズ';

  @override
  String get premiumRowMessages => '1日のAIメッセージ';

  @override
  String get premiumRowAds => 'インタースティシャル広告';

  @override
  String get premiumValueShown => '表示あり';

  @override
  String get premiumValueNone => 'なし';

  @override
  String get premiumRowRollover => '未使用のクイズ';

  @override
  String get premiumValueExpire => '失効';

  @override
  String get premiumValueRollOver => '繰り越し';

  @override
  String get premiumRowPetStats => 'ペットの状態';

  @override
  String get premiumValueDecay => '下がる';

  @override
  String get premiumValueDecaySlower => '下がりにくい';

  @override
  String get premiumComingSoon => 'サブスクリプションはまだ開始していません。';

  @override
  String get premiumActive => 'Mimikin Plus は有効です。';

  @override
  String get premiumRestore => '購入を復元';

  @override
  String get premiumRestoreDone => 'このアカウントに復元できるものはありません。';

  @override
  String get premiumPurchasePending => 'ストアで処理しています…';

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

  @override
  String get adsFreeCoins => '無料コイン';

  @override
  String adsWatchForCoins(int coins) {
    return '動画を見て +$coins';
  }

  @override
  String adsLeftToday(int remaining, int total) {
    return '本日 残り $remaining/$total';
  }

  @override
  String get adsNoneLeftToday => '今日はここまで';

  @override
  String get adsNotReady => '今は動画がありません';

  @override
  String adsEarnedCoins(int coins) {
    return '+$coins コイン！';
  }

  @override
  String get privacyRedactedNotice => '個人情報は送信前に隠されました。';

  @override
  String quizQuestionCounter(int current, int total) {
    return '問題 $current/$total';
  }

  @override
  String get quizPreparing => '準備中...';

  @override
  String get quizPickAnswer => '正しい答えを選んでね';

  @override
  String get quizWellDone => 'よくできました！';

  @override
  String get quizEncouragement => 'きっとできるよ！';

  @override
  String petTutorialWelcome(String name) {
    return 'はじめまして、$name！いっしょに まなぼう。';
  }

  @override
  String get tutorialOfferTitle => '案内しましょうか？';

  @override
  String get tutorialWatch => '見せて';

  @override
  String get tutorialSkip => 'スキップ';

  @override
  String get tutorialNext => 'つぎへ';

  @override
  String get tutorialBack => 'もどる';

  @override
  String get tutorialDone => 'かんりょう';

  @override
  String get tutorialReplay => 'チュートリアルをもう一度見る';

  @override
  String get tutorialOfferHome => 'ホーム画面をざっと案内しましょうか？';

  @override
  String get tutorialOfferQuiz => 'はじめてのクイズです。ざっと案内しましょうか？';

  @override
  String get tutorialOfferChat => 'はじめてのチャットです。ざっと案内しましょうか？';

  @override
  String get tutorialOfferShop => 'はじめてのショップです。ざっと案内しましょうか？';

  @override
  String get tutorialOfferProfile => 'プロフィールをざっと案内しましょうか？';

  @override
  String get tutorialOfferReview => 'はじめての復習です。ざっと案内しましょうか？';

  @override
  String get tutorialHomePet => 'この子がモジです。タップするか、頭を横になでてあげましょう。';

  @override
  String get tutorialHomeLevel => 'レベルと経験値です。タップすると次のレベルで何が開くか見られます。';

  @override
  String get tutorialHomeFeed => '手持ちの食べ物です。おやつを選んでモジにドラッグしましょう。';

  @override
  String get tutorialHomeCare => 'モジが何か必要なときに出ます。タップして様子を見ましょう。';

  @override
  String get tutorialHomeReview => '復習：たまった単語をおさらいして、まちがいを見返せます。';

  @override
  String get tutorialHomeSettings => '設定：ピクセル文字、リマインダー、この案内の再生です。';

  @override
  String get tutorialNavTown => 'まち：建物に入って会話の練習をしたり、学校でクイズに挑戦したりできます。';

  @override
  String get tutorialNavChat => 'チャット：長めの会話とロールプレイのシナリオです。';

  @override
  String get tutorialNavShop => 'ショップ：コインで食べ物や見た目、新しい世界を買えます。';

  @override
  String get tutorialNavProfile => 'プロフィール：記録、言語、アカウントの設定です。';

  @override
  String get tutorialQuizHeader => 'レベルと、やめたいときの一時停止ボタンです。';

  @override
  String get tutorialQuizQuestion => '問題です。上のバッジが何をためしているか示します。';

  @override
  String get tutorialQuizOptions => '答えを選びましょう。まちがえたものは保存され、あとで復習できます。';

  @override
  String get tutorialQuizContinue => '答えたら次へ進みましょう。';

  @override
  String get tutorialChatMenu => 'これまでのチャットとロールプレイはこのボタンの中です。';

  @override
  String get tutorialChatMessages => 'ふたりの会話です。まちがいはそっと直してくれます。';

  @override
  String get tutorialChatInput => 'ここに書きましょう。完璧でなくてだいじょうぶです。';

  @override
  String get tutorialShopCoins => 'コインです。練習とモジのお世話でたまります。';

  @override
  String get tutorialShopTabs => 'ほしいもので絞りこめます：食べ物、かざり、スタイル。';

  @override
  String get tutorialShopGrid => 'タップすると買えます。食べ物はなくなりますが、ほかはずっと残ります。';

  @override
  String get tutorialShopFreeCoins => 'コインが足りない？短い動画を見て補充しましょう。';

  @override
  String get tutorialProfileAvatar => 'モジをタップすると見た目と服を変えられます。';

  @override
  String get tutorialProfileStats => 'レベルと、次のレベルまでの残りです。';

  @override
  String get tutorialProfileDaily => '毎日もどるとごほうびがあります。連続日数が長いほど増えます。';

  @override
  String get tutorialProfileLanguages => '話せる言語と学んでいる言語です。どちらもいつでも変えられます。';

  @override
  String get tutorialProfileAccount => 'アカウントを連携すると、機種変更してもモジが残ります。';

  @override
  String get tutorialReviewCard => '答えを思い出してから、カードをタップして確かめましょう。';

  @override
  String get tutorialReviewGrades => '答えを表示して、できぐあいを伝えましょう。むずかしいカードは早く戻ってきます。';

  @override
  String get tutorialReviewCount => 'この回で残っているカードの数です。';

  @override
  String get seasonPassNotOnSale => 'このパスはまだ販売されていません。';

  @override
  String seasonPassBuy(String price) {
    return '$price で購入';
  }

  @override
  String seasonPassClaim(int count) {
    return '受け取る ($count)';
  }

  @override
  String get seasonPassClaiming => '受け取り中…';

  @override
  String seasonPassClaimedToast(int count) {
    return '受け取り: $count';
  }

  @override
  String seasonPassTierOf(int tier, int total) {
    return 'ティア $tier / $total';
  }

  @override
  String seasonPassTrackLength(int count, int xp) {
    return '$count 個 · $xp XP';
  }

  @override
  String get seasonPassComplete => 'トラック完了。';

  @override
  String seasonPassXpToNext(int xp) {
    return '次のアイテムまで $xp XP';
  }

  @override
  String seasonPassTierCost(int xp) {
    return '$xp XP';
  }

  @override
  String get seasonPassReady => '受取可';

  @override
  String get seasonPassTierClaimed => '受取済';

  @override
  String get seasonPassTryOn => '試着する';

  @override
  String get sceneAirfieldName => '出発';

  @override
  String get sceneCozyRoomName => '居心地のいい部屋';

  @override
  String get sceneEnchantedMeadowName => '魔法の草原';

  @override
  String get sceneMushroomGladeName => 'キノコの広場';

  @override
  String get scenePumpkinPatchName => 'かぼちゃ畑';

  @override
  String get seasonPassScenePreviewOwned => 'あなたのものです。ワードローブでいつでも世界を変えられます。';

  @override
  String get seasonPassPreviewOwned => 'あなたのものです。ワードローブで着せられます。';

  @override
  String get seasonPassPreviewLocked => 'まだあなたのものではありません — 見るだけです。';

  @override
  String get seasonPassPromise =>
      'ティアはパス購入後に稼いだXPで進みます。だから遅く買っても損はありません。ここでは何も期限切れになりません。到達したティアはそのまま、まだのティアは待っています。';

  @override
  String seasonPassWaitingToClaim(int count) {
    return '受け取り待ち: $count';
  }

  @override
  String get seasonPassEarnedByStudying => '学習して獲得';

  @override
  String get accessoryBandanaName => 'サンライズバンダナ';

  @override
  String get accessoryBandanaCloudName => 'クラウドバンダナ';

  @override
  String get accessoryScarfDuskName => 'ダスクマフラー';

  @override
  String get accessoryGogglesName => 'フライトゴーグル';

  @override
  String get accessoryGogglesBrassName => 'ブラスゴーグル';

  @override
  String get accessoryBeanieDuskName => 'ダスクニット帽';

  @override
  String get accessoryFlightCapName => 'フライトキャップ';

  @override
  String get accessoryFlightCapCloudName => 'クラウドフライトキャップ';

  @override
  String get accessoryCowboyHatCharcoalName => 'チャコールカウボーイハット';

  @override
  String get accessoryFlightScarfName => 'なびくマフラー';

  @override
  String get accessoryPumpkinWitchName => 'かぼちゃの魔女帽子';

  @override
  String get accessoryDevilBandName => '悪魔のツノカチューシャ';

  @override
  String get accessoryGhostBandanaName => 'おばけバンダナ';

  @override
  String get accessoryBatChokerName => 'コウモリチョーカー';

  @override
  String get shopSectionTopUp => 'コイン購入';

  @override
  String get shopSectionPlus => 'Plus';

  @override
  String get shopSectionPass => 'シーズンパス';

  @override
  String get shopSectionItems => 'アイテム';

  @override
  String get topUpTitle => 'コイン購入';

  @override
  String topUpCoins(int coins) {
    return '$coins コイン';
  }

  @override
  String topUpBonus(int percent) {
    return 'コイン +$percent%';
  }

  @override
  String get topUpBestValue => 'いちばんお得';

  @override
  String get topUpNotOpen => 'コインパックはまだ販売していません。';

  @override
  String topUpThanks(int coins) {
    return '$coins コインを追加しました。';
  }
}
