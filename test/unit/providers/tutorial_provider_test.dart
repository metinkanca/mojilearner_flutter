import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/constants/tutorials.dart';
import 'package:mojilearner_flutter/providers/tutorial_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TutorialProvider', () {
    test('a fresh install has been offered nothing', () async {
      final provider = TutorialProvider();
      await provider.load();

      expect(provider.isLoaded, isTrue);
      for (final id in TutorialId.values) {
        expect(provider.hasSeen(id), isFalse, reason: id.name);
      }
    });

    test('isLoaded is false until load has run', () {
      // The hosts gate on this: acting on hasSeen before the disk read comes
      // back would re-offer a tour the player skipped last week.
      expect(TutorialProvider().isLoaded, isFalse);
    });

    test('marking one seen leaves the others on offer', () async {
      final provider = TutorialProvider();
      await provider.load();

      await provider.markSeen(TutorialId.shop);

      expect(provider.hasSeen(TutorialId.shop), isTrue);
      expect(provider.hasSeen(TutorialId.home), isFalse);
    });

    test('a seen tour survives a restart', () async {
      final first = TutorialProvider();
      await first.load();
      await first.markSeen(TutorialId.home);

      final second = TutorialProvider();
      await second.load();

      expect(second.hasSeen(TutorialId.home), isTrue);
    });

    test('resetAll puts every tour back on offer, on disk too', () async {
      final provider = TutorialProvider();
      await provider.load();
      for (final id in TutorialId.values) {
        await provider.markSeen(id);
      }

      await provider.resetAll();

      final reloaded = TutorialProvider();
      await reloaded.load();
      for (final id in TutorialId.values) {
        expect(provider.hasSeen(id), isFalse, reason: id.name);
        expect(reloaded.hasSeen(id), isFalse, reason: '${id.name} on disk');
      }
    });

    test('marking notifies once, and not again for a repeat', () async {
      final provider = TutorialProvider();
      await provider.load();

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.markSeen(TutorialId.quiz);
      await provider.markSeen(TutorialId.quiz);

      expect(notifications, 1);
    });

    test('the persisted keys are the ones the enum names', () async {
      // These strings are saved data: renaming an enum value silently
      // re-offers that tour to every existing player.
      final provider = TutorialProvider();
      await provider.load();
      await provider.markSeen(TutorialId.review);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('tutorial_seen_review'), isTrue);
    });
  });
}
