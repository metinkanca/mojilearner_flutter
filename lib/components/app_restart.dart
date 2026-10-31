import 'package:flutter/widgets.dart';

/// Throws away everything under it and builds it again.
///
/// Every provider reads storage once, when it is created. After the storage has
/// been wiped (Reset App, Delete Account) the providers still hold the old
/// player, so the only way to show the wiped state without quitting the app is
/// to make new providers. A new key on the subtree does exactly that.
class AppRestart extends StatefulWidget {
  const AppRestart({super.key, required this.child});

  final Widget child;

  /// Rebuilds the app from its first screen with freshly read providers.
  static void restart(BuildContext context) {
    context.findAncestorStateOfType<_AppRestartState>()?._restart();
  }

  @override
  State<AppRestart> createState() => _AppRestartState();
}

class _AppRestartState extends State<AppRestart> {
  Key _key = UniqueKey();

  void _restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}
