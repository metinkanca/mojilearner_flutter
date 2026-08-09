// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get header => 'Impostazioni Lingua';

  @override
  String get iSpeak => 'Parlo';

  @override
  String get imLearning => 'Sto imparando';

  @override
  String get currentSelection => 'Selezione attuale:';

  @override
  String get level => 'Livello';

  @override
  String get xp => 'XP';

  @override
  String get streak => 'Serie';

  @override
  String get audio => 'Voce Bot';

  @override
  String get designMojiBtn => 'Crea Moji';

  @override
  String get quizMode => 'Quiz';

  @override
  String get quizDesc => 'Metti alla prova le tue conoscenze.';

  @override
  String get scenarios => 'Scenari';

  @override
  String get scenariosDesc => 'Pratica conversazioni reali.';

  @override
  String get profile => 'Profilo';

  @override
  String get shop => 'Negozio';

  @override
  String get mistakes => 'ERRORI';

  @override
  String get noMistakesYet => 'NESSUN ERRORE ANCORA!';

  @override
  String get profileDesc => 'Vedi statistiche e impostazioni.';

  @override
  String get voiceCall => 'Chiamata Vocale';

  @override
  String get voiceCallDesc => 'Pratica a parlare in tempo reale.';

  @override
  String get practiceRealLife => 'Pratica Vita Reale';

  @override
  String get chooseSituation => 'Scegli una situazione';

  @override
  String get createYourOwn => 'Crea il tuo';

  @override
  String get startCustom => 'Avvia scenario personalizzato';

  @override
  String get customPlaceholder => 'Es. Sei un tassista...';

  @override
  String get orderingCoffee => 'Ordinare il caffè';

  @override
  String get jobInterview => 'Colloquio di lavoro';

  @override
  String get askingDirections => 'Chiedere indicazioni';

  @override
  String get atTheDoctor => 'Dal dottore';

  @override
  String get shopping => 'Shopping';

  @override
  String get restaurant => 'Ristorante';

  @override
  String get chats => 'Chat';

  @override
  String get searchPlaceholder => 'Cerca messaggi...';

  @override
  String get newChat => 'Nuova Chat';

  @override
  String get noChats => 'Nessuna chat';

  @override
  String get startNewConversation => 'Inizia una conversazione';

  @override
  String get blankChat => 'Chat Vuota';

  @override
  String get blankChatDesc => 'Inizia senza contesto';

  @override
  String get roleplayScenario => 'Scenario di Ruolo';

  @override
  String get roleplayScenarioDesc => 'Pratica situazioni specifiche';

  @override
  String get chooseChatType => 'Scegli tipo di chat';

  @override
  String get cancel => 'Annulla';

  @override
  String get typeMessage => 'Scrivi il messaggio...';

  @override
  String get designMoji => 'Design Moji';

  @override
  String get fullCustomization => 'Personalizzazione completa';

  @override
  String get tapToChange => 'Tocca per cambiare';

  @override
  String get mascotColor => 'Colore Mascotte';

  @override
  String get backgroundColor => 'Colore Sfondo';

  @override
  String get faceExpressions => 'Espressioni facciali';

  @override
  String get personalityFaces => 'Personalità & Volti';

  @override
  String get selectFaces => 'Seleziona i volti.';

  @override
  String get locked => 'Bloccato';

  @override
  String unlockMessage(Object level) {
    return 'Raggiungi il livello $level per sbloccare!';
  }

  @override
  String get yourMistakes => 'I tuoi errori';

  @override
  String get learnFromWrong => 'Impara dagli errori';

  @override
  String get all => 'Tutti';

  @override
  String get grammar => 'Grammatica';

  @override
  String get grammarBreakdown => 'Analisi grammaticale';

  @override
  String get close => 'Chiudi';

  @override
  String get noGrammarAnalysis => 'Nessuna analisi grammaticale disponibile.';

  @override
  String get vocabulary => 'Vocabolario';

  @override
  String get noMistakes => 'Nessun errore trovato!';

  @override
  String get yourAnswer => 'La tua risposta';

  @override
  String get correctAnswer => 'Risposta corretta';

  @override
  String get explanation => 'Spiegazione';

  @override
  String get story => 'Scenari';

  @override
  String get drills => 'Errori';

  @override
  String get typeHere => 'Scrivi qui...';

  @override
  String get shopTitle => 'Negozio';

  @override
  String get categoryAll => 'Tutto';

  @override
  String get categoryFood => 'Cibo';

  @override
  String get categoryDecor => 'Decorazione';

  @override
  String get hideOwnedCosmetics => 'Nascondi Cosmetici Posseduti';

  @override
  String get noItems => 'Nessun Articolo';

  @override
  String get owned => 'Posseduto';

  @override
  String get alreadyOwned => 'Già Posseduto';

  @override
  String get alreadyOwnedMessage => 'Possiedi già questo articolo!';

  @override
  String get quantity => 'Quantità';

  @override
  String get totalPrice => 'Prezzo Totale';

  @override
  String get notEnoughCoins => 'Monete Insufficienti!';

  @override
  String get purchaseFailed => 'Acquisto Fallito';

  @override
  String get notEnoughCoinsMessage => 'Monete insufficienti!';

  @override
  String get buy => 'Acquista';

  @override
  String get tooPoor => 'Troppo Povero';

  @override
  String get ok => 'OK';

  @override
  String get daily_reward => 'Ricompensa Giornaliera';

  @override
  String get claim_reward => 'Riscatta Ricompensa';

  @override
  String day_streak(Object X) {
    return 'Serie di $X giorni';
  }

  @override
  String get come_back_tomorrow => 'Torna domani!';

  @override
  String get streak_broken => 'Bentornato! Ripartiamo';

  @override
  String get keep_going => 'Continua così!';

  @override
  String get reward_claimed => 'Ricompensa Ottenuta!';

  @override
  String amazing_streak(Object X) {
    return 'Fantastico! Serie di $X giorni!';
  }

  @override
  String get whatsYourName => 'COME TI CHIAMI?';

  @override
  String get enterYourName => 'Inserisci il tuo nome';

  @override
  String get continueBtn => 'CONTINUA';

  @override
  String get howWouldYouRate => 'COME VALUTERESTI';

  @override
  String get yourLevel => 'IL TUO LIVELLO?';

  @override
  String get beginner => 'PRINCIPIANTE';

  @override
  String get intermediate => 'INTERMEDIO';

  @override
  String get advanced => 'AVANZATO';

  @override
  String get beginnerDesc => 'Sto iniziando. Conosco pochissime parole.';

  @override
  String get intermediateDesc =>
      'Posso avere conversazioni di base e capire testi semplici.';

  @override
  String get advancedDesc =>
      'Sono fluente o quasi. Posso discutere di argomenti complessi.';

  @override
  String get whichLanguage => 'QUALE LINGUA';

  @override
  String get doYouWantToLearn => 'VUOI IMPARARE?';

  @override
  String get changeAnytime =>
      'Puoi modificarlo in qualsiasi momento nelle impostazioni';

  @override
  String get dontWorryVerify =>
      'Non preoccuparti, lo verificheremo con una breve chat!';

  @override
  String get startAssessment => 'INIZIA LA VALUTAZIONE';

  @override
  String get chatAssessment => 'VALUTAZIONE CHAT';

  @override
  String get typeYourAnswer => 'Scrivi la tua risposta...';

  @override
  String get mojiIsTyping => 'Moji sta scrivendo...';

  @override
  String get send => 'INVIA';

  @override
  String get calibrationComplete => 'Calibrazione Completata!';

  @override
  String get basedOnYourAnswers =>
      'In base alle tue risposte, il tuo livello di partenza consigliato è:';

  @override
  String get proficiencyLevel => 'Livello di Competenza';

  @override
  String get shopItemAppleName => 'Mela';

  @override
  String get shopItemAppleDescription => 'Uno snack salutare.';

  @override
  String get shopItemCroissantName => 'Croissant';

  @override
  String get shopItemCroissantDescription => 'Bontà al burro.';

  @override
  String get shopItemPizzaName => 'Fetta di pizza';

  @override
  String get shopItemPizzaDescription => 'Formaggio e sustanziale.';

  @override
  String get shopItemSushiName => 'Set di sushi';

  @override
  String get shopItemSushiDescription => 'Pesce premium.';

  @override
  String get shopItemCoffeeName => 'Espresso';

  @override
  String get shopItemCoffeeDescription => 'Spinta di energia veloce.';

  @override
  String get shopItemMedicineName => 'Medicina';

  @override
  String get shopItemMedicineDescription => 'Rimette in sesto Moji.';

  @override
  String get review => 'Ripasso';

  @override
  String reviewDueCount(int count) {
    return '$count da ripassare';
  }

  @override
  String reviewProgress(int current, int total) {
    return '$current di $total';
  }

  @override
  String get reviewShowAnswer => 'Mostra la risposta';

  @override
  String get reviewGradeAgain => 'Di nuovo';

  @override
  String get reviewGradeHard => 'Difficile';

  @override
  String get reviewGradeGood => 'Bene';

  @override
  String get reviewGradeEasy => 'Facile';

  @override
  String get reviewAllCaughtUp => 'Tutto in pari!';

  @override
  String get reviewNothingDue =>
      'Non c’è nulla da ripassare ora. Chatta o fai un quiz e Moji ricorderà cosa ti mette in difficoltà.';

  @override
  String get reviewSessionComplete => 'Ripasso completato!';

  @override
  String reviewSessionSummary(int count) {
    return '$count ripassati';
  }

  @override
  String get reviewDone => 'Fatto';

  @override
  String get reviewCorrectionPrompt => 'Qual è la correzione?';

  @override
  String get reviewVocabularyPrompt => 'Che cosa significa?';

  @override
  String get shopItemBgBlueName => 'Blu oceano';

  @override
  String get shopItemBgBlueDescription => 'Vibrazioni blu tranquillizzanti.';

  @override
  String get shopItemBgForestName => 'Verde foresta';

  @override
  String get shopItemBgForestDescription => 'Sensazione naturale.';

  @override
  String get shopItemBgSunsetName => 'Arancione tramonto';

  @override
  String get shopItemBgSunsetDescription => 'Caldo e accogliente.';

  @override
  String get shopItemBgGalaxyName => 'Viola galassia';

  @override
  String get shopItemBgGalaxyDescription => 'Fuori da questo mondo.';

  @override
  String purchaseSuccessSingle(Object itemName) {
    return '$itemName acquistato!';
  }

  @override
  String purchaseSuccessMultiple(Object itemName, Object quantity) {
    return '$itemName x$quantity acquistato!';
  }

  @override
  String get youLabel => 'Tu';

  @override
  String get mojiSleepReconnect =>
      'Zzz... Moji sonnecchia mentre il collegamento linguistico si riconnette. Riprova tra poco.';

  @override
  String get mojiSleepNight =>
      'Shhh... Moji sta dormendo. Tocca Moji per svegliarlo.';

  @override
  String get mojiSleepHintReconnect =>
      'MOJI SONNECCHIA... COLLEGAMENTO LINGUISTICO IN RICONNESSIONE';

  @override
  String get mojiSleepHintNight => 'MOJI DORME... TOCCA PER SVEGLIARE';

  @override
  String get mojiWakeSuccess =>
      'Sbadiglio... Moji ora è sveglio! Facciamo pratica!';

  @override
  String get mojiSleepReasonReconnect =>
      'Moji sonnecchia mentre il collegamento linguistico si riconnette.';

  @override
  String get mojiSleepReasonNight => 'Moji sta dormendo. Tocca per svegliarlo.';

  @override
  String get levelsScreenTitle => 'Livelli';

  @override
  String get levelStatusCurrent => 'Livello attuale';

  @override
  String get levelStatusCompleted => 'Completato';

  @override
  String get levelRewardLabel => 'Ricompensa';

  @override
  String get quizPausedTitle => 'In pausa';

  @override
  String get quizPausedPrompt => 'Continuare o uscire?';

  @override
  String get quizPlay => 'Gioca';

  @override
  String get quizPause => 'Pausa';

  @override
  String get quizExit => 'Esci';

  @override
  String get weeklyProgressTitle => 'Progresso settimanale';

  @override
  String dayLabel(int dayNum) {
    return 'Giorno $dayNum';
  }

  @override
  String get dailyRewardHint => 'Torna domani per la ricompensa giornaliera';

  @override
  String get resetAppButton => 'Ripristina';

  @override
  String get resetAppTitle => 'Ripristina app';

  @override
  String get resetAppWarning =>
      'Questo eliminerà tutti i tuoi progressi.\n\nSei sicuro?';

  @override
  String get resetAction => 'Ripristina';

  @override
  String get resetSuccessMessage => 'App ripristinata con successo';

  @override
  String get selectYourCharacter => 'Scegli il tuo personaggio';

  @override
  String get characterDog => 'Cane';

  @override
  String get characterCat => 'Gatto';

  @override
  String get characterBird => 'Uccello';

  @override
  String get aiUnavailableMessage =>
      'Zzz... Moji sonnecchia mentre il collegamento linguistico si riconnette. Riprova presto.';

  @override
  String get mojiDozingReconnect =>
      'Moji sonnecchia mentre il collegamento linguistico si riconnette.';

  @override
  String get mojiSleepingTapWake => 'Moji sta dormendo. Tocca per svegliarlo.';

  @override
  String get mojiAwakeReady => 'Moji è sveglio e pronto!';

  @override
  String get wardrobeTitle => 'Guardaroba';

  @override
  String get slotHat => 'Cappello';

  @override
  String get slotNeck => 'Collo';

  @override
  String get slotFace => 'Viso';

  @override
  String get bodyTailColor => 'Colore corpo e coda';

  @override
  String get eyeColor => 'Colore occhi';

  @override
  String get eyeStyleSolid => 'Tinta unita';

  @override
  String get eyeStyleOddEyed => 'Occhi impari';

  @override
  String get leftEye => 'Occhio sinistro';

  @override
  String get rightEye => 'Occhio destro';

  @override
  String get colorLabel => 'Colore';

  @override
  String get scenarioObjectives => 'Obiettivi';

  @override
  String scenarioProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get scenarioCleared => 'Completato';

  @override
  String get scenarioBonusLabel => 'Bonus';

  @override
  String get scenarioCompleteTitle => 'Scenario completato!';

  @override
  String scenarioCompleteSummary(int done, int total) {
    return '$done di $total obiettivi';
  }

  @override
  String get scenarioFirstClear => 'Prima volta!';

  @override
  String get scenarioReplayNote =>
      'Ricompensa per la ripetizione: la prima volta rende di più.';

  @override
  String get scenarioContinue => 'Continua';

  @override
  String get objCoffeeOrder => 'Ordina una bevanda';

  @override
  String get objCoffeeCustomize => 'Personalizza il tuo ordine';

  @override
  String get objCoffeePrice => 'Chiedi quanto costa';

  @override
  String get objCoffeeSmallTalk => 'Fai due chiacchiere con il barista';

  @override
  String get objInterviewGreet => 'Presentati';

  @override
  String get objInterviewExperience => 'Descrivi la tua esperienza';

  @override
  String get objInterviewStrength => 'Spiega perché sei la persona giusta';

  @override
  String get objInterviewAsk => 'Fai una domanda sul ruolo';

  @override
  String get objDirectionsAsk => 'Chiedi come arrivare da qualche parte';

  @override
  String get objDirectionsClarify =>
      'Chiedi di ripetere o di parlare più piano';

  @override
  String get objDirectionsDistance => 'Scopri quanto è lontano';

  @override
  String get objDirectionsThank => 'Ringrazia come si deve';

  @override
  String get objDoctorSymptom => 'Descrivi i tuoi sintomi';

  @override
  String get objDoctorDuration => 'Di’ da quanto tempo va avanti';

  @override
  String get objDoctorQuestion => 'Chiedi cosa devi fare';

  @override
  String get objDoctorAllergy => 'Menziona un’allergia o un farmaco';

  @override
  String get objShoppingFind => 'Chiedi dove si trova un prodotto';

  @override
  String get objShoppingSize => 'Chiedi taglia, colore o vestibilità';

  @override
  String get objShoppingPrice => 'Chiedi il prezzo';

  @override
  String get objShoppingPay => 'Pagalo';

  @override
  String get objRestaurantTable => 'Chiedi un tavolo';

  @override
  String get objRestaurantOrder => 'Ordina da mangiare';

  @override
  String get objRestaurantDrink => 'Ordina qualcosa da bere';

  @override
  String get objRestaurantBill => 'Chiedi il conto';

  @override
  String get notificationsTitle => 'Notifiche';

  @override
  String get notificationsEnable => 'Ricordami Moji';

  @override
  String get notificationsDesc =>
      'Moji ti avviserà quando ha bisogno di te, quando ci sono ripassi e quando la ricompensa giornaliera è pronta.';

  @override
  String get notificationsBlocked =>
      'Le notifiche sono disattivate nelle impostazioni del dispositivo.';

  @override
  String get notifPetChannelName => 'Moji ha bisogno di te';

  @override
  String get notifPetChannelDesc =>
      'Promemoria quando il tuo animaletto ha fame o è triste';

  @override
  String get notifReviewChannelName => 'Promemoria di ripasso';

  @override
  String get notifReviewChannelDesc =>
      'Promemoria quando ci sono parole da ripassare';

  @override
  String get notifRewardChannelName => 'Ricompensa giornaliera';

  @override
  String get notifRewardChannelDesc =>
      'Promemoria quando la ricompensa giornaliera è pronta';

  @override
  String get notifPetHungryTitle => 'Moji ha fame';

  @override
  String get notifPetHungryBody =>
      'Al tuo animaletto servirebbe proprio uno spuntino adesso.';

  @override
  String get notifPetSadTitle => 'Moji sente la tua mancanza';

  @override
  String get notifPetSadBody =>
      'È tutto silenzioso senza di te. Passi a salutare?';

  @override
  String get notifReviewTitle => 'È ora di ripassare';

  @override
  String notifReviewBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parole ti aspettano.',
      one: '1 parola ti aspetta.',
    );
    return '$_temp0';
  }

  @override
  String get notifRewardTitle => 'La tua ricompensa giornaliera è pronta';

  @override
  String get notifRewardBody => 'Moji ha qualcosa per te. Vieni a prenderlo!';

  @override
  String get careTitle => 'Come sta Moji?';

  @override
  String get careStatFullness => 'Sazietà';

  @override
  String get careStatHappiness => 'Felicità';

  @override
  String get careStatHealth => 'Salute';

  @override
  String get careAllWell => 'Moji sta benissimo.';

  @override
  String get careNeedHungry => 'Moji ha fame';

  @override
  String get careNeedLonely => 'Moji è giù di morale';

  @override
  String get careNeedSick => 'Moji è malato';

  @override
  String get careSickPenalty =>
      'Finché Moji è malato, XP e monete sono dimezzate.';

  @override
  String get careFeedTitle => 'Dai da mangiare a Moji';

  @override
  String get careNoFood => 'Cibo finito. Fai un salto al negozio.';

  @override
  String get careGoToShop => 'Vai al negozio';

  @override
  String get carePlay => 'Accarezza Moji';

  @override
  String get carePlayCooldown => 'Moji ha avuto abbastanza coccole per ora.';

  @override
  String get careClose => 'Chiudi';

  @override
  String careFedItem(String item) {
    return 'Moji ha mangiato $item.';
  }

  @override
  String careCurrentFullness(int value) {
    return 'Sazietà attuale: $value%';
  }

  @override
  String get scenarioSickPenalty => 'Moji è malato: ricompense dimezzate';

  @override
  String get careDragToFeed => 'Trascina su Moji per dargli da mangiare';
}
