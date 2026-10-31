import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/components/app_restart.dart';

/// Reset App wipes storage, and every provider reads storage once when it is
/// created. If a restart kept the old objects the player would see their old
/// pet after resetting, so what is pinned here is that state is rebuilt.
class _Counter extends StatefulWidget {
  const _Counter({required this.onInit});
  final VoidCallback onInit;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => AppRestart.restart(context),
        child: const Text('restart'),
      );
}

void main() {
  testWidgets('restarting builds the app state again from nothing',
      (tester) async {
    var created = 0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: AppRestart(child: _Counter(onInit: () => created++)),
      ),
    );
    expect(created, 1);

    await tester.tap(find.text('restart'));
    await tester.pump();

    expect(created, 2, reason: 'a new state object means providers re-read '
        'the storage that was just wiped');
  });
}
