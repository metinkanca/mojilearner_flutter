import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/progression.dart';
import '../constants/shop.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';

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

  String _getMotivationalMessage(AppLocalizations l10n) {
    if (widget.rewardInfo.streakReset) {
      return l10n.streak_broken;
    }
    if (widget.rewardInfo.dayNumber == 7) {
      return l10n.amazing_streak(widget.rewardInfo.dayNumber);
    }
    return l10n.keep_going;
  }

  String _localizedShopItemName(
      AppLocalizations l10n, String itemId, String fallback) {
    switch (itemId) {
      case 'apple':
        return l10n.shopItemAppleName;
      case 'croissant':
        return l10n.shopItemCroissantName;
      case 'pizza':
        return l10n.shopItemPizzaName;
      case 'sushi':
        return l10n.shopItemSushiName;
      case 'coffee':
        return l10n.shopItemCoffeeName;
      case 'bg_blue':
        return l10n.shopItemBgBlueName;
      case 'bg_forest':
        return l10n.shopItemBgForestName;
      case 'bg_sunset':
        return l10n.shopItemBgSunsetName;
      case 'bg_galaxy':
        return l10n.shopItemBgGalaxyName;
      default:
        return fallback;
    }
  }

  String _getRewardDisplayText(AppLocalizations l10n) {
    final reward = widget.rewardInfo.reward;
    if (reward.type == RewardType.coins) {
      return '${reward.value} 🪙';
    } else if (reward.type == RewardType.item && reward.itemId != null) {
      final item = shopItems.firstWhere(
        (i) => i.id == reward.itemId,
        orElse: () => shopItems.first,
      );
      final itemName = _localizedShopItemName(l10n, item.id, item.name);
      return '${item.icon} $itemName ${reward.value > 1 ? 'x${reward.value}' : ''}';
    }
    return reward.description;
  }

  String _getRewardIcon() {
    final reward = widget.rewardInfo.reward;
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
    final l10n = AppLocalizations.of(context)!;
    final fontFunction = settings.usePixelFont
      ? AppFonts.pressStart2p
      : AppFonts.spaceMono;
    final locale = Localizations.localeOf(context);
    final textDirection = textDirectionForLocale(locale);
    final textAlign = textAlignForLocale(locale);

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
                l10n.daily_reward.toUpperCase(),
                textDirection: textDirection,
                textAlign: TextAlign.center,
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
                      l10n.day_streak(widget.rewardInfo.dayNumber),
                      textDirection: textDirection,
                      textAlign: textAlign,
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
                        _getRewardDisplayText(l10n),
                        textDirection: textDirection,
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
                            l10n.reward_claimed.toUpperCase(),
                            textDirection: textDirection,
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
                _getMotivationalMessage(l10n),
                textDirection: textDirection,
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
                      l10n.claim_reward.toUpperCase(),
                      textDirection: textDirection,
                      textAlign: TextAlign.center,
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
                  l10n.come_back_tomorrow,
                  textDirection: textDirection,
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
