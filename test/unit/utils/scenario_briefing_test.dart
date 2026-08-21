import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/utils/scenario_briefing.dart';

BriefedObjective objective(
  String id,
  String label, {
  bool isBonus = false,
  bool isCleared = false,
}) {
  return BriefedObjective(
    id: id,
    label: label,
    isBonus: isBonus,
    isCleared: isCleared,
  );
}

void main() {
  group('ScenarioBriefing.build', () {
    test('names the scene and holds the roleplay frame', () {
      final brief = ScenarioBriefing.build(
        title: 'Ordering Coffee',
        objectives: [objective('order', 'Order a drink')],
      );

      expect(brief, contains('SCENARIO: "Ordering Coffee"'));
      expect(brief, contains('stay strictly within this scenario roleplay'));
      expect(brief, contains('Stay in character'));
    });

    test('lists outstanding objectives with their ids', () {
      final brief = ScenarioBriefing.build(
        title: 'Ordering Coffee',
        objectives: [
          objective('order', 'Order a drink'),
          objective('price', 'Ask what it costs'),
        ],
      );

      expect(brief, contains('- order: Order a drink'));
      expect(brief, contains('- price: Ask what it costs'));
    });

    test('marks bonus objectives as optional', () {
      final brief = ScenarioBriefing.build(
        title: 'Ordering Coffee',
        objectives: [
          objective('order', 'Order a drink'),
          objective('small_talk', 'Make small talk', isBonus: true),
        ],
      );

      expect(brief, contains('- small_talk: Make small talk [optional]'));
      expect(brief, contains('- order: Order a drink\n'));
      expect(brief, isNot(contains('- order: Order a drink [optional]')));
    });

    test('omits cleared objectives from the outstanding list', () {
      final brief = ScenarioBriefing.build(
        title: 'Ordering Coffee',
        objectives: [
          objective('order', 'Order a drink', isCleared: true),
          objective('price', 'Ask what it costs'),
        ],
      );

      expect(brief, isNot(contains('- order: Order a drink')));
      expect(brief, contains('- price: Ask what it costs'));
      expect(brief, contains('do not report these again'));
      expect(brief, contains('order'));
    });

    test('tells the tutor to close the scene when everything is done', () {
      final brief = ScenarioBriefing.build(
        title: 'Ordering Coffee',
        objectives: [
          objective('order', 'Order a drink', isCleared: true),
          objective('price', 'Ask what it costs', isCleared: true),
        ],
      );

      expect(brief, contains('All goals are done'));
      expect(brief, contains('natural close'));
      expect(brief, isNot(contains('Still outstanding')));
    });
  });

  group('ScenarioBriefing.build - behavioural rules', () {
    late String brief;

    setUp(() {
      brief = ScenarioBriefing.build(
        title: 'Ordering Coffee',
        objectives: [objective('order', 'Order a drink')],
      );
    });

    test('forbids narrating the objectives to the learner', () {
      expect(brief, contains('Never list the objectives'));
      expect(brief, contains('never tell the learner what is left'));
      expect(brief, contains('never mention that anything is being tracked'));
    });

    test('specifies the reporting block and its position', () {
      expect(brief, contains('|||OBJECTIVE|||'));
      expect(brief, contains('after the VOCAB'));
      expect(brief, contains('Use only the exact ids listed above'));
    });

    test('requires the learner to have done it themselves', () {
      expect(brief, contains('the learner did it themselves'));
      expect(brief, contains('not when you merely mentioned it'));
      expect(brief, contains('omit the block entirely'));
    });
  });
}
