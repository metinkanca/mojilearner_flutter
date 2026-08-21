import 'package:flutter_test/flutter_test.dart';
import 'package:mojilearner_flutter/providers/settings_provider.dart';

void main() {
  group('SettingsProvider', () {
    test('should initialize with default settings', () {
      // Act
      final provider = SettingsProvider();
      
      // Assert
      expect(provider.usePixelFont, isTrue);
    });

    test('should toggle pixel font setting', () {
      // Arrange
      final provider = SettingsProvider();
      
      // Act
      provider.togglePixelFont(false);
      
      // Assert
      expect(provider.usePixelFont, isFalse);
    });

    test('should toggle pixel font setting multiple times', () {
      // Arrange
      final provider = SettingsProvider();
      
      // Act & Assert
      provider.togglePixelFont(false);
      expect(provider.usePixelFont, isFalse);
      
      provider.togglePixelFont(true);
      expect(provider.usePixelFont, isTrue);
      
      provider.togglePixelFont(false);
      expect(provider.usePixelFont, isFalse);
    });
  });
}
