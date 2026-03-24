import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/progression.dart';
import '../constants/shop.dart';
import '../models/models.dart';
import '../providers/settings_provider.dart';

class DailyRewardsDialog extends StatefulWidget {
  final DailyRewardInfo rewardInfo;
  final VoidCallback onClaim;

  const DailyRewardsDialog({
    super.key,
    required this.rewardInfo,
    required this.onClaim,
  });

  @override
  State<DailyRewardsDialog> createState() => _DailyRewardsDialogState();
}

class _DailyRewardsDialogState extends State<DailyRewardsDialog>
    with SingleTickerProviderStateMixin {
  bool _claimed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getText(String key, String fallback) {
    try {
      final languageProvider = Provider.of<dynamic>(context, listen: false);
      final translations = languageProvider.getTranslations() as Map<String, String>;
      return translations[key] ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _getDayStreakText(int dayNumber) {
    try {
      final languageProvider = Provider.of<dynamic>(context, listen: false);
      final translations = languageProvider.getTranslations() as Map<String, String>;
      final template = translations['day_streak'] ?? 'Day {X} Streak';
      return template.replaceAll('{X}', dayNumber.toString());
    } catch (_) {
      return 'Day $dayNumber Streak';
    }
  }

  String _getAmazingStreakText(int dayNumber) {
    try {
      final languageProvider = Provider.of<dynamic>(context, listen: false);
      final translations = languageProvider.getTranslations() as Map<String, String>;
      final template = translations['amazing_streak'] ?? 'Amazing! Day {X} streak!';
      return template.replaceAll('{X}', dayNumber.toString());
    } catch (_) {
      return 'Amazing! Day $dayNumber streak!';
    }
  }

  String _getMotivationalMessage() {
    if (widget.rewardInfo.streakReset) {
      return _getText('streak_broken', 'Welcome back! Starting fresh');
    }
    if (widget.rewardInfo.dayNumber == 7) {
      return _getAmazingStreakText(widget.rewardInfo.dayNumber);
    }
    return _getText('keep_going', 'Keep it going!');
  }

  String _getRewardDisplayText() {
    final reward = widget.rewardInfo.reward as RewardDef;
    if (reward.type == RewardType.coins) {
      return '${reward.value} 🪙';
    } else if (reward.type == RewardType.item && reward.itemId != null) {
      final item = shopItems.firstWhere(
        (i) => i.id == reward.itemId,
        orElse: () => shopItems.first,
      );
      final itemName = item.name;
      return '${item.icon} $itemName ${reward.value > 1 ? 'x${reward.value}' : ''}';
    }
    return reward.description;
  }

  String _getRewardIcon() {
    final reward = widget.rewardInfo.reward as RewardDef;
    if (reward.type == RewardType.coins) {
      return '🪙';
    } else if (reward.type == RewardType.item && reward.itemId != null) {
      final item = shopItems.firstWhere(
        (i) => i.id == reward.itemId,
        orElse: () => shopItems.first,
      );
      return item.icon;
    }
    return '🎁';
  }

  void _handleClaim() async {
    setState(() => _claimed = true);
    _animationController.forward();

    // Call the claim callback
    widget.onClaim();

    // Wait for animation then close
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final fontFunction = settings.usePixelFont
        ? GoogleFonts.pressStart2p
        : GoogleFonts.spaceMono;

    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.retroDark, width: 4),
        borderRadius: BorderRadius.zero,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.retroDark, width: 4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                _getText('daily_reward', 'Daily Reward').toUpperCase(),
                style: fontFunction(
                  fontSize: 14,
                  color: AppTheme.retroDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Streak Display
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.retroAccent,
                  border: Border.all(color: AppTheme.retroDark, width: 3),
                  boxShadow: const [
                    BoxShadow(color: AppTheme.retroDark, offset: Offset(4, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🔥',
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getDayStreakText(widget.rewardInfo.dayNumber),
                      style: fontFunction(
                        fontSize: 12,
                        color: AppTheme.retroDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Reward Display
              if (!_claimed) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.retroLight,
                    border: Border.all(color: AppTheme.retroDark, width: 3),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getRewardIcon(),
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getRewardDisplayText(),
                        textAlign: TextAlign.center,
                        style: fontFunction(
                          fontSize: 10,
                          color: AppTheme.retroDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        children: [
                          const Text(
                            '✨',
                            style: TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _getText('reward_claimed', 'Reward Claimed!').toUpperCase(),
                            textAlign: TextAlign.center,
                            style: fontFunction(
                              fontSize: 12,
                              color: AppTheme.retroPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Motivational Message
              Text(
                _getMotivationalMessage(),
                textAlign: TextAlign.center,
                style: fontFunction(
                  fontSize: 9,
                  color: AppTheme.retroDark,
                ),
              ),

              const SizedBox(height: 24),

              // 7-Day Calendar
              _SevenDayCalendar(
                currentDayNumber: widget.rewardInfo.dayNumber,
                fontFunction: fontFunction,
              ),

              const SizedBox(height: 24),

              // Claim Button or Come Back Tomorrow message
              if (!_claimed) ...[
                GestureDetector(
                  onTap: _handleClaim,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.retroPrimary,
                      border: Border.all(color: AppTheme.retroDark, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: AppTheme.retroDark, offset: Offset(4, 4)),
                      ],
                    ),
                    child: Text(
                      _getText('claim_reward', 'Claim Reward').toUpperCase(),
                      style: fontFunction(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getText('come_back_tomorrow', 'Come back tomorrow!'),
                  textAlign: TextAlign.center,
                  style: fontFunction(
                    fontSize: 8,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SevenDayCalendar extends StatelessWidget {
  final int currentDayNumber;
  final TextStyle Function({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) fontFunction;

  const _SevenDayCalendar({
    required this.currentDayNumber,
    required this.fontFunction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isCompleted = dayNumber <= currentDayNumber;
        final isToday = dayNumber == currentDayNumber;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.retroGrass : AppTheme.retroLight,
              border: Border.all(
                color: isToday ? AppTheme.retroAccent : AppTheme.retroDark,
                width: isToday ? 3 : 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Text(
                      dayNumber.toString(),
                      style: fontFunction(
                        fontSize: 8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
