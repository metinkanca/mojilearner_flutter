import 'package:shared_preferences/shared_preferences.dart';

import '../constants/ads.dart';

/// Persists the ad ledger and the player's stated birth year.
///
/// Split out for the same reason `DailyRewardRepository` is: the provider
/// should be testable against a fake store, and the key names should live in
/// exactly one place. Every field here has to survive a restart — a daily
/// allowance that resets when the app is killed is not an allowance, a
/// cooldown that resets is not a cooldown, and an age question that is asked
/// again every launch is an annoyance rather than a safeguard.
class AdsRepository {
  static const String _dayKey = 'ads_day';
  static const String _rewardedWatchedKey = 'ads_rewarded_watched_today';
  static const String _lastInterstitialKey = 'ads_last_interstitial';
  static const String _birthYearKey = 'ads_birth_year';

  Future<AdLedger> load() async {
    final prefs = await SharedPreferences.getInstance();

    final dayMs = prefs.getInt(_dayKey);
    final lastInterstitialMs = prefs.getInt(_lastInterstitialKey);

    return AdLedger(
      day: dayMs == null ? null : DateTime.fromMillisecondsSinceEpoch(dayMs),
      rewardedWatchedToday: prefs.getInt(_rewardedWatchedKey) ?? 0,
      lastInterstitialAt: lastInterstitialMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastInterstitialMs),
    );
  }

  Future<void> save(AdLedger ledger) async {
    final prefs = await SharedPreferences.getInstance();

    final day = ledger.day;
    if (day != null) {
      await prefs.setInt(_dayKey, day.millisecondsSinceEpoch);
    }
    await prefs.setInt(_rewardedWatchedKey, ledger.rewardedWatchedToday);

    final last = ledger.lastInterstitialAt;
    if (last != null) {
      await prefs.setInt(_lastInterstitialKey, last.millisecondsSinceEpoch);
    }
  }

  /// The player's stated birth year, or null if they have not said.
  ///
  /// The year alone, never a full date: it is enough to place them either
  /// side of [AdsConstants.consentAge], and asking for more would be
  /// collecting extra personal data to serve slightly better ads.
  Future<int?> loadBirthYear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_birthYearKey);
  }

  Future<void> saveBirthYear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_birthYearKey, year);
  }
}
