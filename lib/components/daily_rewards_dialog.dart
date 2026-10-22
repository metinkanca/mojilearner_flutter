import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../constants/progression.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/settings_provider.dart';
import '../utils/fonts.dart';
import '../utils/rtl_locale.dart';
import 'reward_art.dart';

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
    // No "welcome back, starting fresh" branch to write any more: nothing
    // starts fresh, so there is nothing to apologise for on the way in.
    //
    // The line says "streak", so it follows the run of days rather than the
    // reward cycle, and it comes round every seventh of them rather than once.
    final streak = widget.rewardInfo.loginStreak;
    if (streak > 0 && streak % 7 == 0) {
      return l10n.amazing_streak(streak);
    }
    return l10n.keep_going;
  }

  String _localizedShopItemName(
      AppLocalizations l10n, String itemId, String fallback) {
    switch (itemId) {
      case 'apple':
        return l10n.shopItemAppleName;
      case 'donut':
        return l10n.shopItemDonutName;
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

  /// The line under the reward's picture.
  ///
  /// It no longer opens with the emoji the picture above already draws — the
  /// two were the same symbol twice, and on a platform whose emoji font
  /// differs from the pixel art they were the same reward drawn two ways.
  String _getRewardDisplayText(AppLocalizations l10n) {
    final reward = widget.rewardInfo.reward;
    if (reward.type == RewardType.coins) {
      return l10n.topUpCoins(reward.value);
    }
    final item = rewardShopItem(reward);
    if (item != null) {
      final itemName = _localizedShopItemName(l10n, item.id, item.name);
      return reward.value > 1 ? '$itemName x${reward.value}' : itemName;
    }
    return reward.description;
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
                    SvgPicture.asset(kFlameAsset, width: 24, height: 24),
                    const SizedBox(width: 8),
                    // Flexible, not a bare Text: the label runs past the pill
                    // on a 320pt handset, and in the longer locales sooner
                    // than that. It wraps instead of overflowing.
                    Flexible(
                      child: Text(
                        // The run of days, not the position in the cycle:
                        // the seven boxes below already say where in the week
                        // this reward falls, and a pill reading "Day 3" to
                        // someone on their thirtieth day running was the last
                        // place the two numbers were still confused.
                        l10n.day_streak(widget.rewardInfo.loginStreak),
                        textDirection: textDirection,
                        textAlign: textAlign,
                        style: fontFunction(
                          fontSize: 12,
                          color: AppTheme.retroDark,
                          fontWeight: FontWeight.bold,
                        ),
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
                      RewardArt(
                        reward: widget.rewardInfo.reward,
                        size: 48,
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
                todayClaimed: _claimed,
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

/// The cycle drawn as a row of boxes: what each day of the week gives, and how
/// far through it the player is.
///
/// A box used to carry its own day number, which its position in the row
/// already said, so the row spent seven labels repeating itself and never
/// showed a single reward. Each box now draws the reward that day pays out,
/// and a day already collected is stamped with a check over green instead.
///
/// Today is the box on the boundary: it holds its reward while the claim
/// button is still there to press, and turns into a check the moment it is.
class _SevenDayCalendar extends StatelessWidget {
  final int currentDayNumber;

  /// Whether today's reward has been collected in this sitting. Days before
  /// today are always collected; today is only collected once claimed.
  final bool todayClaimed;

  const _SevenDayCalendar({
    required this.currentDayNumber,
    required this.todayClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final days = dailyRewards.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The markers at their full 32pt, plus the gaps between them, need
        // 280pt - more than the dialog leaves on a handset, where it gets 264.
        // Shrink the markers and their gaps together to fit rather than
        // dropping any, keeping full size wherever there is room for it.
        const maxMarkerSize = 32.0;
        const gapRatio = 0.25; // an 8pt gap at full marker size
        final available = constraints.maxWidth;
        final markerSize = available.isFinite
            ? math.min(
                maxMarkerSize, available / (days + (days - 1) * gapRatio))
            : maxMarkerSize;
        // The check glyph is sized off the marker: at 16pt its line box is
        // taller than a shrunk marker's interior.
        final checkFontSize =
            (16.0 * markerSize / maxMarkerSize).clamp(10.0, 16.0);
        // The art sits inside the marker's border with a little air around it,
        // so a wide sprite does not touch the frame on either side.
        final artSize = markerSize * 0.72;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: markerSize * gapRatio,
          children: List.generate(days, (index) {
            final dayNumber = index + 1;
            final isToday = dayNumber == currentDayNumber;
            final isClaimed =
                dayNumber < currentDayNumber || (isToday && todayClaimed);

            return Container(
              key: ValueKey('daily-reward-day-$dayNumber'),
              width: markerSize,
              height: markerSize,
              decoration: BoxDecoration(
                color: isClaimed ? AppTheme.retroGrass : AppTheme.retroLight,
                border: Border.all(
                  color: isToday ? AppTheme.retroAccent : AppTheme.retroDark,
                  width: isToday ? 3 : 2,
                ),
              ),
              child: Center(
                child: isClaimed
                    ? Text(
                        '\u2713',
                        style: TextStyle(
                          fontSize: checkFontSize,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : RewardArt(
                        reward: dailyRewards[index],
                        size: artSize,
                      ),
              ),
            );
          }),
        );
      },
    );
  }
}
