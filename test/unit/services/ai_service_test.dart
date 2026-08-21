import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mojilearner_flutter/services/ai_service.dart';

void main() {
  group('AiService - unconfigured (AI unavailable)', () {
    setUp(() {
      // No proxy URL, no client fallback: the service must degrade politely.
      dotenv.testLoad(fileInput: '');
    });

    test('reports AI as unavailable', () {
      expect(AiService.instance.isAiAvailable, isFalse);
    });

    test('generateText returns the unavailable sentinel message', () async {
      final text = await AiService.instance.generateText(
        prompt: 'hello',
        source: 'test',
      );
      expect(AiService.instance.isUnavailableResponse(text), isTrue);
    });

    test('createSession hands out an unavailable session whose messages '
        'return the sentinel', () async {
      final sessionId = await AiService.instance.createSession(
        systemInstruction: 'be nice',
        source: 'test',
      );
      final reply = await AiService.instance.sendSessionMessage(
        sessionId: sessionId,
        message: 'hi',
        source: 'test',
      );
      expect(AiService.instance.isUnavailableResponse(reply), isTrue);
    });

    test('isUnavailableResponse is false for ordinary text', () {
      expect(AiService.instance.isUnavailableResponse('Bonjour!'), isFalse);
    });
  });

  group('AiService - backend proxy', () {
    setUp(() {
      dotenv.testLoad(fileInput: '''
AI_PROXY_BASE_URL=https://backend.test
AI_PROXY_TOKEN=secret-token
''');
    });

    tearDown(() {
      dotenv.testLoad(fileInput: '');
    });

    test('is available once a proxy URL is configured', () {
      expect(AiService.instance.isAiAvailable, isTrue);
    });

    test('generateText posts prompt to /v1/ai/generate with auth header',
        () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(json.encode({'text': 'Hola mundo'}), 200);
      });

      final text = await http.runWithClient(
        () => AiService.instance.generateText(
          prompt: 'say hi in Spanish',
          source: 'test',
        ),
        () => client,
      );

      expect(text, equals('Hola mundo'));
      expect(captured.url.toString(),
          equals('https://backend.test/v1/ai/generate'));
      expect(captured.headers['Authorization'], equals('Bearer secret-token'));
      final body = json.decode(captured.body) as Map<String, dynamic>;
      expect(body['prompt'], equals('say hi in Spanish'));
      expect(body['source'], equals('test'));
      expect(body['model'], isNotEmpty);
    });

    test('generateText throws StateError on non-2xx status', () async {
      final client = MockClient((_) async => http.Response('nope', 500));
      expect(
        () => http.runWithClient(
          () => AiService.instance.generateText(prompt: 'x', source: 'test'),
          () => client,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('generateText throws FormatException when text field is missing',
        () async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'wrong': 'shape'}), 200));
      expect(
        () => http.runWithClient(
          () => AiService.instance.generateText(prompt: 'x', source: 'test'),
          () => client,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('generateText throws StateError on empty text', () async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'text': '   '}), 200));
      expect(
        () => http.runWithClient(
          () => AiService.instance.generateText(prompt: 'x', source: 'test'),
          () => client,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createSession + sendSessionMessage round-trip through the backend',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/v1/ai/chat/start') {
          return http.Response(json.encode({'sessionId': 'session-42'}), 200);
        }
        if (request.url.path == '/v1/ai/chat/send') {
          return http.Response(json.encode({'text': 'Ciao!'}), 200);
        }
        return http.Response('not found', 404);
      });

      final reply = await http.runWithClient(() async {
        final sessionId = await AiService.instance.createSession(
          systemInstruction: 'you are a tutor',
          history: const [AiChatMessage(role: 'user', text: 'hi')],
          source: 'test',
        );
        expect(sessionId, equals('session-42'));
        return AiService.instance.sendSessionMessage(
          sessionId: sessionId,
          message: 'hello there',
          source: 'test',
        );
      }, () => client);

      expect(reply, equals('Ciao!'));
      expect(requests, hasLength(2));

      final startBody = json.decode(requests[0].body) as Map<String, dynamic>;
      expect(startBody['systemInstruction'], equals('you are a tutor'));
      expect(startBody['history'], hasLength(1));

      final sendBody = json.decode(requests[1].body) as Map<String, dynamic>;
      expect(sendBody['sessionId'], equals('session-42'));
      expect(sendBody['message'], equals('hello there'));
    });

    test('createSession throws StateError on empty session id', () async {
      final client = MockClient(
          (_) async => http.Response(json.encode({'sessionId': ''}), 200));
      expect(
        () => http.runWithClient(
          () => AiService.instance
              .createSession(systemInstruction: 'x', source: 'test'),
          () => client,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
