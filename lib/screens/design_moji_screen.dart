import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/faces.dart';
import '../constants/shop.dart';
import '../constants/theme.dart';
import '../components/modern_avatar.dart';

class DesignMojiScreen extends StatefulWidget {
  const DesignMojiScreen({super.key});

  @override
  State<DesignMojiScreen> createState() => _DesignMojiScreenState();
}

class _DesignMojiScreenState extends State<DesignMojiScreen> {
  String activeTab = 'faces'; // 'faces', 'color'

  @override
  Widget build(BuildContext context) {
    final characterProvider = Provider.of<CharacterProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final translations = languageProvider.getTranslations();

    final customization = characterProvider.customization;
    final level = userProvider.stats.level;
    
    final fontFunction = settingsProvider.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        title: Text(
          translations['designMoji'] ?? 'DESIGN MOJI',
          style: fontFunction(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.retroDark,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.retroDark, width: 3),
            boxShadow: const [
              BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(2, 2),
                  blurRadius: 0)
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppTheme.retroDark, size: 20),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: Column(
        children: [
          // Preview Area
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: AppTheme.retroDark,
                  offset: Offset(6, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                ModernAvatar(
                  size: 140,
                  openFace: customization.openFace,
                  closedFace: customization.closedFace,
                  characterColor: Color(int.parse(customization.color.replaceAll('#', '0xFF'))),
                  backgroundColor: Color(int.parse(customization.backgroundColor.replaceAll('#', '0xFF'))),
                ),
                const SizedBox(height: 16),
                Text(
                  'YOUR MOJI',
                  style: fontFunction(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.retroDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'TAP TO CUSTOMIZE',
                  style: fontFunction(
                    fontSize: 8,
                    color: AppTheme.retroDark.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.retroDark, width: 3),
            ),
            child: Row(
              children: [
                _buildTab('faces', 'FACES', activeTab == 'faces', fontFunction),
                _buildTab('color', 'COLORS', activeTab == 'color', fontFunction),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: activeTab == 'faces'
                ? _buildFacesTab(characterProvider, level, translations, fontFunction)
                : _buildColorTab(context, characterProvider, translations, fontFunction),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, bool isActive, TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) fontFunction) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppTheme.retroAccent : Colors.white,
            border: Border(
              right: id == 'faces' ? const BorderSide(color: AppTheme.retroDark, width: 2) : BorderSide.none,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: fontFunction(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.retroDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacesTab(CharacterProvider provider, int level, Map<String, String> translations, TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) fontFunction) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFaceCategory('NEUTRAL', Faces.neutral, provider, level, fontFunction),
        _buildFaceCategory('HAPPY', Faces.happy, provider, level, fontFunction),
        _buildFaceCategory('EXCITED', Faces.excited, provider, level, fontFunction),
        _buildFaceCategory('THINKING', Faces.thinking, provider, level, fontFunction),
        _buildFaceCategory('CONFUSED', Faces.confused, provider, level, fontFunction),
      ],
    );
  }

  Widget _buildFaceCategory(String title, List<FaceDefinition> faces, CharacterProvider provider, int level, TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) fontFunction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.retroDark,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: Text(
            title,
            style: fontFunction(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: faces.map((face) {
            final isLocked = face.minLevel > level;
            final isSelected = provider.customization.openFace == face.open;

            return GestureDetector(
              onTap: () {
                if (!isLocked) {
                  provider.updateFace(face.open, closedFace: face.closed);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.retroDark,
                      content: Text(
                        'REACH LEVEL ${face.minLevel}!',
                        style: fontFunction(fontSize: 8, color: Colors.white),
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.retroAccent : Colors.white,
                  border: Border.all(
                    color: AppTheme.retroDark,
                    width: isSelected ? 4 : 3,
                  ),
                  boxShadow: isSelected ? const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ] : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        face.open,
                        textAlign: TextAlign.center,
                        style: fontFunction(
                          fontSize: 10,
                          color: isLocked ? Colors.grey[400]! : AppTheme.retroDark,
                        ),
                      ),
                    ),
                    if (isLocked)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.retroDark,
                            border: Border.all(color: AppTheme.retroDark, width: 2),
                          ),
                          child: const Icon(Icons.lock, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildColorTab(BuildContext context, CharacterProvider provider, Map<String, String> translations, TextStyle Function({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, double? height}) fontFunction) {
    
    final List<String> mascotColors = [
      '#FFFFFF', '#F3F4F6', '#FEF3C7', '#DBEAFE', '#FCE7F3', '#D1FAE5',
    ];

    final List<ShopItem> backgrounds = shopItems.where((i) => i.type == 'background').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.retroDark,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: Text(
            translations['mascotColor']?.toUpperCase() ?? 'MASCOT COLOR',
            style: fontFunction(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: mascotColors.map((color) {
            final isSelected = provider.customization.color == color;
             return GestureDetector(
              onTap: () => provider.updateColor(color),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                  border: Border.all(
                    color: AppTheme.retroDark,
                    width: isSelected ? 4 : 3,
                  ),
                  boxShadow: isSelected ? const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ] : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: AppTheme.retroDark, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.retroDark,
            border: Border.all(color: AppTheme.retroDark, width: 3),
          ),
          child: Text(
            translations['backgroundColor']?.toUpperCase() ?? 'BACKGROUND',
            style: fontFunction(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
         Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // Default background
             GestureDetector(
              onTap: () => provider.updateBackgroundColor('#60A5FA'),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA),
                  border: Border.all(
                    color: AppTheme.retroDark,
                    width: provider.customization.backgroundColor == '#60A5FA' ? 4 : 3,
                  ),
                  boxShadow: provider.customization.backgroundColor == '#60A5FA' ? const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    'DEFAULT',
                    textAlign: TextAlign.center,
                    style: fontFunction(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            ...backgrounds.map((bg) {
            final isUnlocked = provider.unlockedItems.contains(bg.id);
            final isSelected = provider.customization.backgroundColor == bg.value;
            
             return GestureDetector(
              onTap: () {
                if (isUnlocked) {
                  provider.updateBackgroundColor(bg.value!);
                } else {
                  // Prompt buy
                  showDialog(
                    context: context,
                    builder: (ctx) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(6, 6),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              bg.name.toUpperCase(),
                              style: fontFunction(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.retroDark,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Color(int.parse(bg.value!.replaceAll('#', '0xFF'))),
                                border: Border.all(color: AppTheme.retroDark, width: 3),
                              ),
                              child: Center(
                                child: Text(bg.icon, style: const TextStyle(fontSize: 40)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'UNLOCK FOR ${bg.price} GOLD?',
                              style: fontFunction(fontSize: 8, color: AppTheme.retroDark),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(ctx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      border: Border.all(color: AppTheme.retroDark, width: 3),
                                    ),
                                    child: Text(
                                      'CANCEL',
                                      style: fontFunction(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.retroDark),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(ctx);
                                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                                    final success = await provider.unlockItem(bg, userProvider);
                                    if (success && mounted) {
                                      provider.updateBackgroundColor(bg.value!);
                                    } else if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppTheme.retroDark,
                                          content: Text(
                                            'NOT ENOUGH COINS!',
                                            style: fontFunction(fontSize: 8, color: Colors.white),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.retroGreen,
                                      border: Border.all(color: AppTheme.retroDark, width: 3),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppTheme.retroDark,
                                          offset: Offset(2, 2),
                                          blurRadius: 0,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'BUY',
                                      style: fontFunction(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
              },
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Color(int.parse(bg.value!.replaceAll('#', '0xFF'))),
                  border: Border.all(
                    color: AppTheme.retroDark,
                    width: isSelected ? 4 : 3,
                  ),
                  boxShadow: isSelected ? const [
                    BoxShadow(
                      color: AppTheme.retroDark,
                      offset: Offset(3, 3),
                      blurRadius: 0,
                    ),
                  ] : null,
                ),
                child: Stack(
                  children: [
                    Center(child: Text(bg.icon, style: const TextStyle(fontSize: 32))),
                    if (!isUnlocked)
                       Positioned(
                        right: 2, bottom: 2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.retroDark,
                            border: Border.all(color: AppTheme.retroDark, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, color: Colors.white, size: 10),
                              const SizedBox(width: 2),
                              Text(
                                '${bg.price}',
                                style: fontFunction(fontSize: 7, color: Colors.white),
                              ),
                            ],
                          ),
                        )
                       )
                  ],
                ),
              ),
            );
          }),
          ]
        ),
      ],
    );
  }
}
