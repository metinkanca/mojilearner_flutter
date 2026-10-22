/// The pages that offer a guided tour the first time a player lands on them.
///
/// One id per page rather than one flag for "the tutorial", because the tours
/// are offered where they are useful: a player who never opens the shop should
/// not have spent their one tutorial on it.
enum TutorialId {
  home,
  quiz,
  chat,
  shop,
  profile,
  review;

  /// Where the "already offered" flag lives in SharedPreferences.
  ///
  /// Derived from the enum name, so a new page needs nothing but a new value —
  /// but for the same reason these names are now persisted data, and renaming
  /// one silently re-offers that tour to every existing player.
  String get prefsKey => 'tutorial_seen_$name';
}
