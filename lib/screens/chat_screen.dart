import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/gold.dart';
import '../../constants/shop.dart';
import '../../constants/theme.dart';
import '../../components/chat_header.dart';
import '../../components/tutorial/retro_showcase.dart';
import '../../components/tutorial/tutorial_offer_host.dart';
import '../../constants/tutorials.dart';
import '../../components/chat_input.dart';
import '../../components/message_bubble.dart';
import '../../components/chat_sidebar.dart';
import '../../models/models.dart';
import '../../providers/language_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/mistakes_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/ads_provider.dart';
import '../../providers/user_provider.dart';
import '../components/ai_limit_sheet.dart';
import '../constants/entitlements.dart';
import '../../providers/calibration_provider.dart';
import '../../providers/vocab_provider.dart';
import '../../utils/review_selection.dart';
import '../../utils/rtl_locale.dart';
import '../../utils/vocab_extractor.dart';
import '../../utils/mistake_extractor.dart';
import '../../constants/scenarios.dart';
import '../../providers/scenario_provider.dart';
import '../../utils/objective_extractor.dart';
import '../../utils/progression_utils.dart';
import '../../components/scenario_complete_popup.dart';
import '../../components/scenario_objective_tracker.dart';
import '../../components/scenario_stage.dart';
import '../../services/ai_guard.dart';
import '../../services/ai_prompt_spec.dart';
import '../../services/ai_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/fonts.dart';

