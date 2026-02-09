import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mojilearner_flutter/main.dart';

void main() {
  testWidgets('Widget test example', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our app displays a specific widget.
    expect(find.text('Welcome to MojiLearner'), findsOneWidget);
  });
}