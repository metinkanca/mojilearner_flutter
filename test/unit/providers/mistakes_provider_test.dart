import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/mistakes_provider.dart';

void main() {
  group('MistakesProvider', () {
    test('should start with empty mistakes list', () {
      // Act
      final provider = MistakesProvider();
      
      // Assert
      expect(provider.mistakes, isEmpty);
    });

    test('should add mistake to list', () {
      // Arrange
      final provider = MistakesProvider();
      
      // Act
      provider.addMistake(
        'Yo como manzana',
        'Yo como una manzana',
        'Missing article "una"',
        'article',
      );
      
      // Assert
      expect(provider.mistakes.length, equals(1));
      expect(provider.mistakes[0].original, equals('Yo como manzana'));
      expect(provider.mistakes[0].correction, equals('Yo como una manzana'));
      expect(provider.mistakes[0].explanation, equals('Missing article "una"'));
      expect(provider.mistakes[0].type, equals('article'));
    });

    test('should clear specific mistake by id', () async {
      // Arrange
      final provider = MistakesProvider();
      provider.addMistake('Wrong 1', 'Correct 1', 'Explanation 1', 'type1');
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure different IDs
      provider.addMistake('Wrong 2', 'Correct 2', 'Explanation 2', 'type2');
      final idToRemove = provider.mistakes[0].id;
      
      // Act
      provider.clearMistake(idToRemove);
      
      // Assert
      expect(provider.mistakes.length, equals(1));
      expect(provider.mistakes[0].original, equals('Wrong 2'));
    });

    test('should clear all mistakes', () {
      // Arrange
      final provider = MistakesProvider();
      provider.addMistake('Wrong 1', 'Correct 1', 'Explanation 1', 'type1');
      provider.addMistake('Wrong 2', 'Correct 2', 'Explanation 2', 'type2');
      provider.addMistake('Wrong 3', 'Correct 3', 'Explanation 3', 'type3');
      
      // Act
      provider.clearAll();
      
      // Assert
      expect(provider.mistakes, isEmpty);
    });
  });
}
