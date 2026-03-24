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
  String get shopItemAppleName => 'りんご';

  @override
  String get shopItemAppleDescription => '健康的なスナック。';

  @override
  String get shopItemCroissantName => 'クロワッサン';

  @override
  String get shopItemCroissantDescription => 'バターの美味しさ。';

  @override
  String get shopItemPizzaName => 'ピザスライス';

  @override
  String get shopItemPizzaDescription => 'チーズにあふれた。';

  @override
  String get shopItemSushiName => '寿司セット';

  @override
  String get shopItemSushiDescription => 'プレミアム魚。';

  @override
  String get shopItemCoffeeName => 'エスプレッソ';

  @override
  String get shopItemCoffeeDescription => '素早いエネルギーブースト。';

  @override
  String get shopItemBgBlueName => 'オーシャンブルー';

  @override
  String get shopItemBgBlueDescription => '落ち着きのある青色の雰囲気。';

  @override
  String get shopItemBgForestName => 'フォレストグリーン';

  @override
  String get shopItemBgForestDescription => '自然な感覚。';

  @override
  String get shopItemBgSunsetName => 'サンセットオレンジ';

  @override
  String get shopItemBgSunsetDescription => '温かく快適。';

  @override
  String get shopItemBgGalaxyName => 'ギャラクシーパープル';

  @override
  String get shopItemBgGalaxyDescription => 'この世のものとは思えません。';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemNameを購入しました！';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '${itemName}x$quantityを購入しました！';
  }
}
