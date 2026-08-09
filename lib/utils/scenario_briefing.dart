/// Turns a scenario and its remaining objectives into a prompt fragment.
///
/// Pure string building over already-resolved labels, so the wording can be
/// tested without a localization context — the same split as [SrsBriefing].
library;

/// One objective as the prompt sees it: a stable id, a resolved label, and
/// whether the learner has already cleared it this run.
class BriefedObjective {
  const BriefedObjective({
    required this.id,
    required this.label,
    required this.isBonus,
    required this.isCleared,
  });

  final String id;
  final String label;
  final bool isBonus;
  final bool isCleared;
}

class ScenarioBriefing {
  ScenarioBriefing._();

  /// Builds the roleplay brief: the scene, the goals still outstanding, and
  /// the reporting contract.
  ///
  /// The tutor is told to steer toward objectives but never to narrate them.
  /// A barista who reads out your remaining tasks stops being a barista, and
  /// the checklist in the UI already tells the learner where they stand.
  static String build({
    required String title,
    required List<BriefedObjective> objectives,
  }) {
    final remaining = objectives.where((o) => !o.isCleared).toList();
    final cleared = objectives.where((o) => o.isCleared).toList();

    final buffer = StringBuffer()
      ..writeln()
      ..writeln('SCENARIO: "$title".')
      ..writeln('You must stay strictly within this scenario roleplay.')
      ..writeln('Speak only in the target language (in the TEXT section).')
      ..writeln('Keep responses natural and concise. Stay in character.')
      ..writeln()
      ..writeln('OBJECTIVES:')
      ..writeln(
          'The learner is trying to accomplish the goals below. Steer the '
          'conversation so they get natural openings to attempt them. Never '
          'list the objectives, never tell the learner what is left, and '
          'never mention that anything is being tracked.');

    if (remaining.isEmpty) {
      buffer.writeln(
          '\nAll goals are done. Bring the scene to a natural close.');
    } else {
      buffer.writeln('\nStill outstanding:');
      for (final objective in remaining) {
        final suffix = objective.isBonus ? ' [optional]' : '';
        buffer.writeln('- ${objective.id}: ${objective.label}$suffix');
      }
    }

    if (cleared.isNotEmpty) {
      buffer.writeln(
          '\nAlready done (do not report these again): '
          '${cleared.map((o) => o.id).join(', ')}');
    }

    buffer
      ..writeln()
      ..writeln('OBJECTIVE REPORTING:')
      ..writeln(
          'When the learner\'s message genuinely accomplishes one or more '
          'outstanding objectives, append this HIDDEN block after the VOCAB '
          'block:')
      ..writeln('|||OBJECTIVE|||')
      ..writeln('["objective_id"]')
      ..writeln(
          'Use only the exact ids listed above. Report an objective only when '
          'the learner did it themselves, in the target language — not when '
          'you merely mentioned it, and not when they asked you to do it for '
          'them. If nothing was accomplished, omit the block entirely.');

    return buffer.toString();
  }
}
