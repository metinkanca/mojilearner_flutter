import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../constants/app_runtime_config.dart';

/// Central AI gateway service.
///
/// Prefers backend proxy when `AI_PROXY_BASE_URL` is configured.
/// Falls back to direct model calls only when explicitly allowed.
/// Per-request generation settings.
///
/// These exist because the app makes two very different kinds of request.
/// Conversation benefits from the model reasoning before it answers; emitting
/// a fixed JSON schema does not, and on Gemini 2.5 Flash that reasoning is
/// billed as output tokens — the expensive rate — for no gain.
///
/// [thinkingBudget] is only honoured on the backend path. The bundled
/// `google_generative_ai` SDK has no thinking controls, so a direct-client
/// build cannot disable thinking and will keep paying for it. That is
/// acceptable because the client path is a development fallback
/// (`allowClientAiFallback` is false by default) — but it does mean the
/// saving lands only once the proxy forwards this field.
class AiGenerationConfig {
  const AiGenerationConfig({
    this.maxOutputTokens,
    this.temperature,
    this.thinkingBudget,
  });

  /// Cap on generated tokens.
  ///
  /// Careful: when thinking is enabled, reasoning tokens are drawn from this
  /// same budget, so too low a cap can return an empty response rather than a
  /// short one. Callers must treat empty as "fall back", never as an error.
  final int? maxOutputTokens;

  /// Sampling temperature. Null leaves the model default.
  final double? temperature;

  /// Thinking-token budget. 0 disables thinking. Null leaves the default.
  final int? thinkingBudget;

  /// For requests that must return a fixed JSON shape: no thinking, low
  /// randomness, and enough room for a handful of questions.
  static const AiGenerationConfig structuredJson = AiGenerationConfig(
    maxOutputTokens: 2048,
    temperature: 0.4,
    thinkingBudget: 0,
  );

  /// For a one-word classification (the level assessments). The cap is far
  /// above the handful of tokens actually needed: if a build cannot disable
  /// thinking, reasoning still has room to finish, and the caller falls back
  /// on an empty result either way.
  static const AiGenerationConfig classification = AiGenerationConfig(
    maxOutputTokens: 256,
    temperature: 0,
    thinkingBudget: 0,
  );

  /// For conversation, where the model's defaults are what we want.
  static const AiGenerationConfig conversational = AiGenerationConfig();

  bool get isEmpty =>
      maxOutputTokens == null && temperature == null && thinkingBudget == null;

