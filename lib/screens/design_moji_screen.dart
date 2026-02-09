import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/character_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../constants/faces.dart';
import '../constants/shop.dart';
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
    final translations = languageProvider.getTranslations();

    final customization = characterProvider.customization;
    final level = userProvider.stats.level;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          translations['designMoji'] ?? 'Design Moji',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Preview Area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                ModernAvatar(
                  size: 160,
                  openFace: customization.openFace,
                  closedFace: customization.closedFace,
                  characterColor: Color(int.parse(customization.color.replaceAll('#', '0xFF'))),
                  backgroundColor: Color(int.parse(customization.backgroundColor.replaceAll('#', '0xFF'))),
                ),
                const SizedBox(height: 16),
                Text(
                  translations['fullCustomization'] ?? 'Full Customization',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  translations['tapToChange'] ?? 'Tap to change look',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTab('faces', translations['faceExpressions'] ?? 'Face Expressions', activeTab == 'faces'),
                _buildTab('color', 'Color', activeTab == 'color'),
              ],
            ),
          ),

          Expanded(
            child: activeTab == 'faces'
                ? _buildFacesTab(characterProvider, level, translations)
                : _buildColorTab(characterProvider, translations),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => activeTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacesTab(CharacterProvider provider, int level, Map<String, String> translations) {
    // Flatten faces for display or group by category
    // Here we'll just show all categories
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildFaceCategory('Neutral', Faces.neutral, provider, level),
        _buildFaceCategory('Happy', Faces.happy, provider, level),
        _buildFaceCategory('Excited', Faces.excited, provider, level),
        _buildFaceCategory('Thinking', Faces.thinking, provider, level),
        _buildFaceCategory('Confused', Faces.confused, provider, level),
      ],
    );
  }

  Widget _buildFaceCategory(String title, List<FaceDefinition> faces, CharacterProvider provider, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
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
                      content: Text('Reach level ${face.minLevel} to unlock!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        face.open,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (isLocked)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Icon(Icons.lock, size: 14, color: Colors.grey[400]),
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

  Widget _buildColorTab(CharacterProvider provider, Map<String, String> translations) {
    
    final List<String> mascotColors = [
      '#FFFFFF', '#F3F4F6', '#FEF3C7', '#DBEAFE', '#FCE7F3', '#D1FAE5',
    ];

    final List<ShopItem> backgrounds = shopItems.where((i) => i.type == 'background').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          translations['mascotColor'] ?? 'Mascot Color',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
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
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                  ]
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 32),

         Text(
          translations['backgroundColor'] ?? 'Background Color',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: provider.customization.backgroundColor == '#60A5FA' ? const Color(0xFF1E40AF) : Colors.transparent,
                    width: 3,
                  )
                ),
                child: const Center(child: Text('Default', style: TextStyle(fontSize: 10, color: Colors.white))),
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
                    builder: (ctx) => AlertDialog(
                      title: Text(bg.name),
                      content: Text('Unlock for ${bg.price} coins?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            if (provider.unlockItem(bg)) {
                               provider.updateBackgroundColor(bg.value!);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Not enough coins!")));
                            }
                          }, 
                          child: const Text('Buy')
                        ),
                      ],
                    )
                   );
                }
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(int.parse(bg.value!.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected ? [
                    const BoxShadow(color: Colors.black26, blurRadius: 4),
                  ] : []
                ),
                child: Stack(
                  children: [
                    Center(child: Text(bg.icon, style: const TextStyle(fontSize: 24))),
                    if (!isUnlocked)
                       Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.only(topLeft: Radius.circular(8))),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, color: Colors.white, size: 10),
                              Text('${bg.price}', style: const TextStyle(color: Colors.white, fontSize: 10)),
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
