import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mojilearner_flutter/constants/progression.dart';
import 'package:mojilearner_flutter/providers/boss_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserProvider user;

  setUpAll(() {
    registerFallbackValue(const RewardDef(
        level: 1, type: RewardType.coins, value: 1, description: ''));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    user = MockUserProvider();
    when(() => user.grantReward(any())).thenAnswer((_) async {});
  });

  Future<List<RewardDef>> clear(
    BossProgressProvider progress, {
    String boss = 'mossback',
    int step = 0,
    bool finale = false,
  }) =>
      progress.recordClear(
        bossId: boss,
        step: step,
        level: step + 1,
        finale: finale,
        user: user,
      );

  test('a level not yet cleared pays its first clear', () async {
    final progress = BossProgressProvider();
    await progress.load();
    expect(progress.isCleared('mossback', 0), isFalse);

    final paid = await clear(progress);

    expect(paid.map((r) => r.type), [RewardType.coins, RewardType.item]);
    expect(progress.isCleared('mossback', 0), isTrue);
    verify(() => user.grantReward(any())).called(2);
  });

  test('a repeat pays nothing', () async {
    final progress = BossProgressProvider();
    await progress.load();
    await clear(progress);
    clearInteractions(user);

    final again = await clear(progress);

    expect(again, isEmpty);
    verifyNever(() => user.grantReward(any()));
  });

  test('each level pays once, whichever boss it belongs to', () async {
    final progress = BossProgressProvider();
    await progress.load();

    expect(await clear(progress, boss: 'mossback', step: 1), isNotEmpty);
    expect(await clear(progress, boss: 'witch', step: 1), isNotEmpty);
    expect(await clear(progress, boss: 'mossback', step: 2), isNotEmpty);
    expect(await clear(progress, boss: 'mossback', step: 1), isEmpty);
    expect(progress.clearedCount, 3);
  });

  test('a finale pays its 100 coins', () async {
    final progress = BossProgressProvider();
    await progress.load();

    final paid = await clear(progress, step: 4, finale: true);

    expect(paid.firstWhere((r) => r.type == RewardType.coins).value, 100);
  });

  test('two clears racing pay once', () async {
    final progress = BossProgressProvider();
    await progress.load();

    final both = await Future.wait([clear(progress), clear(progress)]);

    expect(both.where((p) => p.isNotEmpty), hasLength(1));
    verify(() => user.grantReward(any())).called(2);
  });

  test('what was cleared survives a restart, and still pays nothing', () async {
    final first = BossProgressProvider();
    await first.load();
    await clear(first, step: 2);
    await first.saved;

    final restarted = BossProgressProvider();
    await restarted.load();

    expect(restarted.isCleared('mossback', 2), isTrue);
    expect(await clear(restarted, step: 2), isEmpty);
  });
}
