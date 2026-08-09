import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('fi'),
    Locale('fr'),
    Locale('hi'),
    Locale('hu'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('no'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sv'),
    Locale('th'),
    Locale('tr'),
    Locale('uk'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @header.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get header;

  /// No description provided for @iSpeak.
  ///
  /// In en, this message translates to:
  /// **'I Speak'**
  String get iSpeak;

  /// No description provided for @imLearning.
  ///
  /// In en, this message translates to:
  /// **'I\'m Learning'**
  String get imLearning;

  /// No description provided for @currentSelection.
  ///
  /// In en, this message translates to:
  /// **'Current Selection:'**
  String get currentSelection;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @xp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get xp;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get streak;

  /// No description provided for @audio.
  ///
  /// In en, this message translates to:
  /// **'Bot Voice'**
  String get audio;

  /// No description provided for @designMojiBtn.
  ///
  /// In en, this message translates to:
  /// **'Design Your Moji'**
  String get designMojiBtn;

  /// No description provided for @quizMode.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizMode;

  /// No description provided for @quizDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge with active recall quizzes.'**
  String get quizDesc;

  /// No description provided for @scenarios.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get scenarios;

  /// No description provided for @scenariosDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice real-life conversations like ordering coffee or job interviews.'**
  String get scenariosDesc;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @mistakes.
  ///
  /// In en, this message translates to:
  /// **'MISTAKES'**
  String get mistakes;

  /// No description provided for @noMistakesYet.
  ///
  /// In en, this message translates to:
  /// **'NO MISTAKES YET!'**
  String get noMistakesYet;

  /// No description provided for @profileDesc.
  ///
  /// In en, this message translates to:
  /// **'View your stats, settings, and progress.'**
  String get profileDesc;

  /// No description provided for @voiceCall.
  ///
  /// In en, this message translates to:
  /// **'Voice Call'**
  String get voiceCall;

  /// No description provided for @voiceCallDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice speaking in a real-time voice call.'**
  String get voiceCallDesc;

  /// No description provided for @practiceRealLife.
  ///
  /// In en, this message translates to:
  /// **'Practice Real Life'**
  String get practiceRealLife;

  /// No description provided for @chooseSituation.
  ///
  /// In en, this message translates to:
  /// **'Choose a situation to master your conversation skills'**
  String get chooseSituation;

  /// No description provided for @createYourOwn.
  ///
  /// In en, this message translates to:
  /// **'Create Your Own'**
  String get createYourOwn;

  /// No description provided for @startCustom.
  ///
  /// In en, this message translates to:
  /// **'Start Custom Scenario'**
  String get startCustom;

  /// No description provided for @customPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'E.g. You are a taxi driver...'**
  String get customPlaceholder;

  /// No description provided for @orderingCoffee.
  ///
  /// In en, this message translates to:
  /// **'Ordering Coffee'**
  String get orderingCoffee;

  /// No description provided for @jobInterview.
  ///
  /// In en, this message translates to:
  /// **'Job Interview'**
  String get jobInterview;

  /// No description provided for @askingDirections.
  ///
  /// In en, this message translates to:
  /// **'Asking Directions'**
  String get askingDirections;

  /// No description provided for @atTheDoctor.
  ///
  /// In en, this message translates to:
  /// **'At the Doctor'**
  String get atTheDoctor;

  /// No description provided for @shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get shopping;

  /// No description provided for @restaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @chats.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chats;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search messages...'**
  String get searchPlaceholder;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'No chats yet'**
  String get noChats;

  /// No description provided for @startNewConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a new conversation'**
  String get startNewConversation;

  /// No description provided for @blankChat.
  ///
  /// In en, this message translates to:
  /// **'Blank Chat'**
  String get blankChat;

  /// No description provided for @blankChatDesc.
  ///
  /// In en, this message translates to:
  /// **'Start a fresh conversation with no context'**
  String get blankChatDesc;

  /// No description provided for @roleplayScenario.
  ///
  /// In en, this message translates to:
  /// **'Roleplay Scenario'**
  String get roleplayScenario;

  /// No description provided for @roleplayScenarioDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice specific situations like ordering coffee or a job interview'**
  String get roleplayScenarioDesc;

  /// No description provided for @chooseChatType.
  ///
  /// In en, this message translates to:
  /// **'Choose a Chat Type'**
  String get chooseChatType;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type your message...'**
  String get typeMessage;

  /// No description provided for @designMoji.
  ///
  /// In en, this message translates to:
  /// **'Design Moji'**
  String get designMoji;

  /// No description provided for @fullCustomization.
  ///
  /// In en, this message translates to:
  /// **'Full Customization'**
  String get fullCustomization;

  /// No description provided for @tapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change emotion'**
  String get tapToChange;

  /// No description provided for @mascotColor.
  ///
  /// In en, this message translates to:
  /// **'Mascot Color'**
  String get mascotColor;

  /// No description provided for @backgroundColor.
  ///
  /// In en, this message translates to:
  /// **'Background Color'**
  String get backgroundColor;

  /// No description provided for @faceExpressions.
  ///
  /// In en, this message translates to:
  /// **'Face Expressions'**
  String get faceExpressions;

  /// No description provided for @personalityFaces.
  ///
  /// In en, this message translates to:
  /// **'Personality & Faces'**
  String get personalityFaces;

  /// No description provided for @selectFaces.
  ///
  /// In en, this message translates to:
  /// **'Select the faces your mascot will use.'**
  String get selectFaces;

  /// No description provided for @locked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// No description provided for @unlockMessage.
  ///
  /// In en, this message translates to:
  /// **'Reach Level {level} to unlock this face!'**
  String unlockMessage(Object level);

  /// No description provided for @yourMistakes.
  ///
  /// In en, this message translates to:
  /// **'Your Mistakes'**
  String get yourMistakes;

  /// No description provided for @learnFromWrong.
  ///
  /// In en, this message translates to:
  /// **'Learn from what went wrong'**
  String get learnFromWrong;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @grammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get grammar;

  /// No description provided for @grammarBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Grammar Breakdown'**
  String get grammarBreakdown;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @noGrammarAnalysis.
  ///
  /// In en, this message translates to:
  /// **'No grammar analysis available.'**
  String get noGrammarAnalysis;

  /// No description provided for @vocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabulary;

  /// No description provided for @noMistakes.
  ///
  /// In en, this message translates to:
  /// **'No mistakes found!'**
  String get noMistakes;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get yourAnswer;

  /// No description provided for @correctAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswer;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @story.
  ///
  /// In en, this message translates to:
  /// **'Scenarios'**
  String get story;

  /// No description provided for @drills.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get drills;

  /// No description provided for @typeHere.
  ///
  /// In en, this message translates to:
  /// **'Type here...'**
  String get typeHere;

  /// No description provided for @shopTitle.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shopTitle;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryDecor.
  ///
  /// In en, this message translates to:
  /// **'Decor'**
  String get categoryDecor;

  /// No description provided for @hideOwnedCosmetics.
  ///
  /// In en, this message translates to:
  /// **'Hide Owned Cosmetics'**
  String get hideOwnedCosmetics;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'No Items'**
  String get noItems;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @alreadyOwned.
  ///
  /// In en, this message translates to:
  /// **'Already Owned'**
  String get alreadyOwned;

  /// No description provided for @alreadyOwnedMessage.
  ///
  /// In en, this message translates to:
  /// **'You already own this item!'**
  String get alreadyOwnedMessage;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @notEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not Enough Coins!'**
  String get notEnoughCoins;

  /// No description provided for @purchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase Failed'**
  String get purchaseFailed;

  /// No description provided for @notEnoughCoinsMessage.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins!'**
  String get notEnoughCoinsMessage;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @tooPoor.
  ///
  /// In en, this message translates to:
  /// **'Too Poor'**
  String get tooPoor;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @daily_reward.
  ///
  /// In en, this message translates to:
  /// **'Daily Reward'**
  String get daily_reward;

  /// No description provided for @claim_reward.
  ///
  /// In en, this message translates to:
  /// **'Claim Reward'**
  String get claim_reward;

  /// No description provided for @day_streak.
  ///
  /// In en, this message translates to:
  /// **'Day {X} Streak'**
  String day_streak(Object X);

  /// No description provided for @come_back_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Come back tomorrow!'**
  String get come_back_tomorrow;

  /// No description provided for @streak_broken.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Starting fresh'**
  String get streak_broken;

  /// No description provided for @keep_going.
  ///
  /// In en, this message translates to:
  /// **'Keep it going!'**
  String get keep_going;

  /// No description provided for @reward_claimed.
  ///
  /// In en, this message translates to:
  /// **'Reward Claimed!'**
  String get reward_claimed;

  /// No description provided for @amazing_streak.
  ///
  /// In en, this message translates to:
  /// **'Amazing! Day {X} streak!'**
  String amazing_streak(Object X);

  /// No description provided for @whatsYourName.
  ///
  /// In en, this message translates to:
  /// **'WHAT\'S YOUR NAME?'**
  String get whatsYourName;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @continueBtn.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueBtn;

  /// No description provided for @howWouldYouRate.
  ///
  /// In en, this message translates to:
  /// **'HOW WOULD YOU RATE'**
  String get howWouldYouRate;

  /// No description provided for @yourLevel.
  ///
  /// In en, this message translates to:
  /// **'YOUR LEVEL?'**
  String get yourLevel;

  /// No description provided for @beginner.
  ///
  /// In en, this message translates to:
  /// **'BEGINNER'**
  String get beginner;

  /// No description provided for @intermediate.
  ///
  /// In en, this message translates to:
  /// **'INTERMEDIATE'**
  String get intermediate;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'ADVANCED'**
  String get advanced;

  /// No description provided for @beginnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Just starting. I know very few words.'**
  String get beginnerDesc;

  /// No description provided for @intermediateDesc.
  ///
  /// In en, this message translates to:
  /// **'I can hold basic conversations and understand simple texts.'**
  String get intermediateDesc;

  /// No description provided for @advancedDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'m fluent or near-fluent. I can discuss complex topics.'**
  String get advancedDesc;

  /// No description provided for @whichLanguage.
  ///
  /// In en, this message translates to:
  /// **'WHICH LANGUAGE'**
  String get whichLanguage;

  /// No description provided for @doYouWantToLearn.
  ///
  /// In en, this message translates to:
  /// **'DO YOU WANT TO LEARN?'**
  String get doYouWantToLearn;

  /// No description provided for @changeAnytime.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings'**
  String get changeAnytime;

  /// No description provided for @dontWorryVerify.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry, we\'ll verify this with a quick chat!'**
  String get dontWorryVerify;

  /// No description provided for @startAssessment.
  ///
  /// In en, this message translates to:
  /// **'START ASSESSMENT'**
  String get startAssessment;

  /// No description provided for @chatAssessment.
  ///
  /// In en, this message translates to:
  /// **'CHAT ASSESSMENT'**
  String get chatAssessment;

  /// No description provided for @typeYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Type your answer...'**
  String get typeYourAnswer;

  /// No description provided for @mojiIsTyping.
  ///
  /// In en, this message translates to:
  /// **'Moji is typing...'**
  String get mojiIsTyping;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get send;

  /// No description provided for @calibrationComplete.
  ///
  /// In en, this message translates to:
  /// **'Calibration Complete!'**
  String get calibrationComplete;

  /// No description provided for @basedOnYourAnswers.
  ///
  /// In en, this message translates to:
  /// **'Based on your answers, your recommended starting level is:'**
  String get basedOnYourAnswers;

  /// No description provided for @proficiencyLevel.
  ///
  /// In en, this message translates to:
  /// **'Proficiency Level'**
  String get proficiencyLevel;

  /// No description provided for @shopItemAppleName.
  ///
  /// In en, this message translates to:
  /// **'Apple'**
  String get shopItemAppleName;

  /// No description provided for @shopItemAppleDescription.
  ///
  /// In en, this message translates to:
  /// **'A healthy snack.'**
  String get shopItemAppleDescription;

  /// No description provided for @shopItemCroissantName.
  ///
  /// In en, this message translates to:
  /// **'Croissant'**
  String get shopItemCroissantName;

  /// No description provided for @shopItemCroissantDescription.
  ///
  /// In en, this message translates to:
  /// **'Buttery goodness.'**
  String get shopItemCroissantDescription;

  /// No description provided for @shopItemPizzaName.
  ///
  /// In en, this message translates to:
  /// **'Pizza Slice'**
  String get shopItemPizzaName;

  /// No description provided for @shopItemPizzaDescription.
  ///
  /// In en, this message translates to:
  /// **'Cheesy and filling.'**
  String get shopItemPizzaDescription;

  /// No description provided for @shopItemSushiName.
  ///
  /// In en, this message translates to:
  /// **'Sushi Set'**
  String get shopItemSushiName;

  /// No description provided for @shopItemSushiDescription.
  ///
  /// In en, this message translates to:
  /// **'Premium fish.'**
  String get shopItemSushiDescription;

  /// No description provided for @shopItemCoffeeName.
  ///
  /// In en, this message translates to:
  /// **'Espresso'**
  String get shopItemCoffeeName;

  /// No description provided for @shopItemCoffeeDescription.
  ///
  /// In en, this message translates to:
  /// **'Quick energy boost.'**
  String get shopItemCoffeeDescription;

  /// No description provided for @shopItemMedicineName.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get shopItemMedicineName;

  /// No description provided for @shopItemMedicineDescription.
  ///
  /// In en, this message translates to:
  /// **'Nurses Moji back to health.'**
  String get shopItemMedicineDescription;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @reviewDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String reviewDueCount(int count);

  /// No description provided for @reviewProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String reviewProgress(int current, int total);

  /// No description provided for @reviewShowAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show answer'**
  String get reviewShowAnswer;

  /// No description provided for @reviewGradeAgain.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get reviewGradeAgain;

  /// No description provided for @reviewGradeHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get reviewGradeHard;

  /// No description provided for @reviewGradeGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewGradeGood;

  /// No description provided for @reviewGradeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get reviewGradeEasy;

  /// No description provided for @reviewAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get reviewAllCaughtUp;

  /// No description provided for @reviewNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review right now. Chat or take a quiz and Moji will remember what you struggle with.'**
  String get reviewNothingDue;

  /// No description provided for @reviewSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Review complete!'**
  String get reviewSessionComplete;

  /// No description provided for @reviewSessionSummary.
  ///
  /// In en, this message translates to:
  /// **'{count} reviewed'**
  String reviewSessionSummary(int count);

  /// No description provided for @reviewDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get reviewDone;

  /// No description provided for @reviewCorrectionPrompt.
  ///
  /// In en, this message translates to:
  /// **'What\'s the correction?'**
  String get reviewCorrectionPrompt;

  /// No description provided for @reviewVocabularyPrompt.
  ///
  /// In en, this message translates to:
  /// **'What does this mean?'**
  String get reviewVocabularyPrompt;

  /// No description provided for @shopItemBgBlueName.
  ///
  /// In en, this message translates to:
  /// **'Ocean Blue'**
  String get shopItemBgBlueName;

  /// No description provided for @shopItemBgBlueDescription.
  ///
  /// In en, this message translates to:
  /// **'Calming blue vibes.'**
  String get shopItemBgBlueDescription;

  /// No description provided for @shopItemBgForestName.
  ///
  /// In en, this message translates to:
  /// **'Forest Green'**
  String get shopItemBgForestName;

  /// No description provided for @shopItemBgForestDescription.
  ///
  /// In en, this message translates to:
  /// **'Natural feeling.'**
  String get shopItemBgForestDescription;

  /// No description provided for @shopItemBgSunsetName.
  ///
  /// In en, this message translates to:
  /// **'Sunset Orange'**
  String get shopItemBgSunsetName;

  /// No description provided for @shopItemBgSunsetDescription.
  ///
  /// In en, this message translates to:
  /// **'Warm and cozy.'**
  String get shopItemBgSunsetDescription;

  /// No description provided for @shopItemBgGalaxyName.
  ///
  /// In en, this message translates to:
  /// **'Galaxy Purple'**
  String get shopItemBgGalaxyName;

  /// No description provided for @shopItemBgGalaxyDescription.
  ///
  /// In en, this message translates to:
  /// **'Out of this world.'**
  String get shopItemBgGalaxyDescription;

  /// No description provided for @purchaseSuccessSingle.
  ///
  /// In en, this message translates to:
  /// **'Purchased {itemName}!'**
  String purchaseSuccessSingle(Object itemName);

  /// No description provided for @purchaseSuccessMultiple.
  ///
  /// In en, this message translates to:
  /// **'Purchased {itemName} x{quantity}!'**
  String purchaseSuccessMultiple(Object itemName, Object quantity);

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @mojiSleepReconnect.
  ///
  /// In en, this message translates to:
  /// **'Zzz... Moji is dozing while the language link reconnects. Try again soon.'**
  String get mojiSleepReconnect;

  /// No description provided for @mojiSleepNight.
  ///
  /// In en, this message translates to:
  /// **'Shhh... Moji is sleeping. Tap Moji to wake up.'**
  String get mojiSleepNight;

  /// No description provided for @mojiSleepHintReconnect.
  ///
  /// In en, this message translates to:
  /// **'MOJI IS DOZING... LANGUAGE LINK RECONNECTING'**
  String get mojiSleepHintReconnect;

  /// No description provided for @mojiSleepHintNight.
  ///
  /// In en, this message translates to:
  /// **'MOJI IS SLEEPING... TAP TO WAKE'**
  String get mojiSleepHintNight;

  /// No description provided for @mojiWakeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Yawn... Moji is awake now. Let\'s practice!'**
  String get mojiWakeSuccess;

  /// No description provided for @mojiSleepReasonReconnect.
  ///
  /// In en, this message translates to:
  /// **'Moji is dozing while the language link reconnects.'**
  String get mojiSleepReasonReconnect;

  /// No description provided for @mojiSleepReasonNight.
  ///
  /// In en, this message translates to:
  /// **'Moji is sleeping. Tap to wake up.'**
  String get mojiSleepReasonNight;

  /// No description provided for @levelsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get levelsScreenTitle;

  /// No description provided for @levelStatusCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get levelStatusCurrent;

  /// No description provided for @levelStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get levelStatusCompleted;

  /// No description provided for @levelRewardLabel.
  ///
  /// In en, this message translates to:
  /// **'Reward'**
  String get levelRewardLabel;

  /// No description provided for @quizPausedTitle.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get quizPausedTitle;

  /// No description provided for @quizPausedPrompt.
  ///
  /// In en, this message translates to:
  /// **'Continue quiz or exit?'**
  String get quizPausedPrompt;

  /// No description provided for @quizPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get quizPlay;

  /// No description provided for @quizPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get quizPause;

  /// No description provided for @quizExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get quizExit;

  /// No description provided for @weeklyProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Progress'**
  String get weeklyProgressTitle;

  /// Label for a day number in weekly rewards view
  ///
  /// In en, this message translates to:
  /// **'Day {dayNum}'**
  String dayLabel(int dayNum);

  /// No description provided for @dailyRewardHint.
  ///
  /// In en, this message translates to:
  /// **'Claim once per day. Your weekly track continues where you left off.'**
  String get dailyRewardHint;

  /// No description provided for @resetAppButton.
  ///
  /// In en, this message translates to:
  /// **'Reset App'**
  String get resetAppButton;

  /// No description provided for @resetAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset App?'**
  String get resetAppTitle;

  /// No description provided for @resetAppWarning.
  ///
  /// In en, this message translates to:
  /// **'This will delete all your progress, calibration data, and settings.\\n\\nYou\'ll restart from the beginning.\\n\\nAre you sure?'**
  String get resetAppWarning;

  /// No description provided for @resetAction.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetAction;

  /// No description provided for @resetSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'App reset! Restarting...'**
  String get resetSuccessMessage;

  /// No description provided for @selectYourCharacter.
  ///
  /// In en, this message translates to:
  /// **'Select Your Character'**
  String get selectYourCharacter;

  /// No description provided for @characterDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get characterDog;

  /// No description provided for @characterCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get characterCat;

  /// No description provided for @characterBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get characterBird;

  /// No description provided for @aiUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Zzz... Moji is dozing while the language link reconnects. Try again soon.'**
  String get aiUnavailableMessage;

  /// No description provided for @mojiDozingReconnect.
  ///
  /// In en, this message translates to:
  /// **'Moji is dozing while the language link reconnects.'**
  String get mojiDozingReconnect;

  /// No description provided for @mojiSleepingTapWake.
  ///
  /// In en, this message translates to:
  /// **'Moji is sleeping. Tap to wake up.'**
  String get mojiSleepingTapWake;

  /// No description provided for @mojiAwakeReady.
  ///
  /// In en, this message translates to:
  /// **'Moji is awake and ready!'**
  String get mojiAwakeReady;

  /// No description provided for @wardrobeTitle.
  ///
  /// In en, this message translates to:
  /// **'Wardrobe'**
  String get wardrobeTitle;

  /// No description provided for @slotHat.
  ///
  /// In en, this message translates to:
  /// **'Hat'**
  String get slotHat;

  /// No description provided for @slotNeck.
  ///
  /// In en, this message translates to:
  /// **'Neck'**
  String get slotNeck;

  /// No description provided for @slotFace.
  ///
  /// In en, this message translates to:
  /// **'Face'**
  String get slotFace;

  /// No description provided for @bodyTailColor.
  ///
  /// In en, this message translates to:
  /// **'Body & Tail Color'**
  String get bodyTailColor;

  /// No description provided for @eyeColor.
  ///
  /// In en, this message translates to:
  /// **'Eye Color'**
  String get eyeColor;

  /// No description provided for @eyeStyleSolid.
  ///
  /// In en, this message translates to:
  /// **'Solid'**
  String get eyeStyleSolid;

  /// No description provided for @eyeStyleOddEyed.
  ///
  /// In en, this message translates to:
  /// **'Odd-Eyed'**
  String get eyeStyleOddEyed;

  /// No description provided for @leftEye.
  ///
  /// In en, this message translates to:
  /// **'Left Eye'**
  String get leftEye;

  /// No description provided for @rightEye.
  ///
  /// In en, this message translates to:
  /// **'Right Eye'**
  String get rightEye;

  /// No description provided for @colorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get colorLabel;

  /// No description provided for @scenarioObjectives.
  ///
  /// In en, this message translates to:
  /// **'Objectives'**
  String get scenarioObjectives;

  /// Objectives completed out of the scenario total
  ///
  /// In en, this message translates to:
  /// **'{done}/{total}'**
  String scenarioProgress(int done, int total);

  /// No description provided for @scenarioCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get scenarioCleared;

  /// No description provided for @scenarioBonusLabel.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get scenarioBonusLabel;

  /// No description provided for @scenarioCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenario complete!'**
  String get scenarioCompleteTitle;

  /// Objective tally shown on the scenario completion popup
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} objectives'**
  String scenarioCompleteSummary(int done, int total);

  /// No description provided for @scenarioFirstClear.
  ///
  /// In en, this message translates to:
  /// **'First clear!'**
  String get scenarioFirstClear;

  /// No description provided for @scenarioReplayNote.
  ///
  /// In en, this message translates to:
  /// **'Replay reward — first clears pay more.'**
  String get scenarioReplayNote;

  /// No description provided for @scenarioContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get scenarioContinue;

  /// No description provided for @objCoffeeOrder.
  ///
  /// In en, this message translates to:
  /// **'Order a drink'**
  String get objCoffeeOrder;

  /// No description provided for @objCoffeeCustomize.
  ///
  /// In en, this message translates to:
  /// **'Customize your order'**
  String get objCoffeeCustomize;

  /// No description provided for @objCoffeePrice.
  ///
  /// In en, this message translates to:
  /// **'Ask what it costs'**
  String get objCoffeePrice;

  /// No description provided for @objCoffeeSmallTalk.
  ///
  /// In en, this message translates to:
  /// **'Make small talk with the barista'**
  String get objCoffeeSmallTalk;

  /// No description provided for @objInterviewGreet.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself'**
  String get objInterviewGreet;

  /// No description provided for @objInterviewExperience.
  ///
  /// In en, this message translates to:
  /// **'Describe your experience'**
  String get objInterviewExperience;

  /// No description provided for @objInterviewStrength.
  ///
  /// In en, this message translates to:
  /// **'Explain why you\'re a good fit'**
  String get objInterviewStrength;

  /// No description provided for @objInterviewAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask a question about the role'**
  String get objInterviewAsk;

  /// No description provided for @objDirectionsAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask how to get somewhere'**
  String get objDirectionsAsk;

  /// No description provided for @objDirectionsClarify.
  ///
  /// In en, this message translates to:
  /// **'Ask them to repeat or slow down'**
  String get objDirectionsClarify;

  /// No description provided for @objDirectionsDistance.
  ///
  /// In en, this message translates to:
  /// **'Find out how far it is'**
  String get objDirectionsDistance;

  /// No description provided for @objDirectionsThank.
  ///
  /// In en, this message translates to:
  /// **'Thank them properly'**
  String get objDirectionsThank;

  /// No description provided for @objDoctorSymptom.
  ///
  /// In en, this message translates to:
  /// **'Describe your symptoms'**
  String get objDoctorSymptom;

  /// No description provided for @objDoctorDuration.
  ///
  /// In en, this message translates to:
  /// **'Say how long it has been going on'**
  String get objDoctorDuration;

  /// No description provided for @objDoctorQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask what you should do'**
  String get objDoctorQuestion;

  /// No description provided for @objDoctorAllergy.
  ///
  /// In en, this message translates to:
  /// **'Mention an allergy or medication'**
  String get objDoctorAllergy;

  /// No description provided for @objShoppingFind.
  ///
  /// In en, this message translates to:
  /// **'Ask where an item is'**
  String get objShoppingFind;

  /// No description provided for @objShoppingSize.
  ///
  /// In en, this message translates to:
  /// **'Ask about size, color, or fit'**
  String get objShoppingSize;

  /// No description provided for @objShoppingPrice.
  ///
  /// In en, this message translates to:
  /// **'Ask the price'**
  String get objShoppingPrice;

  /// No description provided for @objShoppingPay.
  ///
  /// In en, this message translates to:
  /// **'Pay for it'**
  String get objShoppingPay;

  /// No description provided for @objRestaurantTable.
  ///
  /// In en, this message translates to:
  /// **'Ask for a table'**
  String get objRestaurantTable;

  /// No description provided for @objRestaurantOrder.
  ///
  /// In en, this message translates to:
  /// **'Order food'**
  String get objRestaurantOrder;

  /// No description provided for @objRestaurantDrink.
  ///
  /// In en, this message translates to:
  /// **'Order something to drink'**
  String get objRestaurantDrink;

  /// No description provided for @objRestaurantBill.
  ///
  /// In en, this message translates to:
  /// **'Ask for the bill'**
  String get objRestaurantBill;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Remind me about Moji'**
  String get notificationsEnable;

  /// No description provided for @notificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Moji will let you know when they need you, when reviews are due, and when your daily reward is ready.'**
  String get notificationsDesc;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications are turned off in your device settings.'**
  String get notificationsBlocked;

  /// No description provided for @notifPetChannelName.
  ///
  /// In en, this message translates to:
  /// **'Moji needs you'**
  String get notifPetChannelName;

  /// No description provided for @notifPetChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders when your pet is hungry or unhappy'**
  String get notifPetChannelDesc;

  /// No description provided for @notifReviewChannelName.
  ///
  /// In en, this message translates to:
  /// **'Review reminders'**
  String get notifReviewChannelName;

  /// No description provided for @notifReviewChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders when words are due for review'**
  String get notifReviewChannelDesc;

  /// No description provided for @notifRewardChannelName.
  ///
  /// In en, this message translates to:
  /// **'Daily reward'**
  String get notifRewardChannelName;

  /// No description provided for @notifRewardChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Reminders when your daily reward is ready'**
  String get notifRewardChannelDesc;

  /// No description provided for @notifPetHungryTitle.
  ///
  /// In en, this message translates to:
  /// **'Moji is hungry'**
  String get notifPetHungryTitle;

  /// No description provided for @notifPetHungryBody.
  ///
  /// In en, this message translates to:
  /// **'Your pet could really use a snack right about now.'**
  String get notifPetHungryBody;

  /// No description provided for @notifPetSadTitle.
  ///
  /// In en, this message translates to:
  /// **'Moji misses you'**
  String get notifPetSadTitle;

  /// No description provided for @notifPetSadBody.
  ///
  /// In en, this message translates to:
  /// **'It has been quiet without you. Come say hello?'**
  String get notifPetSadBody;

  /// No description provided for @notifReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to review'**
  String get notifReviewTitle;

  /// Body of the review-due notification
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word is waiting for you.} other{{count} words are waiting for you.}}'**
  String notifReviewBody(int count);

  /// No description provided for @notifRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily reward is ready'**
  String get notifRewardTitle;

  /// No description provided for @notifRewardBody.
  ///
  /// In en, this message translates to:
  /// **'Moji has something for you. Come and collect it!'**
  String get notifRewardBody;

  /// No description provided for @careTitle.
  ///
  /// In en, this message translates to:
  /// **'How is Moji?'**
  String get careTitle;

  /// No description provided for @careStatFullness.
  ///
  /// In en, this message translates to:
  /// **'Fullness'**
  String get careStatFullness;

  /// No description provided for @careStatHappiness.
  ///
  /// In en, this message translates to:
  /// **'Happiness'**
  String get careStatHappiness;

  /// No description provided for @careStatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get careStatHealth;

  /// No description provided for @careAllWell.
  ///
  /// In en, this message translates to:
  /// **'Moji is doing great.'**
  String get careAllWell;

  /// No description provided for @careNeedHungry.
  ///
  /// In en, this message translates to:
  /// **'Moji is hungry'**
  String get careNeedHungry;

  /// No description provided for @careNeedLonely.
  ///
  /// In en, this message translates to:
  /// **'Moji is feeling low'**
  String get careNeedLonely;

  /// No description provided for @careNeedSick.
  ///
  /// In en, this message translates to:
  /// **'Moji is sick'**
  String get careNeedSick;

  /// No description provided for @careSickPenalty.
  ///
  /// In en, this message translates to:
  /// **'While Moji is sick, all XP and coins are halved.'**
  String get careSickPenalty;

  /// No description provided for @careFeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Feed Moji'**
  String get careFeedTitle;

  /// No description provided for @careNoFood.
  ///
  /// In en, this message translates to:
  /// **'No food left. Visit the shop to stock up.'**
  String get careNoFood;

  /// No description provided for @careGoToShop.
  ///
  /// In en, this message translates to:
  /// **'Go to shop'**
  String get careGoToShop;

  /// No description provided for @carePlay.
  ///
  /// In en, this message translates to:
  /// **'Pet Moji'**
  String get carePlay;

  /// No description provided for @carePlayCooldown.
  ///
  /// In en, this message translates to:
  /// **'Moji has had enough fuss for now.'**
  String get carePlayCooldown;

  /// No description provided for @careClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get careClose;

  /// Confirmation after feeding an inventory item
  ///
  /// In en, this message translates to:
  /// **'Moji ate the {item}.'**
  String careFedItem(String item);

  /// Shows the player their current fullness while shopping for food
  ///
  /// In en, this message translates to:
  /// **'Fullness now: {value}%'**
  String careCurrentFullness(int value);

  /// No description provided for @scenarioSickPenalty.
  ///
  /// In en, this message translates to:
  /// **'Moji is sick — rewards halved'**
  String get scenarioSickPenalty;

  /// No description provided for @careDragToFeed.
  ///
  /// In en, this message translates to:
  /// **'Drag onto Moji to feed'**
  String get careDragToFeed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'cs',
        'da',
        'de',
        'el',
        'en',
        'es',
        'fi',
        'fr',
        'hi',
        'hu',
        'id',
        'it',
        'ja',
        'ko',
        'nl',
        'no',
        'pl',
        'pt',
        'ro',
        'ru',
        'sv',
        'th',
        'tr',
        'uk',
        'vi',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
