import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/language_provider.dart';
import '../constants/theme.dart';

class ChatSidebar extends StatelessWidget {
  final List<Chat> chats;
  final VoidCallback onClose;
  final Function(String) onSelectChat;
  final String? activeChatId;

  const ChatSidebar({
    super.key,
    required this.chats,
    required this.onClose,
    required this.onSelectChat,
    this.activeChatId,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.getTranslations();

    return Container(
      width: 300,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppTheme.retroLight,
        border: Border(right: BorderSide(color: AppTheme.retroDark, width: 4)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.retroDark, width: 4)),
              color: AppTheme.retroBlue,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (translations['chats'] ?? 'CHATS').toUpperCase(),
                  style: GoogleFonts.pressStart2p(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppTheme.retroDark, width: 2),
                      boxShadow: const [
                        BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))
                      ]
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppTheme.retroDark),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.retroDark, width: 2),
                boxShadow: const [
                   BoxShadow(color: AppTheme.retroDark, offset: Offset(2, 2))
                ]
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: (translations['searchPlaceholder'] ?? 'SEARCH...').toUpperCase(),
                  hintStyle: GoogleFonts.pressStart2p(fontSize: 10, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppTheme.retroDark),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  isDense: true,
                ),
                style: GoogleFonts.pressStart2p(fontSize: 10, color: AppTheme.retroDark),
              ),
            ),
          ),

          // New Chat Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () {
                onClose();
                context.pushNamed('new_chat');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.retroGreen,
                  border: Border.all(color: AppTheme.retroDark, width: 2),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 16, color: AppTheme.retroDark),
                    const SizedBox(width: 8),
                    Text(
                      (translations['newChat'] ?? 'NEW CHAT').toUpperCase(),
                      style: GoogleFonts.pressStart2p(
                        fontSize: 10, 
                        color: AppTheme.retroDark
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(thickness: 4, color: AppTheme.retroDark, height: 4),

          // Chat List
          Expanded(
            child: chats.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline,
                            size: 32, color: AppTheme.retroDark),
                        const SizedBox(height: 16),
                        Text(
                          (translations['noChats'] ?? 'NO CHATS YET').toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            color: AppTheme.retroDark,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final isActive = chat.id == activeChatId;
                      return InkWell(
                        onTap: () => onSelectChat(chat.id),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.retroOrange : Colors.transparent,
                            border: const Border(bottom: BorderSide(color: AppTheme.retroDark, width: 2)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppTheme.retroDark, width: 2),
                                ),
                                child: const Center(
                                  child: Text('🤖', style: TextStyle(fontSize: 16)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            chat.title.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.pressStart2p(
                                              fontSize: 10,
                                              color: AppTheme.retroDark,
                                            ),
                                          ),
                                        ),
                                        // Simple date formatting
                                        Text(
                                          '${chat.createdAt.day}/${chat.createdAt.month}',
                                          style: GoogleFonts.pressStart2p(
                                            fontSize: 8,
                                            color: AppTheme.retroDark.withOpacity(0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      chat.lastMessage?.content.toUpperCase() ??
                                          'EMPTY',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.pressStart2p(
                                        fontSize: 8,
                                        color: AppTheme.retroDark.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
