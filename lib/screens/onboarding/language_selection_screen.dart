import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../constants/theme.dart';
import '../../providers/language_provider.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Select Language', style: TextStyle(color: AppTheme.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: languageProvider.availableLanguages.length,
        itemBuilder: (context, index) {
          final lang = languageProvider.availableLanguages[index];
          final isSelected = languageProvider.targetLanguage?.code == lang.code;
          
          return Card(
            color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.card,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isSelected ? const BorderSide(color: AppTheme.primary, width: 2) : BorderSide.none,
            ),
            child: ListTile(
              leading: Text(lang.flag, style: const TextStyle(fontSize: 32)),
              title: Text(lang.name, style: const TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold)),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : null,
              onTap: () {
                context.read<LanguageProvider>().setTargetLanguage(lang);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: languageProvider.hasSelectedLanguages 
              ? () => context.push('/calibration') 
              : null,
          child: const Text('Continue', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}
