import '../utils/input_sanitizer.dart';
import '../utils/output_validator.dart';
import '../utils/pii_detector.dart';
import '../utils/rate_limiter.dart';
import '../utils/semantic_validator.dart';

/// The kind of AI request being guarded. Determines which rate-limit
/// cooldown applies.
enum AiRequestKind { chat, assessment, quiz }

/// Why an outbound user message was blocked, or null if allowed.
enum AiGuardBlock { rateLimited, suspiciousInput, emptyInput, offTopicShift }

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

  /// Original text with PII redacted — what should be shown/stored locally.
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
/// rate limiting, input sanitization, semantic-shift detection,
/// PII redaction, and AI response validation.
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
  /// [recentUserMessages] is the user's prior messages in this
  /// conversation, used for semantic-shift detection.
  ///
  /// Does NOT record the request against the rate limiter — call
  /// [recordRequest] once the message is actually sent.
  static AiInputGuardResult checkUserMessage({
    required String rawText,
    required AiRequestKind kind,
    required String source,
    List<String> recentUserMessages = const [],
  }) {
    if (!_canSend(kind, source)) {
      return AiInputGuardResult._(
        block: AiGuardBlock.rateLimited,
        rateLimitMessage:
            RateLimiter.getRateLimitMessage(source, _cooldownSeconds(kind)),
      );
    }

    final sanitizedText = InputSanitizer.sanitizeUserInput(rawText);

    if (InputSanitizer.isSuspicious(rawText)) {
      InputSanitizer.logSuspiciousInput(rawText, source);
      return const AiInputGuardResult._(block: AiGuardBlock.suspiciousInput);
    }

    if (sanitizedText.isEmpty) {
      return const AiInputGuardResult._(block: AiGuardBlock.emptyInput);
    }

    if (SemanticValidator.hasAnomalousShift(
      recentUserMessages: recentUserMessages,
      newInput: sanitizedText,
    )) {
      InputSanitizer.logSuspiciousInput(rawText, '${source}_semantic');
      return const AiInputGuardResult._(block: AiGuardBlock.offTopicShift);
    }

    final piiRedacted = PIIDetector.hasSensitiveData(sanitizedText);
    return AiInputGuardResult._(
      outboundText: piiRedacted
          ? PIIDetector.redactSensitiveData(sanitizedText)
          : sanitizedText,
      displayText:
          piiRedacted ? PIIDetector.redactSensitiveData(rawText) : rawText,
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
