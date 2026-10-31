import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The text theme asks google_fonts for Inter. If the files are not bundled the
/// package fetches them from the network on first use, which is a launch cost
/// and a flash of the wrong face. With fetching switched off, the only way
/// these loads can succeed is by finding the font in the app's own assets.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => GoogleFonts.config.allowRuntimeFetching = true);

  for (final weight in [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
  ]) {
    test('Inter $weight loads from the bundle, not the network', () async {
      final style = GoogleFonts.inter(fontWeight: weight);
      await expectLater(GoogleFonts.pendingFonts([style]), completes);
    });
  }
}