  Map<String, Object?> toJson() => {
        if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
        if (temperature != null) 'temperature': temperature,
        if (thinkingBudget != null) 'thinkingBudget': thinkingBudget,
      };
}

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  static const String _defaultModel = 'gemini-2.5-flash';

  /// Upper bound for any remote AI call so a hung backend can never
  /// freeze the UI indefinitely.
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const String _unavailableSessionPrefix = 'ai_unavailable_';
  static const String _unavailableUserMessage =
      'Zzz... Moji is dozing while the language link reconnects. Try again soon.';
  final Map<String, ChatSession> _clientSessions = <String, ChatSession>{};
  bool _loggedUnavailableConfig = false;

  String? _getEnvValue(String key) {
    try {
      return dotenv.env[key];
    } catch (_) {
      // dotenv may not be initialized yet
      return null;
    }
  }

  String _newSessionId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    final randomSuffix = (micros % 1000000).toString().padLeft(6, '0');
    return 'ai_${micros}_$randomSuffix';
  }

  String _newUnavailableSessionId() {
    final micros = DateTime.now().microsecondsSinceEpoch;
    return '$_unavailableSessionPrefix$micros';
  }

  String? _getConfigValue(String key) {
    if (key == 'AI_PROXY_BASE_URL') {
      final value = AppRuntimeConfig.aiProxyBaseUrl.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    if (key == 'ALLOW_CLIENT_AI_FALLBACK') {
      return AppRuntimeConfig.allowClientAiFallback ? 'true' : 'false';
    }

    return _getEnvValue(key);
  }

  void _logUnavailableConfigOnce() {
    if (_loggedUnavailableConfig) {
      return;
    }
    _loggedUnavailableConfig = true;
    debugPrint(
      'AI backend is not configured. Update lib/constants/app_runtime_config.dart and set aiProxyBaseUrl.',
    );
  }

  bool _isUnavailableSession(String sessionId) {
    return sessionId.startsWith(_unavailableSessionPrefix);
  }

  bool get isAiAvailable {
    return _backendConfigured || _allowClientFallback;
  }

  String get unavailableUserMessage => _unavailableUserMessage;

  bool isUnavailableResponse(String text) {
    return text.trim() == _unavailableUserMessage;
  }

  bool get _backendConfigured {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    return baseUrl != null && baseUrl.isNotEmpty;
  }

  bool get _allowClientFallback {
    final value = _getConfigValue('ALLOW_CLIENT_AI_FALLBACK')?.toLowerCase().trim();
    return value == '1' || value == 'true' || value == 'yes';
  }

  String? get _clientApiKey {
    final apiKey = _getEnvValue('GEMINI_API_KEY')?.trim();
    if (apiKey == null || apiKey.isEmpty || apiKey == 'offline') {
      return null;
    }
    return apiKey;
  }

  Future<String> generateText({
    required String prompt,
    String model = _defaultModel,
    String source = 'unknown',
    AiGenerationConfig config = AiGenerationConfig.conversational,
  }) async {
    if (_backendConfigured) {
      return _generateViaBackend(
        prompt: prompt,
        model: model,
        source: source,
        config: config,
      );
    }

    if (!_allowClientFallback) {
      _logUnavailableConfigOnce();
      return _unavailableUserMessage;
    }

    return _generateViaClient(prompt: prompt, model: model, config: config);
  }

  Future<String> createSession({
    required String systemInstruction,
    List<AiChatMessage> history = const <AiChatMessage>[],
    String model = _defaultModel,
    String source = 'unknown',
  }) async {
    if (_backendConfigured) {
      return _createSessionViaBackend(
        systemInstruction: systemInstruction,
        history: history,
        model: model,
        source: source,
      );
    }

    if (!_allowClientFallback) {
      _logUnavailableConfigOnce();
      return _newUnavailableSessionId();
    }

    return _createSessionViaClient(
      systemInstruction: systemInstruction,
      history: history,
      model: model,
    );
  }

  Future<String> sendSessionMessage({
    required String sessionId,
    required String message,
    String model = _defaultModel,
    String source = 'unknown',
  }) async {
    if (_backendConfigured) {
      return _sendSessionMessageViaBackend(
        sessionId: sessionId,
        message: message,
        model: model,
        source: source,
      );
    }

    if (_isUnavailableSession(sessionId) && !_allowClientFallback) {
      _logUnavailableConfigOnce();
      return _unavailableUserMessage;
    }

    if (!_allowClientFallback) {
      _logUnavailableConfigOnce();
      return _unavailableUserMessage;
    }

    return _sendSessionMessageViaClient(sessionId: sessionId, message: message);
  }

  void disposeSession(String sessionId) {
    _clientSessions.remove(sessionId);
  }

  Future<String> _generateViaBackend({
    required String prompt,
    required String model,
    required String source,
    AiGenerationConfig config = AiGenerationConfig.conversational,
  }) async {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('AI backend base URL is not configured.');
    }
    final authToken = _getConfigValue('AI_PROXY_TOKEN')?.trim();

    final uri = Uri.parse('$baseUrl/v1/ai/generate');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'model': model,
        'prompt': prompt,
        'source': source,
        // Forwarded for the proxy to map onto the provider's own fields.
        // A proxy that ignores this simply gets the previous behaviour.
        if (!config.isEmpty) 'generationConfig': config.toJson(),
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI backend request failed (${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic> && decoded['text'] is String) {
      final text = (decoded['text'] as String).trim();
      if (text.isEmpty) {
        throw StateError('AI backend returned empty text.');
      }
      return text;
    }

    throw const FormatException('AI backend response missing `text` field.');
  }

  Future<String> _generateViaClient({
    required String prompt,
    required String model,
    AiGenerationConfig config = AiGenerationConfig.conversational,
  }) async {
    final apiKey = _clientApiKey;
    if (apiKey == null) {
      throw StateError('Client fallback enabled but GEMINI_API_KEY is missing.');
    }

    final client = GenerativeModel(
      model: model,
      apiKey: apiKey,
      // No thinking control here: this SDK version does not expose one, so a
      // direct-client build still pays for reasoning tokens. See
      // [AiGenerationConfig].
      generationConfig: config.isEmpty
          ? null
          : GenerationConfig(
              maxOutputTokens: config.maxOutputTokens,
              temperature: config.temperature,
            ),
    );
    final response = await client
        .generateContent([Content.text(prompt)]).timeout(_requestTimeout);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('AI model returned empty response.');
    }
    return text;
  }

  Future<String> _createSessionViaBackend({
    required String systemInstruction,
    required List<AiChatMessage> history,
    required String model,
    required String source,
  }) async {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('AI backend base URL is not configured.');
    }
    final authToken = _getConfigValue('AI_PROXY_TOKEN')?.trim();

    final uri = Uri.parse('$baseUrl/v1/ai/chat/start');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'model': model,
        'source': source,
        'systemInstruction': systemInstruction,
        'history': history.map((m) => m.toJson()).toList(),
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI backend session start failed (${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic> && decoded['sessionId'] is String) {
      final sessionId = (decoded['sessionId'] as String).trim();
      if (sessionId.isEmpty) {
        throw StateError('AI backend returned empty session id.');
      }
      return sessionId;
    }

    throw const FormatException('AI backend response missing `sessionId` field.');
  }

  Future<String> _sendSessionMessageViaBackend({
    required String sessionId,
    required String message,
    required String model,
    required String source,
  }) async {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('AI backend base URL is not configured.');
    }
    final authToken = _getConfigValue('AI_PROXY_TOKEN')?.trim();

    final uri = Uri.parse('$baseUrl/v1/ai/chat/send');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'model': model,
        'source': source,
        'sessionId': sessionId,
        'message': message,
      }),
    ).timeout(_requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI backend chat send failed (${response.statusCode}).');
    }

    final decoded = json.decode(response.body);
    if (decoded is Map<String, dynamic> && decoded['text'] is String) {
      final text = (decoded['text'] as String).trim();
      if (text.isEmpty) {
        throw StateError('AI backend returned empty chat response.');
      }
      return text;
    }

    throw const FormatException('AI backend response missing `text` field.');
  }

  Future<String> _createSessionViaClient({
    required String systemInstruction,
    required List<AiChatMessage> history,
    required String model,
  }) async {
    final apiKey = _clientApiKey;
    if (apiKey == null) {
      throw StateError('Client fallback enabled but GEMINI_API_KEY is missing.');
    }

    final client = GenerativeModel(model: model, apiKey: apiKey);

    final fullHistory = <Content>[
      Content.text(systemInstruction),
      ...history.map((message) {
        final role = message.role == 'user' ? 'user' : 'model';
        return Content(role, [TextPart(message.text)]);
      }),
    ];

    final session = client.startChat(history: fullHistory);
    final sessionId = _newSessionId();
    _clientSessions[sessionId] = session;
    return sessionId;
  }

  Future<String> _sendSessionMessageViaClient({
    required String sessionId,
    required String message,
  }) async {
    final session = _clientSessions[sessionId];
    if (session == null) {
      throw StateError('AI session not found for id: $sessionId');
    }

    final response =
        await session.sendMessage(Content.text(message)).timeout(_requestTimeout);
    final text = response.text?.trim();
    if (text == null || text.isEmpty) {
      throw StateError('AI model returned empty response.');
    }
    return text;
  }
}

class AiChatMessage {
  const AiChatMessage({
    required this.role,
    required this.text,
  });

  final String role;
  final String text;

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
      };
}
