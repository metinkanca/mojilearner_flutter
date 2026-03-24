import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../constants/theme.dart';
import '../../components/character_sprite.dart';
import '../../providers/user_provider.dart';
import '../../l10n/app_localizations.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _continue(BuildContext context) {
    final username = _controller.text.trim();
    if (username.isNotEmpty) {
      Provider.of<UserProvider>(context, listen: false).updateUsername(username);
      context.go('/onboarding/target-language');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    '2/8',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppTheme.retroDark, width: 2),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 2 / 8,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          color: AppTheme.retroAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    l10n.whatsYourName,
                    style: GoogleFonts.pressStart2p(
                      fontSize: 12,
                      color: AppTheme.retroDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Character
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(6, 6),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Center(
                child: CharacterSprite(
                  width: 90,
                  height: 90,
                ),
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Input field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.retroDark, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pressStart2p(
                    fontSize: 16,
                    color: AppTheme.retroDark,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.enterYourName,
                    hintStyle: GoogleFonts.pressStart2p(
                      fontSize: 10,
                      color: AppTheme.retroDark.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  onSubmitted: (_) => _continue(context),
                ),
              ),
            ),
            
            const Spacer(),
            
            // Continue button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return GestureDetector(
                    onTap: () {
                      if (hasText) {
                        _continue(context);
                      }
                    },
                    child: Opacity(
                      opacity: hasText ? 1.0 : 0.5,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.retroPrimary,
                          border: Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: hasText
                              ? [
                                  const BoxShadow(
                                    color: AppTheme.retroDark,
                                    offset: Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          l10n.continueBtn,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
