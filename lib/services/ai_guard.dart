import '../utils/input_sanitizer.dart';
import '../utils/output_validator.dart';
import '../utils/pii_detector.dart';
import '../utils/rate_limiter.dart';

/// The kind of AI request being guarded. Determines which rate-limit
/// cooldown applies.
enum AiRequestKind { chat, assessment, quiz }

/// Why an outbound user message was blocked, or null if allowed.
///
/// Deliberately short. There used to be `suspiciousInput` and `offTopicShift`
/// too, both driven by English keyword lists — they refused ordinary learner
/// messages ("let's roleplay a cafe scene", anything written in Japanese) and
/// caught nothing an attacker could not rephrase. Refusing a message is now
/// reserved for the two reasons that are language-neutral and certain: the
/// learner is over the rate limit, or there is nothing to send.
enum AiGuardBlock { rateLimited, emptyInput }

/// Result of guarding an outbound user message.
class AiInputGuardResult {
  const AiInputGuardResult._({
    this.block,
    this.rateLimitMessage = '',
    this.outboundText = '',
    this.displayText = '',
    this.piiRedacted = false,
  });

  /// Null when the message may be sent.
  final AiGuardBlock? block;

  /// User-facing cooldown message, set when [block] is
  /// [AiGuardBlock.rateLimited].
  final String rateLimitMessage;

  /// Sanitized (and PII-redacted) text to send to the model.
  final String outboundText;

  /// What to show and store locally: the learner's own words, with PII
  /// redacted and response markers escaped. Escaping matters because stored
  /// messages are replayed to the model as history when a chat is reopened,
  /// and an unescaped `|||VOCAB|||` in a user turn would be parsed as if the
  /// tutor had written it.
  final String displayText;

  /// True when personal data was detected and redacted.
  final bool piiRedacted;

  bool get allowed => block == null;
}

/// Result of guarding an AI response.
class AiResponseGuardResult {
  const AiResponseGuardResult._({this.text, this.injectionSuspected = false});

  /// Sanitized response text, or null when the response was rejected.
  final String? text;

  /// True when the rejection was due to a suspected prompt injection
  /// (as opposed to a malformed response).
  final bool injectionSuspected;

  bool get valid => text != null;
}

/// Single entry point for the client-side AI security pipeline:
/// rate limiting, marker escaping, PII redaction, and AI response validation.
///
/// The pipeline deliberately does not try to classify intent from the user's
/// wording. That job belongs to the system prompt, which handles it in every
/// language; this layer handles the parts a prompt cannot — cost, structure,
/// personal data, and checking what comes back.
///
/// Every screen that talks to [AiService] must route user text through
/// [checkUserMessage] and model output through [checkAiResponse] instead
/// of calling the individual validators directly.
class AiGuard {
  AiGuard._();

  static int _cooldownSeconds(AiRequestKind kind) {
    switch (kind) {
      case AiRequestKind.chat:
        return 3;
      case AiRequestKind.assessment:
      case AiRequestKind.quiz:
        return 2;
    }
  }

  static bool _canSend(AiRequestKind kind, String source) {
    switch (kind) {
      case AiRequestKind.chat:
        return RateLimiter.canSendMessage(source);
      case AiRequestKind.assessment:
        return RateLimiter.canSendAssessment(source);
      case AiRequestKind.quiz:
        return RateLimiter.canGenerateQuiz(source);
    }
  }

  /// Checks only the rate limit for [kind]/[source] — used for requests
  /// without free-form user text (e.g. quiz generation).
  static AiInputGuardResult checkRequest({
    required AiRequestKind kind,
    required String source,
  }) {
    if (!_canSend(kind, source)) {
      return AiInputGuardResult._(
        block: AiGuardBlock.rateLimited,
        rateLimitMessage:
            RateLimiter.getRateLimitMessage(source, _cooldownSeconds(kind)),
      );
    }
    return const AiInputGuardResult._();
  }

  /// Runs the full inbound pipeline over a free-form user message.
  ///
  /// Does NOT record the request against the rate limiter — call
  /// [recordRequest] once the message is actually sent.
  static AiInputGuardResult checkUserMessage({
    required String rawText,
    required AiRequestKind kind,
    required String source,
  }) {
    if (!_canSend(kind, source)) {
      return AiInputGuardResult._(
        block: AiGuardBlock.rateLimited,
        rateLimitMessage:
            RateLimiter.getRateLimitMessage(source, _cooldownSeconds(kind)),
      );
    }

    // Escapes response markers, strips control characters, caps length, and
    // logs anything injection-shaped for monitoring. It never rewrites what
    // the learner actually said.
    final sanitizedText =
        InputSanitizer.sanitizeUserInput(rawText, source: source);

    if (sanitizedText.isEmpty) {
      return const AiInputGuardResult._(block: AiGuardBlock.emptyInput);
    }

    final piiRedacted = PIIDetector.hasSensitiveData(sanitizedText);
    final displayText = InputSanitizer.escapeSpecialMarkers(rawText);
    return AiInputGuardResult._(
      outboundText: piiRedacted
          ? PIIDetector.redactSensitiveData(sanitizedText)
          : sanitizedText,
      displayText: piiRedacted
          ? PIIDetector.redactSensitiveData(displayText)
          : displayText,
      piiRedacted: piiRedacted,
    );
  }

  /// Records a sent request against the rate limiter.
  static void recordRequest(String source) {
    RateLimiter.recordRequest(source);
  }

  /// Validates and sanitizes an AI response.
  static AiResponseGuardResult checkAiResponse(
    String responseText, {
    required String source,
  }) {
    if (!OutputValidator.isValidResponse(responseText)) {
      OutputValidator.logValidationFailure(
          'Invalid response format ($source)', responseText);
      return const AiResponseGuardResult._();
    }

    if (!OutputValidator.isGenuineResponse(responseText)) {
      OutputValidator.logValidationFailure(
          'Prompt injection detected in response ($source)', responseText);
      return const AiResponseGuardResult._(injectionSuspected: true);
    }

    return AiResponseGuardResult._(
      text: OutputValidator.sanitizeResponse(responseText),
    );
  }
}