/// The chat tour's steps, in the order it visits them.
final GlobalKey chatMenuShowcaseKey = GlobalKey();
final GlobalKey chatMessagesShowcaseKey = GlobalKey();
final GlobalKey chatInputShowcaseKey = GlobalKey();

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? scenarioTitle;

  /// Stable scenario id, e.g. 'coffee'. Null for free chat and for custom
  /// scenarios, which stay freeform and untracked.
  final String? scenarioId;

  const ChatScreen({
    super.key,
    this.chatId,
    this.scenarioTitle,
    this.scenarioId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  static const double _sidebarWidth = 300;
  static const double _swipeThreshold = 0.18;

  late AnimationController _sidebarController;
  double? _dragStartX;
  double _dragStartProgress = 0;
  
  // AI State
  String? _aiSessionId;
  bool _isConnecting = true;
  String? _currentChatId;

  /// A message is out and the tutor has not answered yet. Only drawn — the
  /// scenario host wears a thinking bubble — never used to block a send.
  bool _awaitingReply = false;

  /// The scenario's service, put on the table when the goal that asks for it
  /// lands, until it is paid for or turned down. Not saved: leaving the scene
  /// leaves the meal behind.
  ShopItem? _serviceOffer;

  /// The last service paid for, and how many have been this visit — what the
  /// scene plays the pet eating.
  ShopItem? _lastService;
  int _servicesBought = 0;
  bool _payingForService = false;

  /// Guards against paying out a scenario twice if another response
  /// lands while the completion popup is still open.
  bool _completionHandled = false;

  String? _resolveScenarioTitle(ChatProvider chatProvider) {
    if (widget.scenarioTitle != null && widget.scenarioTitle!.trim().isNotEmpty) {
      return widget.scenarioTitle;
    }

    if (_currentChatId == null) return null;
    final existing = chatProvider.chats.where((c) => c.id == _currentChatId).toList();
    if (existing.isEmpty) return null;

    final chat = existing.first;
    if (chat.type == 'scenario') {
      return chat.title;
    }
    return null;
  }

  /// Recovers the scenario id from a `new_<id>` route, so a deep link works
  /// even without the `extra` map the scenarios grid passes.
  String? _scenarioIdFromRouteId(String? routeChatId) {
    if (routeChatId == null || !routeChatId.startsWith('new_')) return null;
    final raw = routeChatId.substring(4);
    if (raw.isEmpty || raw == 'custom') return null;
    return ScenarioCatalog.byId(raw)?.id;
  }

  /// The scenario this chat is playing, or null when it isn't a tracked one.
  ///
  /// Prefers the id carried on the route, then the id persisted on the chat —
  /// chats saved before scenarios became trackable have neither, and stay
  /// freeform.
  ScenarioDefinition? _resolveScenario(ChatProvider chatProvider) {
    final routeId = widget.scenarioId ?? _scenarioIdFromRouteId(widget.chatId);
    if (routeId != null) return ScenarioCatalog.byId(routeId);

    if (_currentChatId == null) return null;
    for (final chat in chatProvider.chats) {
      if (chat.id == _currentChatId && chat.scenarioId != null) {
        return ScenarioCatalog.byId(chat.scenarioId!);
      }
    }
    return null;
  }

  String _defaultScenarioTitleFromRouteId(String? routeChatId) {
    if (routeChatId == null || !routeChatId.startsWith('new_')) {
      return 'Scenario Chat';
    }

    final raw = routeChatId.substring(4);
    if (raw.isEmpty || raw == 'custom') {
      return 'Custom Scenario';
    }

    final words = raw.split('_').where((w) => w.isNotEmpty).map((w) {
      if (w.length == 1) return w.toUpperCase();
      return '${w[0].toUpperCase()}${w.substring(1)}';
    }).join(' ');

    return words.isEmpty ? 'Scenario Chat' : words;
  }

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 0,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupChat();
    });
  }

  @override
  void dispose() {
    if (_aiSessionId != null) {
      AiService.instance.disposeSession(_aiSessionId!);
    }
    _sidebarController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatId != oldWidget.chatId ||
        widget.scenarioTitle != oldWidget.scenarioTitle ||
        widget.scenarioId != oldWidget.scenarioId) {
      _setupChat();
    }
  }

  Future<void> _setupChat() async {
    // A fresh chat is a fresh run, so the payout latch has to clear with it —
    // otherwise the second scenario opened without leaving this screen would
    // silently never pay out.
    _completionHandled = false;
    setState(() => _isConnecting = true); // Start loading
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    if (_aiSessionId != null) {
      AiService.instance.disposeSession(_aiSessionId!);
      _aiSessionId = null;
    }

    try {
      final isNewRouteRequest = widget.chatId?.startsWith('new_') ?? false;

      if (widget.scenarioTitle != null || isNewRouteRequest) {
        final scenarioTitle = widget.scenarioTitle ?? _defaultScenarioTitleFromRouteId(widget.chatId);
        final newId = await chatProvider.createNewChat(
          title: scenarioTitle,
          type: 'scenario',
          scenarioId: widget.scenarioId ?? _scenarioIdFromRouteId(widget.chatId),
        );
        if (mounted) {
          setState(() => _currentChatId = newId);
          await _initAI(isNew: true);
        }
      } else if (widget.chatId != null) {
        // Loading EXISTING Chat
        setState(() => _currentChatId = widget.chatId);
        await _initAI(isNew: false);
      } else {
        // Creating a NEW Default Chat
        final newId = await chatProvider.createNewChat(title: "New Chat");
        if (mounted) {
          setState(() => _currentChatId = newId);
          await _initAI(isNew: true);
        }
      }
    } catch (e) {
      debugPrint("Error setting up chat: $e");
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _initAI({required bool isNew}) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final vocabProvider = Provider.of<VocabProvider>(context, listen: false);
    
    // Safety check
    if (_currentChatId == null) return;

    final effectiveScenarioTitle = _resolveScenarioTitle(chatProvider);
    final isScenarioChat = effectiveScenarioTitle != null;

    // --- 1. Describe the prompt the server should build ---
    //
    // The tutor's wording lives in `server/src/prompts.js`. What this screen
    // knows, and the server cannot, is the learner's state: which scenario
    // they are in, which objectives are still open, and what their review
    // queue holds. It sends that as data and names the mode.
    final targetCode = languageProvider.targetLanguage?.code;
    final l10n = AppLocalizations.of(context)!;

    List<AiObjective> objectives = const [];
    ScenarioDefinition? scenario;
    if (isScenarioChat) {
      scenario = _resolveScenario(chatProvider);
      if (scenario != null) {
        final progress = Provider.of<ScenarioProvider>(context, listen: false)
            .forScenario(scenario.id);
        objectives = scenario.objectives
            .map((objective) => AiObjective(
                  id: objective.id,
                  label: objective.label(l10n),
                  isBonus: objective.isBonus,
                  isCleared: progress.isCleared(objective.id),
                ))
            .toList();
      }
      // A custom or legacy scenario leaves [objectives] empty, which is what
      // selects the untracked freeform roleplay branch on the server.
    }

    // Trimmed here because this screen decides what is worth showing the
    // tutor. The server caps these again; sending more just wastes bytes.
    final briefed = ReviewSelection.select(
      troubleSpots: vocabProvider.troubleSpots(languageCode: targetCode),
      dueItems: vocabProvider.nextSession(languageCode: targetCode),
    );

    final level = targetCode == null
        ? null
        : Provider.of<CalibrationProvider>(context, listen: false)
            .getLanguageProficiency(targetCode)
            ?.aiDeterminedLevel;
    final spec = AiPromptSpec.chat(
      targetCode: targetCode,
      nativeCode: languageProvider.nativeLanguage.code,
      level: level,
      scenarioTitle: effectiveScenarioTitle,
      scenarioHost: scenario?.hostPet,
      objectives: objectives,
      troubleSpots: briefed.trouble,
      dueItems: briefed.due,
    );

    try {
      // --- 2. Build History ---
      List<AiChatMessage> history = [];
      
      if (!isNew) {
        // Load existing messages from Provider
        final messages = chatProvider.getMessages(_currentChatId!);
        
        // Filter and map to session history
        history = messages
          .where((m) => m.sender == 'user' || m.sender == 'bot')
          .map((m) {
             return AiChatMessage(
               role: m.sender == 'user' ? 'user' : 'model',
               text: m.content,
             );
          }).toList();
      }

      // --- 3. Start Chat Session ---
      _aiSessionId = await AiService.instance.createSession(
        spec: spec,
        history: history,
        source: 'chat_screen',
      );
      
      // --- 4. Initial Bot Message (If New) ---
      if (isNew) {
         String? initialPrompt;
         if (isScenarioChat) {
             initialPrompt = "Start the roleplay now. Be creative.";
         } else {
             // For free chat, we might NOT want to prompt, just welcome message in UI?
             // Or prompt model to say hello.
             // Let's prompt model to say hello so it's in the history for sure.
             initialPrompt = "Say a warm hello to start the conversation.";
         }
         
        final responseText = await AiService.instance.sendSessionMessage(
          sessionId: _aiSessionId!,
          message: initialPrompt,
          source: 'chat_screen',
        );
        if (responseText.isNotEmpty && mounted) {
          await _parseAndSaveBotResponse(
            _localizeAiText(responseText),
            isOpeningTurn: true,
          );
         }
      }

    } catch (e) {
      debugPrint("AI Init Error: $e");
      // Add system error message to chat (optional)
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  /// Swaps the AI-unavailable sentinel text for its localized equivalent.
  String _localizeAiText(String text) {
    if (!AiService.instance.isUnavailableResponse(text)) return text;
    return AppLocalizations.of(context)?.aiUnavailableMessage ?? text;
  }

  void _showGuardMessage(
    String message,
    TextDirection textDirection,
    TextAlign textAlign,
  ) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: textDirection,
          textAlign: textAlign,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSend(String text) async {
    if (_currentChatId == null || _aiSessionId == null) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    // 🔒 SECURITY: inbound pipeline (rate limit, marker escaping, PII
    // redaction) via AiGuard. Off-topic and jailbreak-shaped messages are no
    // longer refused here — the system prompt answers them, in the learner's
    // own language, with a redirection that is itself a small lesson.
    final guard = AiGuard.checkUserMessage(
      rawText: text,
      kind: AiRequestKind.chat,
      source: 'chat_screen',
    );

    if (!guard.allowed) {
      switch (guard.block!) {
        case AiGuardBlock.rateLimited:
          _showGuardMessage(guard.rateLimitMessage, textDirection, textAlign);
          break;
        case AiGuardBlock.emptyInput:
          break;
      }
      return;
    }

    if (guard.piiRedacted) {
      _showGuardMessage(
        AppLocalizations.of(context)?.privacyRedactedNotice ??
            'Personal details were hidden before sending.',
        textDirection,
        textAlign,
      );
    }

    // The day's message allowance. Checked before the message is added to the
    // transcript, so a turned-away send leaves no half-exchange sitting there
    // with nothing answering it.
    //
    // This is the one wall with no free version of itself behind it — you
    // cannot talk to the pet without the model. So the sheet points at the
    // review queue and the locally-built quiz instead: there is always
    // something to study, even when there is nothing to say.
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (!userProvider.canSpendAi(AiSpend.message)) {
      await AiLimitSheet.show(context, AiSpend.message);
      return;
    }

    AiGuard.recordRequest('chat_screen');

    // 1. Add User Message to Provider (redacted when sensitive)
    await chatProvider.addMessage(_currentChatId!, Message(
      id: DateTime.now().toString(),
      content: guard.displayText,
      sender: 'user',
      timestamp: DateTime.now()
    ));
    if (mounted) setState(() => _awaitingReply = true);

    // 2. Send to AI (sanitized and redacted text)
    try {
      final responseText = await AiService.instance.sendSessionMessage(
        sessionId: _aiSessionId!,
        message: guard.outboundText,
        source: 'chat_screen',
      );

      // Charged on an exchange the player actually got, matching the quiz
      // side: a failed call cost the provider, but taking the player's
      // allowance for it is how a cap starts feeling arbitrary.
      if (responseText.isNotEmpty) {
        await userProvider.spendAi(AiSpend.message);
      }

      if (responseText.isNotEmpty && mounted) {
        // 🔒 SECURITY: Validate AI response
        final response =
            AiGuard.checkAiResponse(responseText, source: 'chat_screen');
        if (!response.valid) {
          _showGuardMessage(
            response.injectionSuspected
                ? 'Unexpected response. Please rephrase your message.'
                : 'Received invalid response. Please try again.',
            textDirection,
            textAlign,
          );
          return;
        }

        await _parseAndSaveBotResponse(
          _localizeAiText(response.text!),
          userMessage: text,
        );

        // Saving the reply is its own async gap, and leaving the chat during
        // it is ordinary: the reply is already persisted, so dropping the
        // rewards is the correct outcome rather than reaching for a dead
        // context.
        if (!mounted) return;

        // Reward pet and XP for chatting
        final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final isScenarioChat = _resolveScenarioTitle(chatProvider) != null;
        
        // XP is deliberately not passed through scaleReward, unlike the
        // coins below. XP is what the pet's bond stage is projected from, and
        // a sick pet slowing its own closeness is exactly the coupling bond
        // was built without: the relationship grows through the language, not
        // through whether the player could afford food this week.
        if (isScenarioChat) {
          characterProvider.rewardScenario();
          userProvider.addXp(10);
        } else {
          characterProvider.rewardChat();
          userProvider.addXp(5);
        }

        // Talking to the pet in the target language is the app's core act,
        // and it used to pay no coins at all — the worry being that unlimited
        // messages would let players farm the shop without ever sitting a
        // quiz. That worry is now answered by the daily cap on this source
        // and by the taper over all learning income (see `gold.dart`), so a
        // real conversation can pay something without becoming a faucet: a
        // capped-out day of chat is worth less than one good quiz.
        unawaited(userProvider.awardLearningGold(
          characterProvider.scaleReward(GoldConstants.conversation),
          GoldSource.conversation,
        ));

        // Every exchange is a turn in the target language, scenario or not.
        // The XP above is what grows the bond; this only tells the pet it was
        // not forgotten today.
        characterProvider.recordLearningMoment();
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text(
               "Error: $e",
               textDirection: textDirection,
               textAlign: textAlign,
             ),
           ),
         );
       }
    } finally {
      if (mounted) setState(() => _awaitingReply = false);
    }
  }

  /// [isOpeningTurn] marks the tutor's own scene-setter, generated before the
  /// learner has said anything. Objective claims are ignored on that turn: an
  /// interviewer who introduces themselves would otherwise tick "introduce
  /// yourself" on the learner's behalf, handing them a goal for free.
  Future<void> _parseAndSaveBotResponse(
    String rawText, {
    bool isOpeningTurn = false,
    String? userMessage,
  }) async {
      // 1. Extract the correction the tutor reported.
      //
      // Validated rather than decoded straight into the store: fields capped,
      // markers escaped, non-strings dropped, and a "correction" identical to
      // the original discarded. What lands here is reviewed by the learner
      // later, so it is worth checking.
      final mistakeExtraction = MistakeExtractor.extract(rawText);
      String content = mistakeExtraction.content;
      final mistake = mistakeExtraction.mistake;
      if (mistake != null && mounted) {
        Provider.of<MistakesProvider>(context, listen: false).addMistake(
          mistake.original,
          mistake.correction,
          mistake.explanation,
          mistake.type,
        );
      }

      // 2. Record objectives the tutor says this turn accomplished.
      //
      // Block order in the response is VOCAB, then OBJECTIVE, then MISTAKE, so
      // extraction unwinds from the tail: mistake above, objectives here,
      // vocabulary below.
      final objectiveExtraction = ObjectiveExtractor.extract(content);
      content = objectiveExtraction.content;
      if (mounted &&
          !isOpeningTurn &&
          objectiveExtraction.objectiveIds.isNotEmpty) {
        _recordObjectives(objectiveExtraction.objectiveIds);
      }

      // 3. Extract taught vocabulary into the review queue.
      //
      // Runs before the TEXT/TRANS/GRAMMAR regexes below so the block never
      // leaks into the visible bubble.
      final vocabExtraction = VocabExtractor.extract(content);
      content = vocabExtraction.content;
      if (mounted && vocabExtraction.entries.isNotEmpty) {
        final languageCode =
            Provider.of<LanguageProvider>(context, listen: false)
                .targetLanguage
                ?.code;
        if (languageCode != null) {
          final vocab = Provider.of<VocabProvider>(context, listen: false);
          // What the tutor taught goes to the review queue. What it only
          // suggested about the topic goes to the pile the games use. Neither
          // is kept when the learner wrote the word themselves, since a game
          // that asks them back what they just typed teaches nothing, and the
          // pile also drops anything they already have.
          final userText = userMessage ?? '';
          final written = userText.isEmpty
              ? vocabExtraction.entries
              : VocabExtractor.withoutWritten(
                  vocabExtraction.entries,
                  userText: userText,
                );
          vocab.addVocabularyBatch(
            written.where((e) => !e.related),
            languageCode: languageCode,
          );
          vocab.addSuggested(
            VocabExtractor.freshRelated(
              vocabExtraction.entries,
              userText: userText,
              isKnown: (term) => vocab.knowsVocabulary(languageCode, term),
            ),
            languageCode: languageCode,
          );
        }
      }

      String? translation;
      String? grammar;
      String? reading;

      // Simple parsing of labeled sections. READING is optional and sits
      // between TEXT and TRANS, so TEXT has to stop at either.
      final textMatch = RegExp(r'TEXT:\s*(.*?)(?=\nREADING:|\nTRANS:|$)',
              dotAll: true)
          .firstMatch(content);
      final readingMatch =
          RegExp(r'READING:\s*(.*?)(?=\nTRANS:|$)', dotAll: true)
              .firstMatch(content);
      final transMatch = RegExp(r'TRANS:\s*(.*?)(?=\nGRAMMAR:|$)', dotAll: true).firstMatch(content);
      final grammarMatch = RegExp(r'GRAMMAR:\s*(.*)', dotAll: true).firstMatch(content);

      if (textMatch != null) {
         content = textMatch.group(1)?.trim() ?? content;
         translation = transMatch?.group(1)?.trim();
         grammar = grammarMatch?.group(1)?.trim();
         final rawReading = readingMatch?.group(1)?.trim();
         reading = (rawReading == null || rawReading.isEmpty) ? null : rawReading;
      }

      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (_currentChatId != null) {
        await chatProvider.addMessage(_currentChatId!, Message(
          id: DateTime.now().toString(),
          content: content,
          sender: 'bot',
          timestamp: DateTime.now(),
          translation: translation,
          grammarAnalysis: grammar,
          reading: reading,
        ));
      }
  }

  /// Applies the objectives the tutor reported, and closes out the run when
  /// the last required one lands.
  ///
  /// Ids are claims, not facts: [ScenarioProvider.markObjectives] drops
  /// anything not in the catalogue, so a model that invents an id cannot
  /// award itself a clear.
  void _recordObjectives(List<String> objectiveIds) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final scenario = _resolveScenario(chatProvider);
    if (scenario == null) return;

    final scenarioProvider =
        Provider.of<ScenarioProvider>(context, listen: false);
    final newlyCleared =
        scenarioProvider.markObjectives(scenario, objectiveIds);
    if (newlyCleared.isEmpty) return;

    // The order was understood, so the host brings it out. Offered rather
    // than charged: the tutor decided the goal was met, and only the player
    // decides to spend coins.
    final service = scenario.serviceOrderedBy(newlyCleared);
    final item = service == null ? null : shopItemById(service.itemId);
    if (item != null) setState(() => _serviceOffer = item);

    if (!scenarioProvider.isComplete(scenario) || _completionHandled) return;

    // Latch before any await: a second response arriving mid-popup must not
    // pay out twice.
    _completionHandled = true;
    _completeScenario(scenario, scenarioProvider);
  }

  /// Pays for the service on the table and gives it to the pet — at the
  /// shop's price, with the shop's effect.
  Future<void> _payForService() async {
    final item = _serviceOffer;
    if (item == null || _payingForService) return;
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final user = Provider.of<UserProvider>(context, listen: false);
    final character = Provider.of<CharacterProvider>(context, listen: false);

    setState(() => _payingForService = true);
    final paid = await character.purchaseAndFeed(item, user);
    if (!mounted) return;
    setState(() {
      _payingForService = false;
      if (paid) {
        _serviceOffer = null;
        _lastService = item;
        _servicesBought++;
      }
    });
    // Left on the table when it cannot be paid for, so a player who tops up
    // their coins can come back to it.
    if (!paid) {
      _showGuardMessage(
        l10n.notEnoughCoinsMessage,
        textDirectionForLocale(locale),
        textAlignForLocale(locale),
      );
    }
  }

  Future<void> _completeScenario(
    ScenarioDefinition scenario,
    ScenarioProvider scenarioProvider,
  ) async {
    final clearedThisRun =
        Set<String>.from(scenarioProvider.forScenario(scenario.id)
            .clearedObjectiveIds);
    final bonusCleared = scenario.objectives
        .where((o) => o.isBonus && clearedThisRun.contains(o.id))
        .length;
    final bonusTotal = scenario.objectives.where((o) => o.isBonus).length;

    // completeRun resets the checklist for the next play-through, so the
    // reward tier has to be read from its return value, not re-derived after.
    final isFirstClear = scenarioProvider.completeRun(scenario);

    final reward = ProgressionUtils.getScenarioRewardOutcome(
      bonusObjectivesCleared: bonusCleared,
      bonusObjectivesTotal: bonusTotal,
      isFirstClear: isFirstClear,
    );

    await _payOutRun(scenario, reward, clearedThisRun);
  }

  /// Ends the run on the learner's say-so, with goals still outstanding.
  ///
  /// The exit exists because a scene can outrun its own checklist: a waiter
  /// who seats you before you ask leaves "ask for a table" permanently
  /// unreachable, and without a way out the chat continues past the goodbyes
  /// with the reward never arriving. Pays for what was actually done and does
  /// not record a clear, so finishing early costs the first-clear tier rather
  /// than spending it.
  Future<void> _finishRunEarly() async {
    if (_completionHandled) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final scenario = _resolveScenario(chatProvider);
    if (scenario == null) return;

    final scenarioProvider =
        Provider.of<ScenarioProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppTheme.retroDark, width: 3),
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          l10n.scenarioFinishTitle,
          style: AppFonts.pressStart2p(fontSize: 10, color: AppTheme.retroDark),
        ),
        content: Text(
          l10n.scenarioFinishBody,
          style: AppFonts.pressStart2p(
              fontSize: 8, height: 1.8, color: AppTheme.retroDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.scenarioFinishCancel.toUpperCase(),
              style: AppFonts.pressStart2p(
                  fontSize: 8, color: AppTheme.retroDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.scenarioFinishConfirm.toUpperCase(),
              style: AppFonts.pressStart2p(
                  fontSize: 8, color: AppTheme.retroPrimary),
            ),
          ),
        ],
      ),
    );

    // A reply can land while the dialog is open and complete the run properly;
    // the latch is what stops that from being paid twice.
    if (confirmed != true || !mounted || _completionHandled) return;
    _completionHandled = true;

    final clearedThisRun =
        Set<String>.from(scenarioProvider.forScenario(scenario.id)
            .clearedObjectiveIds);
    final reward = ProgressionUtils.getScenarioPartialOutcome(
      objectivesCleared: clearedThisRun.where(scenario.hasObjective).length,
      objectivesTotal: scenario.objectives.length,
    );

    scenarioProvider.endRunEarly(scenario);
    await _payOutRun(scenario, reward, clearedThisRun);
  }

  /// Grants a finished run's reward and shows the summary.
  ///
  /// Shared by the full clear and the early finish so the two can never drift
  /// on sick scaling, gold capping, or what the popup is told.
  Future<void> _payOutRun(
    ScenarioDefinition scenario,
    ScenarioRewardOutcome reward,
    Set<String> clearedThisRun,
  ) async {
    final characterProvider =
        Provider.of<CharacterProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final adsProvider = Provider.of<AdsProvider>(context, listen: false);

    // Scale while the pet is still in its pre-reward condition, matching the
    // quiz flow — a sick pet earns half.
    final wasSick = characterProvider.isSick;
    // Not scaled by sickness: see the note on the per-message XP above.
    final grantedXp = reward.xpReward;

    characterProvider.applyQuizRewards(
      happinessDelta: reward.happinessDelta,
      hungerDelta: reward.hungerDelta,
    );
    await userProvider.addXp(grantedXp);
    final coinAward = await userProvider.awardLearningGold(
      characterProvider.scaleReward(reward.coinReward),
      GoldSource.scenario,
    );
    final grantedCoins = coinAward.paid;

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => ScenarioCompletePopup(
        scenario: scenario,
        clearedObjectiveIds: clearedThisRun,
        reward: reward,
        grantedXp: grantedXp,
        grantedCoins: grantedCoins,
        sickPenaltyApplied: wasSick,
        onContinue: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );

    // After the reward popup, never before it, and on the same guard the quiz
    // uses: the payoff for a five-minute conversation must not be the thing
    // that gets interrupted.
    if (!mounted) return;
    await adsProvider.maybeShowInterstitial();

    // The run is paid out: drop the finish control so the checklist that just
    // reset can't be cashed in a second time on this screen.
    if (mounted) setState(() {});
  }

  String _formatTime(DateTime date) {
    // Simple formatter since we don't have intl setup yet: "TODAY hh:mm AM"
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return "TODAY $hour:$minute $amPm";
  }

  void _openSidebar() {
    _sidebarController.animateTo(
      1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _closeSidebar() {
    _sidebarController.animateTo(
      0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  void _onSidebarDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragStartProgress = _sidebarController.value;
  }

  void _onSidebarDragUpdate(DragUpdateDetails details) {
    if (_dragStartX == null) return;

    final dragDx = details.globalPosition.dx - _dragStartX!;
    final progressDelta = dragDx / _sidebarWidth;
    final newProgress = (_dragStartProgress + progressDelta).clamp(0.0, 1.0);
    _sidebarController.value = newProgress;
  }

  void _onSidebarDragEnd(DragEndDetails details) {
    final velocityX = details.velocity.pixelsPerSecond.dx;

    if (velocityX > 650) {
      _openSidebar();
    } else if (velocityX < -650) {
      _closeSidebar();
    } else {
      final current = _sidebarController.value;
      final delta = current - _dragStartProgress;

      if (_dragStartProgress <= 0.01) {
        if (delta > _swipeThreshold) {
          _openSidebar();
        } else {
          _closeSidebar();
        }
      } else if (_dragStartProgress >= 0.99) {
        if (-delta > _swipeThreshold) {
          _closeSidebar();
        } else {
          _openSidebar();
        }
      } else {
        if (current >= 0.5) {
          _openSidebar();
        } else {
          _closeSidebar();
        }
      }
    }

    _dragStartX = null;
  }

  /// The sidebar's new-chat button. Roleplay scenarios are not offered here:
  /// they live in the town, which has its own tab.
  void _startNewChat() {
    if (!mounted) return;
    context.goNamed('new_chat');
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final l10n = AppLocalizations.of(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

    if (_isConnecting && _currentChatId == null) {
      return const Scaffold(
        backgroundColor: AppTheme.retroSky,
        body: Center(child: CircularProgressIndicator(color: AppTheme.retroDark)),
      );
    }
    
    // Watch provider for updates
    final chatProvider = Provider.of<ChatProvider>(context);
    // Safe access to messages
    final messages = _currentChatId != null ? chatProvider.getMessages(_currentChatId!) : <Message>[];
    final scenario = _resolveScenario(chatProvider);
    // Read here, above this screen's Scaffold: its body sees no keyboard
    // inset, because the Scaffold has already made room for the keyboard.
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    final coins = Provider.of<UserProvider>(context).coins;

    return TutorialOfferHost(
      id: TutorialId.chat,
      // The message list is a spinner until the session is up, and the tour
      // opens on the button that reveals the chat list.
      enabled: !_isConnecting,
      steps: () => [
        chatMenuShowcaseKey,
        chatMessagesShowcaseKey,
        chatInputShowcaseKey,
      ],
      child: Scaffold(
      backgroundColor: AppTheme.retroLight,
      body: AnimatedBuilder(
        animation: _sidebarController,
        builder: (context, _) {
          final sidebarProgress = _sidebarController.value;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onSidebarDragStart,
            onHorizontalDragUpdate: _onSidebarDragUpdate,
            onHorizontalDragEnd: _onSidebarDragEnd,
            child: Stack(
              children: [
          // 1. Dither Background Pattern
          Positioned.fill(
             child: CustomPaint(
               painter: DitherPatternPainter(),
             ),
          ),

          // 2. Main Layout
          Column(
            children: [
              ChatHeader(
                onOpenSidebar: () {
                  _openSidebar();
                },
                menuShowcaseKey: chatMenuShowcaseKey,
                menuShowcaseDescription: l10n?.tutorialChatMenu,
              ),
              
              // Date Badge
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withValues(alpha: 0.1),
                child: Text(
                  _formatTime(DateTime.now()), 
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                ),
              ),

              // A tracked scenario is set in its place, with its host pet;
              // the room's sign carries the title. A custom scenario has no
              // place, so it keeps the plain banner.
              if (scenario != null)
                ScenarioStage(
                  scenario: scenario,
                  learnerTurns:
                      messages.where((m) => m.sender == 'user').length,
                  hostTurns: messages.where((m) => m.sender == 'bot').length,
                  hostThinking: _awaitingReply ||
                      (_isConnecting && messages.isEmpty),
                  compact: keyboardUp,
                  offer: _serviceOffer,
                  canAffordOffer: _serviceOffer != null &&
                      coins >= _serviceOffer!.price,
                  onPay: _payForService,
                  onDecline: () => setState(() => _serviceOffer = null),
                  lastBought: _lastService,
                  servicesBought: _servicesBought,
                )
              else if (_resolveScenarioTitle(chatProvider) != null)
                 Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.retroDark, width: 2), color: AppTheme.retroAccent),
                  child: Text(
                    "SCENARIO: ${_resolveScenarioTitle(chatProvider) ?? ''}".toUpperCase(),
                    textDirection: textDirection,
                    textAlign: textAlign,
                    style: AppFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                  ),
                ),

              // Objective checklist for tracked scenarios. The tutor never
              // says what's left, so this is the only place that answers it.
              if (scenario != null)
                ScenarioObjectiveTracker(
                  scenario: scenario,
                  onFinish: _completionHandled ? null : _finishRunEarly,
                ),

              Expanded(
                // Inside the Expanded, which has to stay a direct child of
                // the Column.
                child: RetroShowcase(
                  showcaseKey: chatMessagesShowcaseKey,
                  description:
                      l10n?.tutorialChatMessages ?? 'Your conversation.',
                  targetPadding: EdgeInsets.zero,
                  child: _isConnecting 
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.retroDark))
                  : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      if (msg.sender == 'system') return const SizedBox.shrink(); 
                    
                      return MessageBubble(
                        text: msg.content, 
                        isUser: msg.sender == 'user',
                        translation: msg.translation,
                        grammarAnalysis: msg.grammarAnalysis,
                        reading: msg.reading,
                      );
                    },
                  ),
                ),
              ),
              RetroShowcase(
                showcaseKey: chatInputShowcaseKey,
                description: l10n?.tutorialChatInput ?? 'Write here.',
                isLast: true,
                targetPadding: EdgeInsets.zero,
                child: ChatInput(onSend: _handleSend),
              ),
            ],
          ),
              if (sidebarProgress > 0)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closeSidebar,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.30 * sidebarProgress),
                    ),
                  ),
                ),

              Positioned(
                left: (-_sidebarWidth + (_sidebarWidth * sidebarProgress)),
                top: 0,
                bottom: 0,
                width: _sidebarWidth,
                child: ChatSidebar(
                  chats: chatProvider.chats,
                  activeChatId: _currentChatId,
                  onClose: _closeSidebar,
                  onStartNewChat: _startNewChat,
                  onSelectChat: (id) {
                    _closeSidebar();
                    if (id == _currentChatId) return;
                    // Resolved now rather than after the delay: `mounted`
                    // guards this State, not the builder's context, so the
                    // router has to be captured while the tree is still up.
                    final router = GoRouter.of(context);
                    Future.delayed(const Duration(milliseconds: 120), () {
                      if (!mounted) return;
                      router.goNamed('chat', pathParameters: {'chatId': id});
                    });
                  },
                ),
              ),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class DitherPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.retroUi.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    // Draw simple dots grid pattern
    const double step = 6.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        if ((x / step).floor() % 2 == (y / step).floor() % 2) { 
           canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
