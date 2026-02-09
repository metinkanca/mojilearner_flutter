import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch language provider for updates (rebuilds when language changes)
    final langProvider = Provider.of<LanguageProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    // Get translated strings based on native language
    final texts = langProvider.getTranslations();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(texts['profile'] ?? 'Profile', style: const TextStyle(color: AppTheme.text)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.text),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Header
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  userProvider.username,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.text),
                ),
                Text(
                  "Level ${userProvider.stats.level} • ${userProvider.stats.xp} XP",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Language Settings
          Text(texts['header'] ?? 'Language Settings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.text)),
          const SizedBox(height: 16),
          
          _buildLanguageSelector(
            context, 
            label: texts['iSpeak'] ?? 'I Speak', 
            current: langProvider.nativeLanguage,
            options: langProvider.availableLanguages,
            onSelect: (lang) => langProvider.setNativeLanguage(lang),
          ),
          
          const SizedBox(height: 16),
          
          _buildLanguageSelector(
             context, 
             label: texts['imLearning'] ?? "I'm Learning", 
             current: langProvider.targetLanguage ?? langProvider.availableLanguages[1],
             options: langProvider.availableLanguages,
             onSelect: (lang) => langProvider.setTargetLanguage(lang),
          ),
          
          const SizedBox(height: 32),
          
          // Stats Grid
          Row(
            children: [
               Expanded(child: _statCard(texts['streak'] ?? 'Streak', "${userProvider.stats.streak} 🔥", Colors.orange)),
               const SizedBox(width: 16),
               Expanded(child: _statCard(texts['xp'] ?? 'Total XP', "${userProvider.stats.xp} ✨", Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, {required String label, required Language current, required List<Language> options, required Function(Language) onSelect}) {
    // Find the current language in options to ensure dropdown value matches
    final selectedOption = options.firstWhere(
      (lang) => lang.code == current.code,
      orElse: () => options.first,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          DropdownButtonFormField<Language>(
            value: selectedOption,
            decoration: const InputDecoration(
               border: InputBorder.none,
            ),
            items: options.map((lang) {
              return DropdownMenuItem(
                value: lang,
                child: Row(
                  children: [
                     Text(lang.flag, style: const TextStyle(fontSize: 24)),
                     const SizedBox(width: 12),
                     Text(lang.name, style: const TextStyle(fontSize: 16, color: AppTheme.text)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onSelect(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 14)),
        ],
      ),
    );
  }
}
