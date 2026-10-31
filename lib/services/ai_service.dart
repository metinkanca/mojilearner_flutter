import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../constants/app_runtime_config.dart';
import 'ai_prompt_spec.dart';
import 'fallback_prompts.dart';

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

  /// Set at build time with `--dart-define=AI_MODEL=...`; see
  /// [AppRuntimeConfig.aiModel] for why the default is what it is.
  static const String _defaultModel = AppRuntimeConfig.aiModel;

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

  /// Supplies the caller's Firebase ID token, or null when there is no
  /// account layer running.
  ///
  /// Set once at startup rather than read from Firebase here, so this service
  /// keeps working — and keeps being testable — on a build where cloud sync
  /// could not start. See `main.dart`.
  Future<String?> Function()? idTokenResolver;

  /// Supplies a Firebase App Check token: proof, from Play Integrity or App
  /// Attest, that this is a genuine build of the app on a real device. The
  /// shared `AI_PROXY_TOKEN` and an anonymous account can both be produced by a
  /// script; this cannot. Wired in `main.dart`; null where attestation is not
  /// available, and the proxy decides what an absent one means.
  Future<String?> Function()? appCheckTokenResolver;

  /// The headers every proxy request carries.
  ///
  /// Two tokens, doing different jobs. `Authorization` is the shared
  /// `AI_PROXY_TOKEN`, which says *an install of this app* is calling and is
  /// the same string inside every APK. `X-Id-Token` says *which account*, and
  /// is the only one of the two the server can meter a person against — see
  /// `server/src/quotas.js`.
  ///
  /// A missing or failed ID token is not an error: the server falls back to a
  /// shared bucket, which is tighter rather than looser.
  Future<Map<String, String>> _proxyHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final authToken = _getConfigValue('AI_PROXY_TOKEN')?.trim();
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    try {
      final idToken = await idTokenResolver?.call();
      if (idToken != null && idToken.isNotEmpty) {
        headers['X-Id-Token'] = idToken;
      }
    } catch (_) {
      // A token refresh needs the network, and this request is about to try
      // the network anyway. Let the request go and be metered anonymously
      // rather than failing here.
    }

    try {
      final appCheck = await appCheckTokenResolver?.call();
      if (appCheck != null && appCheck.isNotEmpty) {
        headers['X-Firebase-AppCheck'] = appCheck;
      }
    } catch (_) {
      // As above: no token is a state the proxy already has an answer for.
    }

    return headers;
  }

  /// Tells the proxy about a Google Play subscription so the *server* can give
  /// this account the member allowance. The proxy asks Google whether the
  /// purchase token is a live subscription; nothing the app says about itself is
  /// believed. See `server/src/entitlements.js`.
  ///
  /// Returns true only when the proxy confirmed Plus. Never throws: a proxy
  /// that is unreachable or not configured simply leaves the account on the
  /// free allowance, and the next launch asks again.
  Future<bool> verifyPurchase({
    required String productId,
    required String purchaseToken,
  }) async {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) return false;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/v1/entitlement'),
            headers: await _proxyHeaders(),
            body: json.encode({
              'productId': productId,
              'purchaseToken': purchaseToken,
            }),
          )
          .timeout(_requestTimeout);
      if (response.statusCode != 200) return false;
      final decoded = json.decode(response.body);
      return decoded is Map<String, dynamic> && decoded['premium'] == true;
    } catch (e) {
      debugPrint('⚠️ ENTITLEMENT: could not verify with the proxy - $e');
      return false;
    }
  }

  String? _getConfigValue(String key) {
    if (key == 'AI_PROXY_BASE_URL') {
      final value = AppRuntimeConfig.aiProxyBaseUrl.trim();
      if (value.isNotEmpty) {
        return value;
      }
    }

    if (key == 'AI_PROXY_TOKEN') {
      final value = AppRuntimeConfig.aiProxyToken.trim();
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

  /// Runs a one-shot prompt.
  ///
  /// [spec] names the prompt and carries its data; the wording lives on the
  /// server. See [AiPromptSpec] for why the app no longer sends prompt text.
  Future<String> generateText({
    required AiPromptSpec spec,
    String model = _defaultModel,
    String source = 'unknown',
    AiGenerationConfig config = AiGenerationConfig.conversational,
  }) async {
    if (_backendConfigured) {
      return _generateViaBackend(
        spec: spec,
        model: model,
        source: source,
        config: config,
      );
    }

    if (!_allowClientFallback) {
      _logUnavailableConfigOnce();
      return _unavailableUserMessage;
    }

    final prompt = FallbackPrompts.prompt(spec);
    if (prompt == null) {
      throw ArgumentError('${spec.mode.wireName} is not a generate mode.');
    }
    return _generateViaClient(prompt: prompt, model: model, config: config);
  }

  /// Opens a chat session under the persona [spec] names.
  Future<String> createSession({
    required AiPromptSpec spec,
    List<AiChatMessage> history = const <AiChatMessage>[],
    String model = _defaultModel,
    String source = 'unknown',
  }) async {
    if (_backendConfigured) {
      return _createSessionViaBackend(
        spec: spec,
        history: history,
        model: model,
        source: source,
      );
    }

    if (!_allowClientFallback) {
      _logUnavailableConfigOnce();
      return _newUnavailableSessionId();
    }

    final systemInstruction = FallbackPrompts.systemInstruction(spec);
    if (systemInstruction == null) {
      throw ArgumentError('${spec.mode.wireName} is not a chat mode.');
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
    required AiPromptSpec spec,
    required String model,
    required String source,
    AiGenerationConfig config = AiGenerationConfig.conversational,
  }) async {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('AI backend base URL is not configured.');
    }

    final uri = Uri.parse('$baseUrl/v1/ai/generate');
    final headers = await _proxyHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'model': model,
        'mode': spec.mode.wireName,
        'params': spec.params,
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
    required AiPromptSpec spec,
    required List<AiChatMessage> history,
    required String model,
    required String source,
  }) async {
    final baseUrl = _getConfigValue('AI_PROXY_BASE_URL')?.trim();
    if (baseUrl == null || baseUrl.isEmpty) {
      throw StateError('AI backend base URL is not configured.');
    }

    final uri = Uri.parse('$baseUrl/v1/ai/chat/start');
    final headers = await _proxyHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'model': model,
        'source': source,
        'mode': spec.mode.wireName,
        'params': spec.params,
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

    final uri = Uri.parse('$baseUrl/v1/ai/chat/send');
    final headers = await _proxyHeaders();

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
