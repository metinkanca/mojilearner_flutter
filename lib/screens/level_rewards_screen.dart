import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../constants/theme.dart';

class LevelRewardsScreen extends StatefulWidget {
  const LevelRewardsScreen({super.key});

  @override
  State<LevelRewardsScreen> createState() => _LevelRewardsScreenState();
}

class _LevelRewardsScreenState extends State<LevelRewardsScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _rewards = [
    {'level': 1, 'reward': '150 gold'},
    {'level': 2, 'reward': '200 gold'},
    {'level': 3, 'reward': 'Color unlock: Blue Fur'},
    {'level': 4, 'reward': '250 gold'},
    {'level': 5, 'reward': 'Food item (meal) + 200 gold'},
    {'level': 6, 'reward': '300 gold'},
    {'level': 7, 'reward': 'Cosmetic: Eye Shape A'},
    {'level': 8, 'reward': 'Boost: +20% XP (24h)'},
    {'level': 9, 'reward': '350 gold'},
    {'level': 10, 'reward': 'Background: Green Hills'},
  ];

  @override
  void initState() {
    super.initState();
    // We will initialize the controller in the build method or didChangeDependencies
    // to ensure we have access to the provider for the initial page.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentLevel = userProvider.stats.level;
    // Ensure we don't go out of bounds if level > 10
    final initialIndex = (currentLevel - 1).clamp(0, _rewards.length - 1);
    
    _pageController = PageController(
      viewportFraction: 0.65, // Smaller fraction to show more side content
      initialPage: initialIndex
    );
    _currentPage = initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentLevel = userProvider.stats.level;

    return Scaffold(
      backgroundColor: AppTheme.background, // Or a specific gradient from image
      appBar: AppBar(
        title: Text(
          'Level Rewards',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _rewards.length,
              itemBuilder: (context, index) {
                final item = _rewards[index];
                final level = item['level'] as int;
                final reward = item['reward'] as String;
                final isCurrentLevel = level == currentLevel;
                // Since this runs in build, we can adjust visual state
                // However, PageView builds scrolling items. 
                // We want smooth scaling.
                
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0); 
                    } else {
                       value = index == _currentPage ? 1.0 : 0.7;
                    }
                    
                    return Center(
                      child: SizedBox(
                        height: 380, // Taller fixed height to prevent overflow
                         child: Transform.scale(
                           scale: value,
                           child: child,
                         ),
                      ),
                    );
                  },
                  child: AspectRatio(
                    aspectRatio: 0.8, // Slightly taller than square (4:5) to fit content
                    child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    decoration: BoxDecoration(
                      color: isCurrentLevel 
                        ? const Color(0xFF2563EB) // Active Level Color
                        : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.1),
                           blurRadius: 10,
                           offset: const Offset(0, 5),
                         )
                      ],
                      border: isCurrentLevel 
                          ? Border.all(color: const Color(0xFF60A5FA), width: 2)
                          : Border.all(color: Colors.transparent),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Reduced padding
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "LEVEL",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isCurrentLevel ? Colors.white70 : Colors.grey[400],
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4), // Reduced spacing
                          Text(
                            "$level",
                            style: GoogleFonts.poppins(
                              fontSize: 56, // Reduced font size
                              fontWeight: FontWeight.w900,
                              color: isCurrentLevel ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            width: 40,
                            color: isCurrentLevel ? Colors.white30 : Colors.grey[200],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "REWARD",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isCurrentLevel ? Colors.white70 : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded( // Allow reward text to flex if needed
                            child: Center(
                              child: Text(
                                reward,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  height: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrentLevel ? Colors.white : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                          if (level < currentLevel) ...[
                            const SizedBox(height: 12),
                            const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 28)
                          ] else if (level == currentLevel) ...[
                             const SizedBox(height: 12),
                             Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.2),
                                 borderRadius: BorderRadius.circular(20)
                               ),
                               child: Text(
                                 "Current",
                                 style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                               ),
                             )
                          ] else ...[
                             const SizedBox(height: 12),
                             Icon(Icons.lock, color: Colors.grey[300], size: 24),
                          ]
                        ],
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
