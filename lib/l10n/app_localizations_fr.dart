// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get header => 'Paramètres de langue';

  @override
  String get iSpeak => 'Je parle';

  @override
  String get imLearning => 'J\'apprends';

  @override
  String get currentSelection => 'Sélection actuelle :';

  @override
  String get level => 'Niveau';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Série';

  @override
  String get audio => 'Voix du bot';

  @override
  String get designMojiBtn => 'Créer ton Moji';

  @override
  String get quizMode => 'Quiz';

  @override
  String get quizDesc => 'Teste tes connaissances.';

  @override
  String get scenarios => 'Scénarios';

  @override
  String get scenariosDesc => 'Pratique des conversations réelles.';

  @override
  String get profile => 'Profil';

  @override
  String get shop => 'Boutique';

  @override
  String get mistakes => 'ERREURS';

  @override
  String get noMistakesYet => 'PAS ENCORE D\'ERREURS!';

  @override
  String get profileDesc => 'Voir tes stats et réglages.';

  @override
  String get voiceCall => 'Appel vocal';

  @override
  String get voiceCallDesc => 'Pratique à l\'oral en temps réel.';

  @override
  String get practiceRealLife => 'Pratique la vraie vie';

  @override
  String get chooseSituation => 'Choisis une situation à maîtriser';

  @override
  String get createYourOwn => 'Crée le tien';

  @override
  String get startCustom => 'Lancer scénario perso';

  @override
  String get customPlaceholder => 'Ex. Tu es chauffeur de taxi...';

  @override
  String get orderingCoffee => 'Commander un café';

  @override
  String get jobInterview => 'Entretien d\'embauche';

  @override
  String get askingDirections => 'Demander son chemin';

  @override
  String get atTheDoctor => 'Chez le médecin';

  @override
  String get shopping => 'Shopping';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get chats => 'Discussions';

  @override
  String get searchPlaceholder => 'Rechercher...';

  @override
  String get newChat => 'Nouvelle discussion';

  @override
  String get noChats => 'Pas encore de discussion';

  @override
  String get startNewConversation => 'Lancer une nouvelle conversation';

  @override
  String get blankChat => 'Chat vide';

  @override
  String get blankChatDesc => 'Commencer sans contexte';

  @override
  String get roleplayScenario => 'Scénario de jeu de rôle';

  @override
  String get roleplayScenarioDesc => 'Pratiquer des situations spécifiques';

  @override
  String get chooseChatType => 'Type de chat';

  @override
  String get cancel => 'Annuler';

  @override
  String get typeMessage => 'Ã‰cris ton message...';

  @override
  String get designMoji => 'Design Moji';

  @override
  String get fullCustomization => 'Personnalisation complète';

  @override
  String get tapToChange => 'Touche pour changer l\'émotion';

  @override
  String get mascotColor => 'Couleur mascotte';

  @override
  String get backgroundColor => 'Couleur de fond';

  @override
  String get faceExpressions => 'Expressions faciales';

  @override
  String get personalityFaces => 'Personnalité et visages';

  @override
  String get selectFaces => 'Choisis les visages de ta mascotte.';

  @override
  String get locked => 'Verrouillé';

  @override
  String unlockMessage(Object level) {
    return 'Atteins le niveau $level pour débloquer !';
  }

  @override
  String get yourMistakes => 'Tes erreurs';

  @override
  String get learnFromWrong => 'Apprends de tes erreurs';

  @override
  String get all => 'Tout';

  @override
  String get grammar => 'Grammaire';

  @override
  String get grammarBreakdown => 'Analyse grammaticale';

  @override
  String get close => 'Fermer';

  @override
  String get noGrammarAnalysis => 'Aucune analyse grammaticale disponible.';

  @override
  String get vocabulary => 'Vocabulaire';

  @override
  String get noMistakes => 'Aucune erreur trouvée !';

  @override
  String get yourAnswer => 'Ta réponse';

  @override
  String get correctAnswer => 'Bonne réponse';

  @override
  String get explanation => 'Explication';

  @override
  String get story => 'Scénarios';

  @override
  String get drills => 'Erreurs';

  @override
  String get typeHere => 'Tapez ici...';

  @override
  String get shopTitle => 'Magasin';

  @override
  String get categoryAll => 'Tout';

  @override
  String get categoryFood => 'Nourriture';

  @override
  String get categoryDecor => 'Décor';

  @override
  String get hideOwnedCosmetics => 'Masquer les Cosmétiques Possédés';

  @override
  String get noItems => 'Aucun Article';

  @override
  String get owned => 'Possédé';

  @override
  String get alreadyOwned => 'Déjà Possédé';

  @override
  String get alreadyOwnedMessage => 'Vous possédez déjà cet article!';

  @override
  String get quantity => 'Quantité';

  @override
  String get totalPrice => 'Prix Total';

  @override
  String get notEnoughCoins => 'Pas Assez de Pièces!';

  @override
  String get purchaseFailed => 'Achat Ã‰chouÃ©';

  @override
  String get notEnoughCoinsMessage => 'Pas assez de pièces!';

  @override
  String get buy => 'Acheter';

  @override
  String get tooPoor => 'Trop Pauvre';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'Récompense Quotidienne';

  @override
  String get claim_reward => 'Réclamer la Récompense';

  @override
  String day_streak(Object X) {
    return 'Série de $X jours';
  }

  @override
  String get come_back_tomorrow => 'Revenez demain!';

  @override
  String get streak_broken => 'Bon retour! On recommence';

  @override
  String get keep_going => 'Continuez!';

  @override
  String get reward_claimed => 'Récompense Réclamée!';

  @override
  String amazing_streak(Object X) {
    return 'Incroyable! Série de $X jours!';
  }

  @override
  String get whatsYourName => 'QUEL EST TON NOM?';

  @override
  String get enterYourName => 'Entrez votre nom';

  @override
  String get continueBtn => 'CONTINUER';

  @override
  String get howWouldYouRate => 'COMMENT Ã‰VALUEZ-VOUS';

  @override
  String get yourLevel => 'VOTRE NIVEAU?';

  @override
  String get beginner => 'DÃ‰BUTANT';

  @override
  String get intermediate => 'INTERMÃ‰DIAIRE';

  @override
  String get advanced => 'AVANCÃ‰';

  @override
  String get beginnerDesc => 'Je débute. Je connais très peu de mots.';

  @override
  String get intermediateDesc =>
      'Je peux avoir des conversations de base et comprendre des textes simples.';

  @override
  String get advancedDesc =>
      'Je suis fluide ou presque. Je peux discuter de sujets complexes.';

  @override
  String get whichLanguage => 'QUELLE LANGUE';

  @override
  String get doYouWantToLearn => 'VEUX-TU APPRENDRE?';

  @override
  String get changeAnytime =>
      'Tu peux changer cela à tout moment dans les paramètres';

  @override
  String get dontWorryVerify =>
      'Ne t\'inquiète pas, nous vérifierons cela avec une rapide discussion!';

  @override
  String get startAssessment => 'COMMENCER L\'Ã‰VALUATION';

  @override
  String get chatAssessment => 'Ã‰VALUATION PAR CHAT';

  @override
  String get typeYourAnswer => 'Tape ta réponse...';

  @override
  String get mojiIsTyping => 'Moji écrit...';

  @override
  String get send => 'ENVOYER';

  @override
  String get calibrationComplete => 'Calibrage terminé !';

  @override
  String get basedOnYourAnswers =>
      'D\'après tes réponses, ton niveau de départ recommandé est :';

  @override
  String get proficiencyLevel => 'Niveau de compétence';

  @override
  String get shopItemAppleName => 'Pomme';

  @override
  String get shopItemAppleDescription => 'Une collation saine.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Bonté beurreuse.';

  @override
  String get shopItemPizzaName => 'Tranche de pizza';

  @override
  String get shopItemPizzaDescription => 'Fromage et remplissant.';

  @override
  String get shopItemSushiName => 'Lot de sushi';

  @override
  String get shopItemSushiDescription => 'Poisson premium.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Coup d\'énergie rapide.';

  @override
  String get shopItemMedicineName => 'Médicament';

  @override
  String get shopItemMedicineDescription => 'Remet Moji sur pied.';

  @override
  String get review => 'Révision';

  @override
  String reviewDueCount(int count) {
    return '$count à réviser';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$current sur $total';
  }

  @override
  String get reviewShowAnswer => 'Voir la réponse';

  @override
  String get reviewGradeAgain => 'À revoir';

  @override
  String get reviewGradeHard => 'Difficile';

  @override
  String get reviewGradeGood => 'Correct';

  @override
  String get reviewGradeEasy => 'Facile';

  @override
  String get reviewAllCaughtUp => 'Tout est à jour !';

  @override
  String get reviewNothingDue =>
      'Rien à réviser pour le moment. Discute ou fais un quiz et Moji retiendra ce qui te pose problème.';

  @override
  String get reviewSessionComplete => 'Révision terminée !';

  @override
  String reviewSessionSummary(int count) {
    return '$count révisés';
  }

  @override
  String get reviewDone => 'Terminé';

  @override
  String get reviewCorrectionPrompt => 'Quelle est la correction ?';

  @override
  String get reviewVocabularyPrompt => 'Qu’est-ce que ça veut dire ?';

  @override
  String get shopItemBgBlueName => 'Bleu océan';

  @override
  String get shopItemBgBlueDescription => 'Vibrations bleues apaisantes.';

  @override
  String get shopItemBgForestName => 'Vert forêt';

  @override
  String get shopItemBgForestDescription => 'Sensation naturelle.';

  @override
  String get shopItemBgSunsetName => 'Orange coucher de soleil';

  @override
  String get shopItemBgSunsetDescription => 'Chaud et confortable.';

  @override
  String get shopItemBgGalaxyName => 'Violet galaxie';

  @override
  String get shopItemBgGalaxyDescription => 'Hors de ce monde.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName acheté!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity acheté!';
  }

  @override
  String get youLabel => 'Toi';

  @override
  String get mojiSleepReconnect =>
      'Zzz... Moji somnole pendant que la connexion linguistique se rétablit. Réessaie bientôt.';

  @override
  String get mojiSleepNight =>
      'Chut... Moji dort. Appuie sur Moji pour le réveiller.';

  @override
  String get mojiSleepHintReconnect =>
      'MOJI SOMNOLE... RECONNEXION DU LIEN LINGUISTIQUE';

  @override
  String get mojiSleepHintNight => 'MOJI DORT... APPUIE POUR RÉVEILLER';

  @override
  String get mojiWakeSuccess =>
      'Bâillement... Moji est réveillé maintenant ! On sentraîne !';

  @override
  String get mojiSleepReasonReconnect =>
      'Moji somnole pendant que la connexion linguistique se rétablit.';

  @override
  String get mojiSleepReasonNight => 'Moji dort. Appuie pour le réveiller.';

  @override
  String get levelsScreenTitle => 'Niveaux';

  @override
  String get levelStatusCurrent => 'Niveau actuel';

  @override
  String get levelStatusCompleted => 'Complété';

  @override
  String get levelRewardLabel => 'Récompense';

  @override
  String get quizPausedTitle => 'En pause';

  @override
  String get quizPausedPrompt => 'Continuer ou quitter?';

  @override
  String get quizPlay => 'Jouer';

  @override
  String get quizPause => 'Pause';

  @override
  String get quizExit => 'Quitter';

  @override
  String get weeklyProgressTitle => 'Progrès hebdomadaire';

  @override
  String dayLabel(int dayNum) {
    return 'Jour $dayNum';
  }

  @override
  String get dailyRewardHint => 'Revenez demain pour la récompense quotidienne';

  @override
  String get resetAppButton => 'Réinitialiser';

  @override
  String get resetAppTitle => 'Réinitialiser l\'application';

  @override
  String get resetAppWarning =>
      'Cela supprimera tout votre progrès.\n\nÊtes-vous sûr?';

  @override
  String get resetAction => 'Réinitialiser';

  @override
  String get resetSuccessMessage => 'Application réinitialisée avec succès';

  @override
  String get selectYourCharacter => 'Sélectionnez votre personnage';

  @override
  String get characterDog => 'Chien';

  @override
  String get characterCat => 'Chat';

  @override
  String get characterBird => 'Oiseau';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Moji somnole pendant que la connexion linguistique se rétablit. Réessaie bientôt.';

  @override
  String get mojiDozingReconnect =>
      'Moji somnole pendant que la connexion linguistique se rétablit.';

  @override
  String get mojiSleepingTapWake => 'Moji dort. Touche-le pour le réveiller.';

  @override
  String get mojiAwakeReady => 'Moji est réveillé et prêt !';

  @override
  String get wardrobeTitle => 'Garde-robe';

  @override
  String get slotHat => 'Chapeau';

  @override
  String get slotNeck => 'Cou';

  @override
  String get slotFace => 'Visage';

  @override
  String get bodyTailColor => 'Couleur du corps et de la queue';

  @override
  String get eyeColor => 'Couleur des yeux';

  @override
  String get eyeStyleSolid => 'Uni';

  @override
  String get eyeStyleOddEyed => 'Yeux vairons';

  @override
  String get leftEye => 'Œil gauche';

  @override
  String get rightEye => 'Œil droit';

  @override
  String get colorLabel => 'Couleur';

  @override
  String get scenarioObjectives => 'Objectifs';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'Réussi';

  @override
  String get scenarioBonusLabel => 'Bonus';

  @override
  String get scenarioCompleteTitle => 'Scénario réussi !';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '$done objectifs sur $total';
  }

  @override
  String get scenarioFirstClear => 'Première réussite !';

  @override
  String get scenarioReplayNote =>
      'Récompense de rejeu — la première réussite rapporte plus.';

  @override
  String get scenarioContinue => 'Continuer';

  @override
  String get objCoffeeOrder => 'Commande une boisson';

  @override
  String get objCoffeeCustomize => 'Personnalise ta commande';

  @override
  String get objCoffeePrice => 'Demande le prix';

  @override
  String get objCoffeeSmallTalk => 'Bavarde un peu avec le barista';

  @override
  String get objInterviewGreet => 'Présente-toi';

  @override
  String get objInterviewExperience => 'Décris ton expérience';

  @override
  String get objInterviewStrength => 'Explique pourquoi tu conviens';

  @override
  String get objInterviewAsk => 'Pose une question sur le poste';

  @override
  String get objDirectionsAsk => 'Demande ton chemin';

  @override
  String get objDirectionsClarify =>
      'Demande de répéter ou de parler plus lentement';

  @override
  String get objDirectionsDistance => 'Découvre à quelle distance c’est';

  @override
  String get objDirectionsThank => 'Remercie-les comme il faut';

  @override
  String get objDoctorSymptom => 'Décris tes symptômes';

  @override
  String get objDoctorDuration => 'Dis depuis combien de temps ça dure';

  @override
  String get objDoctorQuestion => 'Demande ce que tu dois faire';

  @override
  String get objDoctorAllergy => 'Mentionne une allergie ou un médicament';

  @override
  String get objShoppingFind => 'Demande où se trouve un article';

  @override
  String get objShoppingSize =>
      'Renseigne-toi sur la taille, la couleur ou la coupe';

  @override
  String get objShoppingPrice => 'Demande le prix';

  @override
  String get objShoppingPay => 'Paie-le';

  @override
  String get objRestaurantTable => 'Demande une table';

  @override
  String get objRestaurantOrder => 'Commande à manger';

  @override
  String get objRestaurantDrink => 'Commande quelque chose à boire';

  @override
  String get objRestaurantBill => 'Demande l’addition';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEnable => 'Me rappeler Moji';

  @override
  String get notificationsDesc =>
      'Moji te préviendra quand il a besoin de toi, quand des révisions t’attendent et quand ta récompense quotidienne est prête.';

  @override
  String get notificationsBlocked =>
      'Les notifications sont désactivées dans les réglages de ton appareil.';

  @override
  String get notifPetChannelName => 'Moji a besoin de toi';

  @override
  String get notifPetChannelDesc =>
      'Rappels quand ton compagnon a faim ou est triste';

  @override
  String get notifReviewChannelName => 'Rappels de révision';

  @override
  String get notifReviewChannelDesc => 'Rappels quand des mots sont à réviser';

  @override
  String get notifRewardChannelName => 'Récompense quotidienne';

  @override
  String get notifRewardChannelDesc =>
      'Rappels quand ta récompense quotidienne est prête';

  @override
  String get notifPetHungryTitle => 'Moji a faim';

  @override
  String get notifPetHungryBody =>
      'Ton compagnon aurait bien besoin d’un en-cas.';

  @override
  String get notifPetSadTitle => 'Moji s’ennuie de toi';

  @override
  String get notifPetSadBody => 'C’est calme sans toi. Tu viens dire bonjour ?';

  @override
  String get notifReviewTitle => 'C’est l’heure de réviser';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mots t’attendent.',
      one: '1 mot t’attend.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'Ta récompense quotidienne est prête';

  @override
  String get notifRewardBody =>
      'Moji a quelque chose pour toi. Viens le chercher !';

  @override
  String get careTitle => 'Comment va Moji ?';

  @override
  String get careStatFullness => 'Satiété';

  @override
  String get careStatHappiness => 'Bonheur';

  @override
  String get careStatHealth => 'Santé';

  @override
  String get careAllWell => 'Moji va très bien.';

  @override
  String get careNeedHungry => 'Moji a faim';

  @override
  String get careNeedLonely => 'Moji a le moral bas';

  @override
  String get careNeedSick => 'Moji est malade';

  @override
  String get careSickPenalty =>
      'Tant que Moji est malade, l’XP et les pièces sont divisées par deux.';

  @override
  String get careFeedTitle => 'Nourrir Moji';

  @override
  String get careNoFood => 'Plus de nourriture. Fais un tour à la boutique.';

  @override
  String get careGoToShop => 'Aller à la boutique';

  @override
  String get carePlay => 'Caresser Moji';

  @override
  String get carePlayCooldown => 'Moji a eu assez de câlins pour l’instant.';

  @override
  String get careClose => 'Fermer';

  @override
  String careFedItem(String item) {
    return 'Moji a mangé $item.';
  }

  @override
  String careCurrentFullness(int value) {
    return 'Satiété actuelle : $value %';
  }

  @override
  String get scenarioSickPenalty =>
      'Moji est malade — récompenses divisées par deux';

  @override
  String get careDragToFeed => 'Fais glisser sur Moji pour le nourrir';
}
