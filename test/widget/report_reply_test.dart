import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/character_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mojilearner_flutter/components/message_bubble.dart';
import 'package:mojilearner_flutter/components/report_reply_button.dart';
import 'package:mojilearner_flutter/l10n/app_localizations.dart';

/// Play expects an app that shows AI-written text to let the player flag bad
/// output. The flag hands the report to the player's own email app, so what
/// matters here is that it only appears when there is an address to send to,
/// only under the AI's replies, and sends nothing but what the player can see.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // The bubble draws the pet beside an AI reply, which needs its provider.
  Widget host(Widget child) => ChangeNotifierProvider(
        create: (_) => CharacterProvider(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: Center(child: child)),
        ),
      );

  group('the mail link', () {
    test('quotes the reply and carries nothing else', () {
      final uri = reportReplyUri('help@example.com', 'Bonjour le monde & co');

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'help@example.com');
      final body = Uri.decodeComponent(
        uri.toString().split('body=').last,
      );
      expect(body, contains('Bonjour le monde & co'));
      expect(uri.toString(), isNot(contains('+')),
          reason: 'spaces must be %20 or mail apps show a literal +');
    });

    test('a very long reply is cut so the link stays openable', () {
      final uri = reportReplyUri('help@example.com', 'a' * 5000);
      expect(uri.toString().length, lessThan(2500));
    });
  });

  group('the flag', () {
    testWidgets('is hidden until an address is configured', (tester) async {
      await tester.pumpWidget(host(const ReportReplyButton(reply: 'hi', email: '')));
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
    });

    testWidgets('opens the mail link for the reply it sits under',
        (tester) async {
      Uri? opened;
      await tester.pumpWidget(host(ReportReplyButton(
        reply: 'Das ist falsch',
        email: 'help@example.com',
        launcher: (uri) async {
          opened = uri;
          return true;
        },
      )));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(opened?.path, 'help@example.com');
      expect(Uri.decodeComponent(opened.toString()), contains('Das ist falsch'));
    });

    testWidgets('says so when there is no email app', (tester) async {
      await tester.pumpWidget(host(ReportReplyButton(
        reply: 'x',
        email: 'help@example.com',
        launcher: (_) async => false,
      )));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open your email app."), findsOneWidget);
    });

    testWidgets('a launcher that throws is a message, not a crash',
        (tester) async {
      await tester.pumpWidget(host(ReportReplyButton(
        reply: 'x',
        email: 'help@example.com',
        launcher: (_) async => throw Exception('no handler'),
      )));

      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't open your email app."), findsOneWidget);
    });
  });

  group('in the chat', () {
    testWidgets('appears under the AI\'s replies and not under the player\'s',
        (tester) async {
      await tester.pumpWidget(host(const Column(children: [
        MessageBubble(text: 'bot says', isUser: false, reportEmail: 'a@b.co'),
        MessageBubble(text: 'player says', isUser: true, reportEmail: 'a@b.co'),
      ])));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('is absent from a build with no support address',
        (tester) async {
      await tester.pumpWidget(host(const MessageBubble(
        text: 'bot says',
        isUser: false,
        reportEmail: '',
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.flag_outlined), findsNothing);
    });
  });
}
