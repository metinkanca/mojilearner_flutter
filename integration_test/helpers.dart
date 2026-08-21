import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/screens/home_screen.dart';
import 'package:provider/provider.dart';

/// Reads a provider off the live home screen.
///
/// These flows are a long chain of `await`s, so a `BuildContext` held in a
/// local reads to the analyzer as a context used across an async gap —
/// `use_build_context_synchronously`, fourteen times over. In a
/// tester-driven test the tree is alive by construction, but the lint cannot
/// see that. Acquiring the element and reading through it in one expression
/// says the same thing in a way the analyzer can check, and spares every call
/// site the ceremony.
T readProvider<T>(WidgetTester tester) => Provider.of<T>(
      tester.element(find.byType(HomeScreen)),
      listen: false,
    );
