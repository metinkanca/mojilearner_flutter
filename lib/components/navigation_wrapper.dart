import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/language_provider.dart';

class NavigationWrapper extends StatelessWidget {
  final Widget child;

  const NavigationWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    final bool isHome = location == '/';
    final texts = Provider.of<LanguageProvider>(context).getTranslations();

    return Scaffold(
      extendBody: true, // Needs to be true for FAB to dock, but we might want false for retro feel
      resizeToAvoidBottomInset: false, // Let child handle it
      body: child,
      // Retro FAB
      floatingActionButton: Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
          color: AppTheme.retroPrimary,
          border: Border.all(color: AppTheme.retroDark, width: 4),
          boxShadow: const [BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4), blurRadius: 0)],
        ),
        child: FloatingActionButton(
          onPressed: () {
            if (location != '/') context.go('/');
          },
          backgroundColor: AppTheme.retroPrimary,
          elevation: 0, 
          shape: const RoundedRectangleBorder(), // Square
          child: SvgPicture.asset(
            'assets/svgs/icon-home.svg', 
            width: 24, 
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Container(
        height: 90,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.retroDark, width: 4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Left Side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(context, 'assets/svgs/icon-story.svg', texts['scenarios'] ?? 'Story', '/scenarios', location),
                  _navItem(
                    context, 
                    'assets/svgs/icon-chat.svg', 
                    texts['chats'] ?? 'Chat', 
                    '/new-chat', 
                    location, 
                    onTap: () async {
                       final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                       try {
                          await chatProvider.loadFuture;
                          if (context.mounted) {
                            if (chatProvider.chats.isNotEmpty) {
                              final lastChatId = chatProvider.chats.first.id;
                              context.goNamed('chat', pathParameters: {'chatId': lastChatId});
                            } else {
                              context.goNamed('new_chat');
                            }
                          }
                       } catch (e) {
                          if (context.mounted) context.goNamed('new_chat');
                       }
                    }
                  ),
                ],
              ),
            ),
            // Spacer for Fab
            const SizedBox(width: 80), 
            // Right Side
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(context, 'assets/svgs/icon-quiz.svg', texts['quizMode'] ?? 'Quiz', '/calibration', location),
                  _navItem(context, 'assets/svgs/icon-user.svg', texts['profile'] ?? 'User', '/profile', location),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String svgPath, String label, String route, String currentLocation, {VoidCallback? onTap}) {
    final bool isActive = currentLocation == route;
    final Color itemColor = isActive ? AppTheme.retroPrimary : Colors.grey;

    return GestureDetector(
      onTap: onTap ?? () {
        if (!isActive) context.push(route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            svgPath,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(itemColor, BlendMode.srcIn),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.pressStart2p(
              fontSize: 8,
              color: itemColor,
            ),
          ),
        ],
      ),
    );
  }
}

