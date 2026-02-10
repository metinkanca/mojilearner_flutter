import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../constants/theme.dart';
import '../constants/progression.dart';

class LevelRewardsScreen extends StatefulWidget {
  const LevelRewardsScreen({super.key});

  @override
  State<LevelRewardsScreen> createState() => _LevelRewardsScreenState();
}

class _LevelRewardsScreenState extends State<LevelRewardsScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentLevel = userProvider.stats.level;
    final initialIndex = (currentLevel - 1).clamp(0, levelRewards.length - 1);

    _pageController = PageController(
        viewportFraction: 0.75, // Standard card width
        initialPage: initialIndex);
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
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final currentLevel = userProvider.stats.level;

    final fontFunction = settingsProvider.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

    return Scaffold(
      backgroundColor: AppTheme.retroSky,
      appBar: AppBar(
        title: Text(
          'LEVELS',
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
          const SizedBox(height: 20),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: levelRewards.length,
              itemBuilder: (context, index) {
                final item = levelRewards[index];
                final level = item.level;
                final reward = item.description;

                // State logic
                final isCurrent = level == currentLevel;
                final isLocked = level > currentLevel;

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                    } else {
                      value = index == _currentPage ? 1.0 : 0.8;
                    }

                    return Center(
                      child: SizedBox(
                        height: 450,
                        child: Transform.scale(
                          scale: value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.grey[200] : Colors.white,
                      border: Border.all(color: AppTheme.retroDark, width: 6),
                      boxShadow: const [
                        BoxShadow(
                          color: AppTheme.retroDark,
                          blurRadius: 0,
                          offset: Offset(8, 8),
                        )
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Header Status
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? AppTheme.retroDark
                                  : (isCurrent
                                      ? Colors.white
                                      : AppTheme.retroGreen),
                              border: Border.all(
                                  color: AppTheme.retroDark, width: 3),
                            ),
                            child: Text(
                              isCurrent
                                  ? "CURRENT"
                                  : (isLocked ? "LOCKED" : "COMPLETED"),
                              style: fontFunction(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? AppTheme.retroDark
                                    : Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Big Number Box
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: AppTheme.retroDark, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.retroDark,
                                  offset: Offset(4, 4),
                                )
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "$level",
                                style: fontFunction(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.retroDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "REWARD",
                            style: fontFunction(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.retroDark.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Fixed height container for reward text to prevent dynamic sizing
                          SizedBox(
                            height: 55, // Fixed height
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  reward.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: fontFunction(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: AppTheme.retroDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // XP Progress Info for Current Level
                          if (isCurrent) ...[
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                "${userProvider.stats.currentLevelXP} / ${userProvider.stats.nextLevelXP} XP",
                                style: fontFunction(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.retroDark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Progress bar
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  border: Border.all(
                                      color: AppTheme.retroDark, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppTheme.retroDark,
                                      offset: Offset(3, 3),
                                      blurRadius: 0,
                                    ),
                                  ],
                                ),
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: userProvider.stats.progress.clamp(0.0, 1.0),
                                      child: Container(
                                        height: double.infinity,
                                        color: AppTheme.retroGreen,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 20),

                          // Footer Indicator
                          if (isLocked)
                            Icon(Icons.lock, size: 32, color: Colors.grey[400])
                          else if (!isCurrent)
                            const Icon(Icons.check_circle,
                                size: 32, color: AppTheme.retroGreen)
                          else
                            const SizedBox(height: 32),
                          if (!isCurrent) const SizedBox(height: 12),
                        ],
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
