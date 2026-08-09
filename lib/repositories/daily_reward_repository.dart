import 'package:shared_preferences/shared_preferences.dart';

/// Persists daily-reward bookkeeping: when the user last logged in and when
/// they last claimed a reward. (The streak counter itself is owned by
/// UserProvider, since it is part of the user's visible stats.)
class DailyRewardRepository {
  static const String _lastClaimKey = 'last_reward_claim_date';
  static const String _lastLoginKey = 'last_login_date';

  Future<({DateTime? lastClaimDate, DateTime? lastLoginDate})> load() async {
    final prefs = await SharedPreferences.getInstance();
    final claimStr = prefs.getString(_lastClaimKey);
    final loginStr = prefs.getString(_lastLoginKey);
    return (
      lastClaimDate: claimStr != null ? DateTime.parse(claimStr) : null,
      lastLoginDate: loginStr != null ? DateTime.parse(loginStr) : null,
    );
  }

  Future<void> saveLastLoginDate(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, day.toIso8601String());
  }

  /// Records a claim: both the claim date and login date move to [day].
  Future<void> saveClaim(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastClaimKey, day.toIso8601String());
    await prefs.setString(_lastLoginKey, day.toIso8601String());
  }
}
