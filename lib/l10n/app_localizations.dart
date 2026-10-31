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

  /// No description provided for @quizDesc.
  ///
  /// In en, this message translates to:
  /// **'Test your knowledge with active recall quizzes.'**
  String get quizDesc;

  /// No description provided for @scenarios.
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get scenarios;

  /// No description provided for @scenariosDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice real-life conversations like ordering coffee or job interviews.'**
  String get scenariosDesc;

  /// The school building in the town: where the quizzes are. Shown on its card and under it.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get townSchool;

  /// The cafe building in the town. Shown on its card; the go button names what is practised there.
  ///
  /// In en, this message translates to:
  /// **'Café'**
  String get placeCafe;

  /// The town hall building in the town (where the job interview is).
  ///
  /// In en, this message translates to:
  /// **'Town Hall'**
  String get placeTownHall;

  /// The gazebo in the town (where the player asks for directions).
  ///
  /// In en, this message translates to:
  /// **'Gazebo'**
  String get placeGazebo;

  /// The hospital building in the town (where the doctor scene is).
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get placeHospital;

  /// The shop building in the town (where the shopping scene is).
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get placeShop;

  /// Label of the bottom navigation tab that opens the town (the map of buildings, with the school where the quizzes are).
  ///
  /// In en, this message translates to:
  /// **'Town'**
  String get townTab;

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

  /// No description provided for @shopItemDonutName.
  ///
  /// In en, this message translates to:
  /// **'Donut'**
  String get shopItemDonutName;

  /// No description provided for @shopItemDonutDescription.
  ///
  /// In en, this message translates to:
  /// **'Sweet and sticky.'**
  String get shopItemDonutDescription;

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

  /// No description provided for @sceneryTitle.
  ///
  /// In en, this message translates to:
  /// **'Scenery'**
  String get sceneryTitle;

  /// No description provided for @shopItemBgMeadowName.
  ///
  /// In en, this message translates to:
  /// **'Meadow'**
  String get shopItemBgMeadowName;

  /// No description provided for @sceneInUse.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get sceneInUse;

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

  /// No description provided for @mojiSleepNight.
  ///
  /// In en, this message translates to:
  /// **'Shhh... Moji is sleeping. Tap Moji to wake up.'**
  String get mojiSleepNight;

  /// No description provided for @mojiWakeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Yawn... Moji is awake now. Let\'s practice!'**
  String get mojiWakeSuccess;

  /// No description provided for @mojiAwakeFor.
  ///
  /// In en, this message translates to:
  /// **'Awake for {minutes} min'**
  String mojiAwakeFor(int minutes);

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

  /// No description provided for @characterRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get characterRabbit;

  /// No description provided for @characterHamster.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get characterHamster;

  /// No description provided for @characterParrot.
  ///
  /// In en, this message translates to:
  /// **'Parrot'**
  String get characterParrot;

  /// No description provided for @characterFox.
  ///
  /// In en, this message translates to:
  /// **'Fox'**
  String get characterFox;

  /// No description provided for @characterRaccoon.
  ///
  /// In en, this message translates to:
  /// **'Raccoon'**
  String get characterRaccoon;

  /// No description provided for @characterRedPanda.
  ///
  /// In en, this message translates to:
  /// **'Red Panda'**
  String get characterRedPanda;

  /// No description provided for @characterSkunk.
  ///
  /// In en, this message translates to:
  /// **'Skunk'**
  String get characterSkunk;

  /// No description provided for @characterOtter.
  ///
  /// In en, this message translates to:
  /// **'Otter'**
  String get characterOtter;

  /// No description provided for @characterBeaver.
  ///
  /// In en, this message translates to:
  /// **'Beaver'**
  String get characterBeaver;

  /// No description provided for @characterSquirrel.
  ///
  /// In en, this message translates to:
  /// **'Squirrel'**
  String get characterSquirrel;

  /// No description provided for @characterChinchilla.
  ///
  /// In en, this message translates to:
  /// **'Chinchilla'**
  String get characterChinchilla;

  /// No description provided for @characterMouse.
  ///
  /// In en, this message translates to:
  /// **'Mouse'**
  String get characterMouse;

  /// No description provided for @characterHedgehog.
  ///
  /// In en, this message translates to:
  /// **'Hedgehog'**
  String get characterHedgehog;

  /// No description provided for @characterBat.
  ///
  /// In en, this message translates to:
  /// **'Bat'**
  String get characterBat;

  /// No description provided for @characterFennec.
  ///
  /// In en, this message translates to:
  /// **'Fennec'**
  String get characterFennec;

  /// No description provided for @characterKoala.
  ///
  /// In en, this message translates to:
  /// **'Koala'**
  String get characterKoala;

  /// No description provided for @characterWombat.
  ///
  /// In en, this message translates to:
  /// **'Wombat'**
  String get characterWombat;

  /// No description provided for @characterPanda.
  ///
  /// In en, this message translates to:
  /// **'Panda'**
  String get characterPanda;

  /// No description provided for @characterSloth.
  ///
  /// In en, this message translates to:
  /// **'Sloth'**
  String get characterSloth;

  /// No description provided for @characterCapybara.
  ///
  /// In en, this message translates to:
  /// **'Capybara'**
  String get characterCapybara;

  /// No description provided for @characterPiglet.
  ///
  /// In en, this message translates to:
  /// **'Piglet'**
  String get characterPiglet;

  /// No description provided for @characterSeal.
  ///
  /// In en, this message translates to:
  /// **'Seal'**
  String get characterSeal;

  /// No description provided for @characterPenguin.
  ///
  /// In en, this message translates to:
  /// **'Penguin'**
  String get characterPenguin;

  /// No description provided for @characterFrog.
  ///
  /// In en, this message translates to:
  /// **'Frog'**
  String get characterFrog;

  /// No description provided for @characterAxolotl.
  ///
  /// In en, this message translates to:
  /// **'Axolotl'**
  String get characterAxolotl;

  /// No description provided for @characterGecko.
  ///
  /// In en, this message translates to:
  /// **'Gecko'**
  String get characterGecko;

  /// No description provided for @characterChameleon.
  ///
  /// In en, this message translates to:
  /// **'Chameleon'**
  String get characterChameleon;

  /// No description provided for @aiUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Zzz... Moji is dozing while the language link reconnects. Try again soon.'**
  String get aiUnavailableMessage;

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

  /// No description provided for @beakColor.
  ///
  /// In en, this message translates to:
  /// **'Beak Color'**
  String get beakColor;

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

  /// No description provided for @scenarioFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get scenarioFinish;

  /// No description provided for @scenarioFinishTitle.
  ///
  /// In en, this message translates to:
  /// **'End the scene?'**
  String get scenarioFinishTitle;

  /// No description provided for @scenarioFinishBody.
  ///
  /// In en, this message translates to:
  /// **'Some objectives are still open. Finishing now pays partial credit, and the scenario stays unfinished so you can clear it properly later.'**
  String get scenarioFinishBody;

  /// No description provided for @scenarioFinishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Finish anyway'**
  String get scenarioFinishConfirm;

  /// No description provided for @scenarioFinishCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep talking'**
  String get scenarioFinishCancel;

  /// No description provided for @scenarioPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Scene ended'**
  String get scenarioPartialTitle;

  /// No description provided for @scenarioPartialNote.
  ///
  /// In en, this message translates to:
  /// **'Partial credit — clear every objective for the full reward.'**
  String get scenarioPartialNote;

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

  /// No description provided for @playCatch.
  ///
  /// In en, this message translates to:
  /// **'Play catch'**
  String get playCatch;

  /// No description provided for @playCatchAgain.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playCatchAgain;

  /// No description provided for @playToyChest.
  ///
  /// In en, this message translates to:
  /// **'Toy chest'**
  String get playToyChest;

  /// No description provided for @playBubbleBath.
  ///
  /// In en, this message translates to:
  /// **'Bubble bath'**
  String get playBubbleBath;

  /// No description provided for @playPounce.
  ///
  /// In en, this message translates to:
  /// **'Pounce'**
  String get playPounce;

  /// No description provided for @playPondHop.
  ///
  /// In en, this message translates to:
  /// **'Pond hop'**
  String get playPondHop;

  /// No description provided for @playFetchWords.
  ///
  /// In en, this message translates to:
  /// **'Fetch the words'**
  String get playFetchWords;

  /// No description provided for @playNeedsWords.
  ///
  /// In en, this message translates to:
  /// **'Learn a few more words to play'**
  String get playNeedsWords;

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

  /// No description provided for @bondStageCurious.
  ///
  /// In en, this message translates to:
  /// **'Curious'**
  String get bondStageCurious;

  /// No description provided for @bondStageFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get bondStageFriendly;

  /// No description provided for @bondStageAttached.
  ///
  /// In en, this message translates to:
  /// **'Attached'**
  String get bondStageAttached;

  /// No description provided for @bondStageDevoted.
  ///
  /// In en, this message translates to:
  /// **'Devoted'**
  String get bondStageDevoted;

  /// No description provided for @bondStageInseparable.
  ///
  /// In en, this message translates to:
  /// **'Inseparable'**
  String get bondStageInseparable;

  /// No description provided for @bondMissesYou.
  ///
  /// In en, this message translates to:
  /// **'Moji misses you'**
  String get bondMissesYou;

  /// No description provided for @bondLonely.
  ///
  /// In en, this message translates to:
  /// **'Moji has been waiting for you'**
  String get bondLonely;

  /// No description provided for @aiLimitQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s AI quizzes are used up'**
  String get aiLimitQuizTitle;

  /// No description provided for @aiLimitMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s AI messages are used up'**
  String get aiLimitMessageTitle;

  /// No description provided for @aiLimitUsage.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total} used today'**
  String aiLimitUsage(int used, int total);

  /// No description provided for @aiLimitResets.
  ///
  /// In en, this message translates to:
  /// **'Your allowance comes back tomorrow.'**
  String get aiLimitResets;

  /// No description provided for @aiLimitReviewOpen.
  ///
  /// In en, this message translates to:
  /// **'Review never needs the tutor — your due cards are always there.'**
  String get aiLimitReviewOpen;

  /// No description provided for @aiLimitQuizOpen.
  ///
  /// In en, this message translates to:
  /// **'Quizzes built from your own words are still there.'**
  String get aiLimitQuizOpen;

  /// No description provided for @aiLimitWatchAd.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad for one more'**
  String get aiLimitWatchAd;

  /// No description provided for @aiLimitGoPlus.
  ///
  /// In en, this message translates to:
  /// **'Get Mimikin Plus'**
  String get aiLimitGoPlus;

  /// No description provided for @premiumColumnFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get premiumColumnFree;

  /// No description provided for @premiumColumnPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get premiumColumnPlus;

  /// No description provided for @premiumRowQuizzes.
  ///
  /// In en, this message translates to:
  /// **'AI quizzes a day'**
  String get premiumRowQuizzes;

  /// No description provided for @premiumRowMessages.
  ///
  /// In en, this message translates to:
  /// **'AI messages a day'**
  String get premiumRowMessages;

  /// No description provided for @premiumRowAds.
  ///
  /// In en, this message translates to:
  /// **'Interstitial ads'**
  String get premiumRowAds;

  /// No description provided for @premiumValueShown.
  ///
  /// In en, this message translates to:
  /// **'Shown'**
  String get premiumValueShown;

  /// No description provided for @premiumValueNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get premiumValueNone;

  /// No description provided for @premiumRowRollover.
  ///
  /// In en, this message translates to:
  /// **'Unused quizzes'**
  String get premiumRowRollover;

  /// No description provided for @premiumValueExpire.
  ///
  /// In en, this message translates to:
  /// **'Expire'**
  String get premiumValueExpire;

  /// No description provided for @premiumValueRollOver.
  ///
  /// In en, this message translates to:
  /// **'Roll over'**
  String get premiumValueRollOver;

  /// No description provided for @premiumRowPetStats.
  ///
  /// In en, this message translates to:
  /// **'Pet stats'**
  String get premiumRowPetStats;

  /// No description provided for @premiumValueDecay.
  ///
  /// In en, this message translates to:
  /// **'Decay'**
  String get premiumValueDecay;

  /// No description provided for @premiumValueDecaySlower.
  ///
  /// In en, this message translates to:
  /// **'Decay slower'**
  String get premiumValueDecaySlower;

  /// No description provided for @premiumComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are not open yet.'**
  String get premiumComingSoon;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Mimikin Plus is active.'**
  String get premiumActive;

  /// No description provided for @premiumRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore a purchase'**
  String get premiumRestore;

  /// No description provided for @premiumRestoreDone.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore on this account.'**
  String get premiumRestoreDone;

  /// No description provided for @premiumPurchasePending.
  ///
  /// In en, this message translates to:
  /// **'Finishing with the store…'**
  String get premiumPurchasePending;

  /// No description provided for @categoryStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get categoryStyle;

  /// No description provided for @accessoryDescription.
  ///
  /// In en, this message translates to:
  /// **'A little something for Moji to wear.'**
  String get accessoryDescription;

  /// Shown on a wardrobe tile that a bond stage has not unlocked yet
  ///
  /// In en, this message translates to:
  /// **'Unlocks at {stage}'**
  String accessoryUnlocksAt(String stage);

  /// No description provided for @accessoryEarnedNotSold.
  ///
  /// In en, this message translates to:
  /// **'Earned, not sold'**
  String get accessoryEarnedNotSold;

  /// No description provided for @accessoryCapName.
  ///
  /// In en, this message translates to:
  /// **'Cap'**
  String get accessoryCapName;

  /// No description provided for @accessoryTopHatName.
  ///
  /// In en, this message translates to:
  /// **'Top Hat'**
  String get accessoryTopHatName;

  /// No description provided for @accessoryCowboyHatName.
  ///
  /// In en, this message translates to:
  /// **'Cowboy Hat'**
  String get accessoryCowboyHatName;

  /// No description provided for @accessoryCrownName.
  ///
  /// In en, this message translates to:
  /// **'Crown'**
  String get accessoryCrownName;

  /// No description provided for @accessoryPartyHatName.
  ///
  /// In en, this message translates to:
  /// **'Party Hat'**
  String get accessoryPartyHatName;

  /// No description provided for @accessoryBowTieName.
  ///
  /// In en, this message translates to:
  /// **'Bow Tie'**
  String get accessoryBowTieName;

  /// No description provided for @accessoryNecklaceName.
  ///
  /// In en, this message translates to:
  /// **'Necklace'**
  String get accessoryNecklaceName;

  /// No description provided for @accessoryMustacheName.
  ///
  /// In en, this message translates to:
  /// **'Mustache'**
  String get accessoryMustacheName;

  /// No description provided for @accessoryBeanieName.
  ///
  /// In en, this message translates to:
  /// **'Beanie'**
  String get accessoryBeanieName;

  /// No description provided for @accessoryMortarboardName.
  ///
  /// In en, this message translates to:
  /// **'Graduation Cap'**
  String get accessoryMortarboardName;

  /// No description provided for @accessoryCollarName.
  ///
  /// In en, this message translates to:
  /// **'Bell Collar'**
  String get accessoryCollarName;

  /// No description provided for @accessoryGlassesName.
  ///
  /// In en, this message translates to:
  /// **'Glasses'**
  String get accessoryGlassesName;

  /// No description provided for @accessorySunglassesName.
  ///
  /// In en, this message translates to:
  /// **'Sunglasses'**
  String get accessorySunglassesName;

  /// No description provided for @accessoryMaskName.
  ///
  /// In en, this message translates to:
  /// **'Masquerade Mask'**
  String get accessoryMaskName;

  /// No description provided for @accessoryMedalName.
  ///
  /// In en, this message translates to:
  /// **'Medal'**
  String get accessoryMedalName;

  /// No description provided for @accessoryScarfName.
  ///
  /// In en, this message translates to:
  /// **'Scarf'**
  String get accessoryScarfName;

  /// No description provided for @accessoryHeadphonesName.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get accessoryHeadphonesName;

  /// No description provided for @accessoryWizardHatName.
  ///
  /// In en, this message translates to:
  /// **'Wizard Hat'**
  String get accessoryWizardHatName;

  /// No description provided for @accessoryFlowerCrownName.
  ///
  /// In en, this message translates to:
  /// **'Flower Crown'**
  String get accessoryFlowerCrownName;

  /// No description provided for @onboardingLanguageQuestion.
  ///
  /// In en, this message translates to:
  /// **'What language do you speak?'**
  String get onboardingLanguageQuestion;

  /// No description provided for @onboardingLanguageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingLanguageConfirm;

  /// No description provided for @onboardingPetQuestion.
  ///
  /// In en, this message translates to:
  /// **'Who will you take home?'**
  String get onboardingPetQuestion;

  /// No description provided for @onboardingPetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get onboardingPetConfirm;

  /// No description provided for @onboardingLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Save your pet'**
  String get onboardingLoginTitle;

  /// No description provided for @onboardingLoginGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get onboardingLoginGoogle;

  /// No description provided for @onboardingLoginEmail.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get onboardingLoginEmail;

  /// No description provided for @onboardingLoginSkip.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get onboardingLoginSkip;

  /// No description provided for @onboardingLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in so you never lose them.'**
  String get onboardingLoginSubtitle;

  /// No description provided for @accountEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmailLabel;

  /// No description provided for @accountPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get accountPasswordLabel;

  /// No description provided for @accountContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accountContinueAction;

  /// No description provided for @accountConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Two pets'**
  String get accountConflictTitle;

  /// Shown when the account being linked already owns a save
  ///
  /// In en, this message translates to:
  /// **'{email} already has a pet, and so does this phone. Only one can be kept.'**
  String accountConflictBody(String email);

  /// No description provided for @accountConflictKeepThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Keep this phone\'s pet'**
  String get accountConflictKeepThisDevice;

  /// No description provided for @accountConflictUseSaved.
  ///
  /// In en, this message translates to:
  /// **'Use the saved pet'**
  String get accountConflictUseSaved;

  /// No description provided for @accountErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'That is not a valid email address.'**
  String get accountErrorInvalidEmail;

  /// No description provided for @accountErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get accountErrorWeakPassword;

  /// No description provided for @accountErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your details and try again.'**
  String get accountErrorSignIn;

  /// No description provided for @adsFreeCoins.
  ///
  /// In en, this message translates to:
  /// **'Free Coins'**
  String get adsFreeCoins;

  /// No description provided for @adsWatchForCoins.
  ///
  /// In en, this message translates to:
  /// **'Watch a video for +{coins}'**
  String adsWatchForCoins(int coins);

  /// No description provided for @adsLeftToday.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {total} left today'**
  String adsLeftToday(int remaining, int total);

  /// No description provided for @adsNoneLeftToday.
  ///
  /// In en, this message translates to:
  /// **'That\'s all for today'**
  String get adsNoneLeftToday;

  /// No description provided for @adsNotReady.
  ///
  /// In en, this message translates to:
  /// **'No video available right now'**
  String get adsNotReady;

  /// No description provided for @adsEarnedCoins.
  ///
  /// In en, this message translates to:
  /// **'+{coins} coins!'**
  String adsEarnedCoins(int coins);

  /// Shown when the app removed personal data from a message before sending it to the AI.
  ///
  /// In en, this message translates to:
  /// **'Personal details were hidden before sending.'**
  String get privacyRedactedNotice;

  /// Badge over the quiz card: which question of how many
  ///
  /// In en, this message translates to:
  /// **'QUESTION {current}/{total}'**
  String quizQuestionCounter(int current, int total);

  /// No description provided for @quizPreparing.
  ///
  /// In en, this message translates to:
  /// **'PREPARING...'**
  String get quizPreparing;

  /// No description provided for @quizPickAnswer.
  ///
  /// In en, this message translates to:
  /// **'Pick the right answer'**
  String get quizPickAnswer;

  /// No description provided for @quizWellDone.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get quizWellDone;

  /// No description provided for @quizEncouragement.
  ///
  /// In en, this message translates to:
  /// **'You got this!'**
  String get quizEncouragement;

  /// What the pet says once the player has petted it for the first time
  ///
  /// In en, this message translates to:
  /// **'Nice to meet you, {name}! Let us learn together.'**
  String petTutorialWelcome(String name);

  /// Title of the dialog offering a guided tour of the current page
  ///
  /// In en, this message translates to:
  /// **'NEED A TOUR?'**
  String get tutorialOfferTitle;

  /// Button that starts the guided tour
  ///
  /// In en, this message translates to:
  /// **'SHOW ME'**
  String get tutorialWatch;

  /// Button that declines or leaves a guided tour
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get tutorialSkip;

  /// Advances to the next step of a guided tour
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get tutorialNext;

  /// Returns to the previous step of a guided tour
  ///
  /// In en, this message translates to:
  /// **'BACK'**
  String get tutorialBack;

  /// Finishes a guided tour, shown on its last step
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get tutorialDone;

  /// Settings row that puts every guided tour back on offer
  ///
  /// In en, this message translates to:
  /// **'Replay tutorials'**
  String get tutorialReplay;

  /// No description provided for @tutorialOfferHome.
  ///
  /// In en, this message translates to:
  /// **'Want a quick tour of your home screen?'**
  String get tutorialOfferHome;

  /// No description provided for @tutorialOfferQuiz.
  ///
  /// In en, this message translates to:
  /// **'First quiz. Want a quick tour?'**
  String get tutorialOfferQuiz;

  /// No description provided for @tutorialOfferChat.
  ///
  /// In en, this message translates to:
  /// **'First chat. Want a quick tour?'**
  String get tutorialOfferChat;

  /// No description provided for @tutorialOfferShop.
  ///
  /// In en, this message translates to:
  /// **'First visit to the shop. Want a quick tour?'**
  String get tutorialOfferShop;

  /// No description provided for @tutorialOfferProfile.
  ///
  /// In en, this message translates to:
  /// **'Want a quick tour of your profile?'**
  String get tutorialOfferProfile;

  /// No description provided for @tutorialOfferReview.
  ///
  /// In en, this message translates to:
  /// **'First review session. Want a quick tour?'**
  String get tutorialOfferReview;

  /// No description provided for @tutorialHomePet.
  ///
  /// In en, this message translates to:
  /// **'This is Moji. Tap it, or drag across its head to scratch.'**
  String get tutorialHomePet;

  /// No description provided for @tutorialHomeLevel.
  ///
  /// In en, this message translates to:
  /// **'Your level and XP. Tap to see what the next levels unlock.'**
  String get tutorialHomeLevel;

  /// No description provided for @tutorialHomeFeed.
  ///
  /// In en, this message translates to:
  /// **'Your food. Pick a snack, then drag it onto Moji.'**
  String get tutorialHomeFeed;

  /// No description provided for @tutorialHomeCare.
  ///
  /// In en, this message translates to:
  /// **'This appears when Moji needs something. Tap to check on it.'**
  String get tutorialHomeCare;

  /// No description provided for @tutorialHomeReview.
  ///
  /// In en, this message translates to:
  /// **'Study: review the words that are due, and look back at your mistakes.'**
  String get tutorialHomeReview;

  /// No description provided for @tutorialHomeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings: pixel text, reminders, and replaying these tours.'**
  String get tutorialHomeSettings;

  /// Home tour step pointing at the Town tab in the bottom bar.
  ///
  /// In en, this message translates to:
  /// **'Town: step into a building to practise a conversation, or visit the school for a quiz.'**
  String get tutorialNavTown;

  /// No description provided for @tutorialNavChat.
  ///
  /// In en, this message translates to:
  /// **'Chats: longer conversations, and roleplay scenarios.'**
  String get tutorialNavChat;

  /// No description provided for @tutorialNavShop.
  ///
  /// In en, this message translates to:
  /// **'Shop: spend coins on food, styles and new worlds.'**
  String get tutorialNavShop;

  /// No description provided for @tutorialNavProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile: your stats, your languages and your account.'**
  String get tutorialNavProfile;

  /// No description provided for @tutorialQuizHeader.
  ///
  /// In en, this message translates to:
  /// **'Your level, and the pause button for when you need to stop.'**
  String get tutorialQuizHeader;

  /// No description provided for @tutorialQuizQuestion.
  ///
  /// In en, this message translates to:
  /// **'The question. The badge above says what it is testing.'**
  String get tutorialQuizQuestion;

  /// No description provided for @tutorialQuizOptions.
  ///
  /// In en, this message translates to:
  /// **'Pick an answer. Wrong ones are saved so you can review them later.'**
  String get tutorialQuizOptions;

  /// No description provided for @tutorialQuizContinue.
  ///
  /// In en, this message translates to:
  /// **'Move on once you have answered.'**
  String get tutorialQuizContinue;

  /// No description provided for @tutorialChatMenu.
  ///
  /// In en, this message translates to:
  /// **'Your past chats and roleplay scenarios live behind this button.'**
  String get tutorialChatMenu;

  /// No description provided for @tutorialChatMessages.
  ///
  /// In en, this message translates to:
  /// **'Your conversation. Mistakes get gently corrected as you go.'**
  String get tutorialChatMessages;

  /// No description provided for @tutorialChatInput.
  ///
  /// In en, this message translates to:
  /// **'Write here. Do not worry about getting it perfect.'**
  String get tutorialChatInput;

  /// No description provided for @tutorialShopCoins.
  ///
  /// In en, this message translates to:
  /// **'Your coins. Earn them by practising and caring for Moji.'**
  String get tutorialShopCoins;

  /// No description provided for @tutorialShopTabs.
  ///
  /// In en, this message translates to:
  /// **'Filter by what you are after: food, decor or style.'**
  String get tutorialShopTabs;

  /// No description provided for @tutorialShopGrid.
  ///
  /// In en, this message translates to:
  /// **'Tap anything to buy it. Food gets used up, the rest is yours to keep.'**
  String get tutorialShopGrid;

  /// No description provided for @tutorialShopFreeCoins.
  ///
  /// In en, this message translates to:
  /// **'Out of coins? Watch a short clip to top up.'**
  String get tutorialShopFreeCoins;

  /// No description provided for @tutorialProfileAvatar.
  ///
  /// In en, this message translates to:
  /// **'Tap Moji to change its look and its wardrobe.'**
  String get tutorialProfileAvatar;

  /// No description provided for @tutorialProfileStats.
  ///
  /// In en, this message translates to:
  /// **'Your level, and how far you are from the next one.'**
  String get tutorialProfileStats;

  /// No description provided for @tutorialProfileDaily.
  ///
  /// In en, this message translates to:
  /// **'Come back each day for a reward. Longer streaks pay better.'**
  String get tutorialProfileDaily;

  /// No description provided for @tutorialProfileLanguages.
  ///
  /// In en, this message translates to:
  /// **'What you speak, and what you are learning. Change either any time.'**
  String get tutorialProfileLanguages;

  /// No description provided for @tutorialProfileAccount.
  ///
  /// In en, this message translates to:
  /// **'Link an account so Moji survives a new phone.'**
  String get tutorialProfileAccount;

  /// No description provided for @tutorialReviewCard.
  ///
  /// In en, this message translates to:
  /// **'Try to recall the answer, then tap the card to check.'**
  String get tutorialReviewCard;

  /// No description provided for @tutorialReviewGrades.
  ///
  /// In en, this message translates to:
  /// **'Reveal the answer, then say how it went. Cards you found hard come back sooner.'**
  String get tutorialReviewGrades;

  /// No description provided for @tutorialReviewCount.
  ///
  /// In en, this message translates to:
  /// **'How many cards are left in this session.'**
  String get tutorialReviewCount;

  /// No description provided for @seasonPassNotOnSale.
  ///
  /// In en, this message translates to:
  /// **'This pass is not on sale yet.'**
  String get seasonPassNotOnSale;

  /// No description provided for @seasonPassBuy.
  ///
  /// In en, this message translates to:
  /// **'Buy {price}'**
  String seasonPassBuy(String price);

  /// No description provided for @seasonPassClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim ({count})'**
  String seasonPassClaim(int count);

  /// No description provided for @seasonPassClaiming.
  ///
  /// In en, this message translates to:
  /// **'Claiming…'**
  String get seasonPassClaiming;

  /// No description provided for @seasonPassClaimedToast.
  ///
  /// In en, this message translates to:
  /// **'Claimed: {count}'**
  String seasonPassClaimedToast(int count);

  /// No description provided for @seasonPassTierOf.
  ///
  /// In en, this message translates to:
  /// **'Tier {tier} / {total}'**
  String seasonPassTierOf(int tier, int total);

  /// No description provided for @seasonPassTrackLength.
  ///
  /// In en, this message translates to:
  /// **'{count} pieces · {xp} XP'**
  String seasonPassTrackLength(int count, int xp);

  /// No description provided for @seasonPassComplete.
  ///
  /// In en, this message translates to:
  /// **'Track complete.'**
  String get seasonPassComplete;

  /// No description provided for @seasonPassXpToNext.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP to the next piece'**
  String seasonPassXpToNext(int xp);

  /// No description provided for @seasonPassTierCost.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP'**
  String seasonPassTierCost(int xp);

  /// No description provided for @seasonPassReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get seasonPassReady;

  /// No description provided for @seasonPassTierClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get seasonPassTierClaimed;

  /// No description provided for @seasonPassTryOn.
  ///
  /// In en, this message translates to:
  /// **'Try it on'**
  String get seasonPassTryOn;

  /// Name of the airfield scene handed over by the last season pass tier. The airport-sign sense of the word.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get sceneAirfieldName;

  /// Name of the cozy room scene: the room with a window, a shelf and a round rug that new players start in.
  ///
  /// In en, this message translates to:
  /// **'Cozy Room'**
  String get sceneCozyRoomName;

  /// Name of the enchanted meadow scene: a lavender-sky meadow with a wizard tower, giant mushrooms and a corner moon.
  ///
  /// In en, this message translates to:
  /// **'Enchanted Meadow'**
  String get sceneEnchantedMeadowName;

  /// Name of the mushroom glade scene: a clearing of giant red toadstools on cool jade moss.
  ///
  /// In en, this message translates to:
  /// **'Mushroom Glade'**
  String get sceneMushroomGladeName;

  /// Name of the pumpkin patch scene: a crooked witch's house, a cauldron and jack-o'-lanterns on green grass under a lavender sky. Season two pass content.
  ///
  /// In en, this message translates to:
  /// **'Pumpkin Patch'**
  String get scenePumpkinPatchName;

  /// No description provided for @seasonPassScenePreviewOwned.
  ///
  /// In en, this message translates to:
  /// **'Yours. Change worlds any time in the wardrobe.'**
  String get seasonPassScenePreviewOwned;

  /// No description provided for @seasonPassPreviewOwned.
  ///
  /// In en, this message translates to:
  /// **'Yours. Put it on in the wardrobe.'**
  String get seasonPassPreviewOwned;

  /// No description provided for @seasonPassPreviewLocked.
  ///
  /// In en, this message translates to:
  /// **'Not yours yet — this is only a look.'**
  String get seasonPassPreviewLocked;

  /// No description provided for @seasonPassPromise.
  ///
  /// In en, this message translates to:
  /// **'Tiers are owed XP you earn after buying the pass, so buying it late costs you nothing. Nothing here expires: a tier you have reached stays reached, and one you have not stays waiting.'**
  String get seasonPassPromise;

  /// No description provided for @seasonPassWaitingToClaim.
  ///
  /// In en, this message translates to:
  /// **'Waiting to claim: {count}'**
  String seasonPassWaitingToClaim(int count);

  /// No description provided for @seasonPassEarnedByStudying.
  ///
  /// In en, this message translates to:
  /// **'Earned by studying'**
  String get seasonPassEarnedByStudying;

  /// No description provided for @accessoryBandanaName.
  ///
  /// In en, this message translates to:
  /// **'Sunrise Bandana'**
  String get accessoryBandanaName;

  /// No description provided for @accessoryBandanaCloudName.
  ///
  /// In en, this message translates to:
  /// **'Cloud Bandana'**
  String get accessoryBandanaCloudName;

  /// No description provided for @accessoryScarfDuskName.
  ///
  /// In en, this message translates to:
  /// **'Dusk Scarf'**
  String get accessoryScarfDuskName;

  /// No description provided for @accessoryGogglesName.
  ///
  /// In en, this message translates to:
  /// **'Flight Goggles'**
  String get accessoryGogglesName;

  /// No description provided for @accessoryGogglesBrassName.
  ///
  /// In en, this message translates to:
  /// **'Brass Goggles'**
  String get accessoryGogglesBrassName;

  /// No description provided for @accessoryBeanieDuskName.
  ///
  /// In en, this message translates to:
  /// **'Dusk Beanie'**
  String get accessoryBeanieDuskName;

  /// No description provided for @accessoryFlightCapName.
  ///
  /// In en, this message translates to:
  /// **'Flight Cap'**
  String get accessoryFlightCapName;

  /// No description provided for @accessoryFlightCapCloudName.
  ///
  /// In en, this message translates to:
  /// **'Cloud Flight Cap'**
  String get accessoryFlightCapCloudName;

  /// No description provided for @accessoryCowboyHatCharcoalName.
  ///
  /// In en, this message translates to:
  /// **'Charcoal Cowboy Hat'**
  String get accessoryCowboyHatCharcoalName;

  /// No description provided for @accessoryFlightScarfName.
  ///
  /// In en, this message translates to:
  /// **'Windswept Scarf'**
  String get accessoryFlightScarfName;

  /// No description provided for @accessoryPumpkinWitchName.
  ///
  /// In en, this message translates to:
  /// **'Pumpkin Witch Hat'**
  String get accessoryPumpkinWitchName;

  /// No description provided for @accessoryDevilBandName.
  ///
  /// In en, this message translates to:
  /// **'Devil-Horn Headband'**
  String get accessoryDevilBandName;

  /// No description provided for @accessoryGhostBandanaName.
  ///
  /// In en, this message translates to:
  /// **'Ghost Bandana'**
  String get accessoryGhostBandanaName;

  /// No description provided for @accessoryBatChokerName.
  ///
  /// In en, this message translates to:
  /// **'Bat Choker'**
  String get accessoryBatChokerName;

  /// No description provided for @shopSectionTopUp.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get shopSectionTopUp;

  /// No description provided for @shopSectionPlus.
  ///
  /// In en, this message translates to:
  /// **'Plus'**
  String get shopSectionPlus;

  /// No description provided for @shopSectionPass.
  ///
  /// In en, this message translates to:
  /// **'Season Pass'**
  String get shopSectionPass;

  /// No description provided for @shopSectionItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get shopSectionItems;

  /// No description provided for @topUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Up'**
  String get topUpTitle;

  /// No description provided for @topUpCoins.
  ///
  /// In en, this message translates to:
  /// **'{coins} coins'**
  String topUpCoins(int coins);

  /// No description provided for @topUpBonus.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% coins'**
  String topUpBonus(int percent);

  /// No description provided for @topUpBestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get topUpBestValue;

  /// No description provided for @topUpNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Coin packs are not open yet.'**
  String get topUpNotOpen;

  /// No description provided for @topUpThanks.
  ///
  /// In en, this message translates to:
  /// **'Added {coins} coins.'**
  String topUpThanks(int coins);

  /// No description provided for @deleteAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountButton;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your pet, your progress, your chats and your account, on this phone and in the cloud. It cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account and data were deleted.'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Check your connection and try again.'**
  String get deleteAccountFailed;

  /// No description provided for @privacyPolicyButton.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyButton;

  /// No description provided for @privacyPolicyOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link.'**
  String get privacyPolicyOpenFailed;
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
