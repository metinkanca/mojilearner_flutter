import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../components/chat_header.dart';
import '../../components/chat_input.dart';
import '../../components/message_bubble.dart';
import '../../components/chat_sidebar.dart';
import '../../models/models.dart';
import '../../providers/language_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/mistakes_provider.dart';
import '../../providers/character_provider.dart';
import '../../providers/user_provider.dart';
import 'dart:convert'; // For JSON parsing

class ChatScreen extends StatefulWidget {
  final String? chatId;
  final String? scenarioTitle;

  const ChatScreen({
    super.key,
    this.chatId,
    this.scenarioTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // AI State
  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isConnecting = true;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupChat();
    });
  }

  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chatId != oldWidget.chatId || widget.scenarioTitle != oldWidget.scenarioTitle) {
      _setupChat();
    }
  }

  Future<void> _setupChat() async {
    setState(() => _isConnecting = true); // Start loading
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    try {
      if (widget.scenarioTitle != null) {
        // Creating a NEW Scenario Chat
        // We create it immediately so we have an ID to save messages to
        final newId = await chatProvider.createNewChat(
          title: widget.scenarioTitle!, 
          type: "scenario"
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
    
    // Safety check
    if (_currentChatId == null) return;

    final targetLang = languageProvider.targetLanguage?.name ?? 'Spanish';
    final nativeLang = languageProvider.nativeLanguage.name;
    
    // --- 1. Construct System Instruction ---
    String systemInstruction = '''
You are a friendly and helpful language tutor helping the user learn $targetLang.
The user speaks $nativeLang.

IMPORTANT RESPONSE FORMAT:
You must ALWAYS structure your response strictly in these three parts:
TEXT: [Your response in $targetLang ONLY]
TRANS: [The translation in $nativeLang]
GRAMMAR: [The grammar breakdown in $nativeLang]

For the GRAMMAR section, follow this structure found below.
Your goal is to help the user REUSE the sentence, not just understand it.
IMPORTANT: All explanations in the GRAMMAR section must be in $nativeLang.

Guidelines:
- Be short and practical
- Prefer patterns over word-by-word explanations
- Avoid explaining obvious words unless necessary
- Use bullet points
- Avoid academic language
- Write ALL explanations in $nativeLang

Structure your GRAMMAR response exactly like this (but translate the content to $nativeLang):

1. Meaning:
   - Give a short, natural translation in $nativeLang

2. Core pattern:
   - Show the main structure of the sentence in a simple formula
   - Highlight which parts can change

3. How it works:
   - Briefly explain only the key grammar points in $nativeLang
   - Focus on agreement, tense, or structure if relevant

4. Try changing it:
   - Give 1–2 simple variations using the same pattern

Assume the user wants to speak, not analyze grammar.

Example (if user spoke English):
TEXT: Me gustaría pedir un café.
TRANS: I would like to order a coffee.
GRAMMAR: 
1. Meaning:
   - "I would like to order a coffee."

2. Core pattern:
   - [Me gustaría] + [Action] + [Thing]

3. How it works:
   - "Me gustaría" is the polite way to say "I would like".
   - It doesn't change regardless of who you are speaking to.

4. Try changing it:
   - Me gustaría comprar esto. (I would like to buy this.)
   - Me gustaría visitar México. (I would like to visit Mexico.)

MISTAKE HANDLING:
If the user makes a clear grammar or vocabulary mistake (not just style), append this HIDDEN block at the very end of your response (after GRAMMAR):
|||MISTAKE|||
{ "original": "user's wrong text", "correction": "correct text", "explanation": "brief reason in $nativeLang", "type": "grammar" }
(Use type: "grammar" or "vocabulary")
    ''';

    if (widget.scenarioTitle != null) {  
        systemInstruction += '''
\nScenario: "${widget.scenarioTitle}".
You must stay strictly within this scenario roleplay.
Speak only in $targetLang (in the TEXT section).
Keep responses natural and concise.
        ''';
    } else {
        systemInstruction += '''
\nEngage in free-flowing conversation.
Correct mistakes gently if they block understanding.
        ''';
    }

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('No API Key');

      _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      // --- 2. Build History ---
      List<Content> history = [];
      
      if (!isNew) {
        // Load existing messages from Provider
        final messages = chatProvider.getMessages(_currentChatId!);
        
        // Filter and map to Gemini Content
        // We ignore 'system' messages for the model history to avoid confusing it
        history = messages
          .where((m) => m.sender == 'user' || m.sender == 'bot')
          .map((m) {
             return Content(m.sender == 'user' ? 'user' : 'model', [TextPart(m.content)]);
          }).toList();
      }

      // --- 3. Start Chat Session ---
      // We prepend the system instruction to history? 
      // GenerativeModel.startChat(history: ...) takes the full history.
      // Usually system instruction is just the first part or passed in valid google_ai logic (systemInstruction param is supported in newer SDKs, checking usage...)
      // The current google_generative_ai package supports `systemInstruction` in constructor usually or we just pass it in history.
      // Let's stick to passing it as first text part if needed, or rely on prompt engineering.
      // Since I used `Content.text(systemInstruction)` in the old code, I'll stick to that.
      
      final fullHistory = [
          Content.text(systemInstruction),
          Content.model([TextPart("Understood. I am ready to help you learn $targetLang.")]),
          ...history
      ];
      
      _chatSession = _model!.startChat(history: fullHistory);
      
      // --- 4. Initial Bot Message (If New) ---
      if (isNew) {
         String? initialPrompt;
         if (widget.scenarioTitle != null) {
             initialPrompt = "Start the roleplay now. Be creative.";
         } else {
             // For free chat, we might NOT want to prompt, just welcome message in UI?
             // Or prompt model to say hello.
             // Let's prompt model to say hello so it's in the history for sure.
             initialPrompt = "Say a warm hello to start the conversation.";
         }
         
         final response = await _chatSession!.sendMessage(Content.text(initialPrompt));
         if (response.text != null && mounted) {
            await _parseAndSaveBotResponse(response.text!);
         }
      }

    } catch (e) {
      debugPrint("AI Init Error: $e");
      // Add system error message to chat (optional)
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _handleSend(String text) async {
    if (_currentChatId == null || _chatSession == null) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    // 1. Add User Message to Provider
    await chatProvider.addMessage(_currentChatId!, Message(
      id: DateTime.now().toString(),
      content: text,
      sender: 'user',
      timestamp: DateTime.now()
    ));

    // 2. Send to AI
    try {
      final response = await _chatSession!.sendMessage(Content.text(text));
      
      if (response.text != null && mounted) {
        await _parseAndSaveBotResponse(response.text!);
        
        // Reward pet and XP for chatting
        final characterProvider = Provider.of<CharacterProvider>(context, listen: false);
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        if (widget.scenarioTitle != null) {
          characterProvider.rewardScenario();
          userProvider.addXp(10); // 10 XP for scenario messages
        } else {
          characterProvider.rewardChat();
          userProvider.addXp(5); // 5 XP per chat message
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
       }
    }
  }

  Future<void> _parseAndSaveBotResponse(String rawText) async {
      String content = rawText;
      
      // 1. Extract Mistake Data
      if (rawText.contains('|||MISTAKE|||')) {
        final parts = rawText.split('|||MISTAKE|||');
        content = parts[0].trim(); // Remove the JSON part from visible text
        
        if (parts.length > 1) {
          try {
            final jsonStr = parts[1].trim();
            final jsonMap = json.decode(jsonStr);
            if (mounted) {
              Provider.of<MistakesProvider>(context, listen: false).addMistake(
                jsonMap['original'] ?? '',
                jsonMap['correction'] ?? '',
                jsonMap['explanation'] ?? '',
                jsonMap['type'] ?? 'grammar'
              );
            }
          } catch (e) {
            debugPrint("Mistake JSON Error: $e");
          }
        }
      }

      String? translation;
      String? grammar;

      // Simple parsing of labeled sections
      final textMatch = RegExp(r'TEXT:\s*(.*?)(?=\nTRANS:|$)', dotAll: true).firstMatch(content);
      final transMatch = RegExp(r'TRANS:\s*(.*?)(?=\nGRAMMAR:|$)', dotAll: true).firstMatch(content);
      final grammarMatch = RegExp(r'GRAMMAR:\s*(.*)', dotAll: true).firstMatch(content);

      if (textMatch != null) {
         content = textMatch.group(1)?.trim() ?? content;
         translation = transMatch?.group(1)?.trim();
         grammar = grammarMatch?.group(1)?.trim();
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
        ));
      }
  }

  String _formatTime(DateTime date) {
    // Simple formatter since we don't have intl setup yet: "TODAY hh:mm AM"
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return "TODAY $hour:$minute $amPm";
  }

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.retroLight,
      drawer: Drawer(
        width: 300,
        child: ChatSidebar(
          chats: chatProvider.chats, 
          activeChatId: _currentChatId, 
          onClose: () => Navigator.pop(context),
          onSelectChat: (id) {
             Navigator.pop(context); // Close drawer
             if (id == _currentChatId) return;
             context.goNamed('chat', pathParameters: {'chatId': id});
          },
        ),
      ),
      body: Stack(
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
                  _scaffoldKey.currentState?.openDrawer();
                }
              ),
              
              // Date Badge
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: Colors.black.withOpacity(0.1),
                child: Text(
                  "${_formatTime(DateTime.now())}", 
                  style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                ),
              ),

              if (widget.scenarioTitle != null)
                 Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(border: Border.all(color: AppTheme.retroDark, width: 2), color: AppTheme.retroAccent),
                  child: Text(
                    "SCENARIO: ${widget.scenarioTitle ?? ''}".toUpperCase(),
                    style: GoogleFonts.pressStart2p(fontSize: 8, color: AppTheme.retroDark),
                  ),
                ),

              Expanded(
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
                    );
                  },
                ),
              ),
              ChatInput(onSend: _handleSend),
            ],
          ),
        ],
      ),
    );
  }
}

class DitherPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.retroUi.withOpacity(0.2)
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
