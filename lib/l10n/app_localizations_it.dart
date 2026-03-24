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
}
