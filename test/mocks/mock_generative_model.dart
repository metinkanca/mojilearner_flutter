/// Mock classes for Google Generative AI SDK
/// 
/// NOTE: These mocks are currently commented out because GenerativeModel,
/// ChatSession, and GenerateContentResponse are final classes in the
/// google_generative_ai package and cannot be mocked directly with mocktail.
/// 
/// TODO: Implement one of the following solutions:
/// 1. Create wrapper classes around the final classes
/// 2. Use mockito with build_runner to generate mocks
/// 3. Use dependency injection with abstract interfaces
///
/// For now, tests should use actual instances or mock at a higher level
/// (e.g., mock the repository/provider that uses these classes).
library;

// class MockGenerativeModel extends Mock implements GenerativeModel {}

// class MockChatSession extends Mock implements ChatSession {}

// class MockGenerateContentResponse extends Mock implements GenerateContentResponse {}

/// Helper function to create a mock AI response
String createMockAIResponse(String text, {Map<String, dynamic>? mistake}) {
  if (mistake != null) {
    final mistakeJson = '''
{
  "original": "${mistake['original']}",
  "correction": "${mistake['correction']}",
  "explanation": "${mistake['explanation']}",
  "type": "${mistake['type']}"
}
''';
    return '$text\n|||MISTAKE|||\n$mistakeJson';
  }
  return text;
}

/// Sample AI responses for testing
class MockAIResponses {
  static const String friendlyGreeting = "¡Hola! I'm happy to help you practice!";
  
  static const String encouragement = "You're doing great! Keep it up!";
  
  static const String suggestionQuiz = "You seem hungry for knowledge! Let's try a quiz!";
  
  static String withMistake() => createMockAIResponse(
    "That's close, but there's a small error.",
    mistake: {
      'original': 'yo hablo ingles',
      'correction': 'yo hablo inglés',
      'explanation': 'Language names need an accent on the é',
      'type': 'grammar',
    },
  );
}
