import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/language_provider.dart';

class ScenariosScreen extends StatelessWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.getTranslations();

    final scenarios = [
      {'id': 'coffee', 'icon': LucideIcons.coffee, 'title': translations['orderingCoffee'], 'level': 'Beginner'},
      {'id': 'job_interview', 'icon': LucideIcons.briefcase, 'title': translations['jobInterview'], 'level': 'Advanced'},
      {'id': 'directions', 'icon': LucideIcons.map, 'title': translations['askingDirections'], 'level': 'Beginner'},
      {'id': 'doctor', 'icon': LucideIcons.stethoscope, 'title': translations['atTheDoctor'], 'level': 'Intermediate'},
      {'id': 'shopping', 'icon': LucideIcons.store, 'title': translations['shopping'], 'level': 'Beginner'},
      {'id': 'restaurant', 'icon': LucideIcons.utensils, 'title': translations['restaurant'], 'level': 'Intermediate'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          translations['scenarios'] ?? 'Roleplay Scenarios',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.theater_comedy, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    translations['practiceRealLife'] ?? 'Practice Real Life',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    translations['chooseSituation'] ?? 'Choose a situation to master your conversation skills',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              translations['createYourOwn'] ?? 'Create Your Own',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                // Navigate to chat with custom scenario
                 context.pushNamed(
                  'chat',
                  pathParameters: {'chatId': 'new_custom'},
                   extra: {'isScenario': true}
                  );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                     Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Color(0xFF2563EB)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translations['startCustom'] ?? 'Start Custom Scenario',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                           translations['customPlaceholder'] ?? 'E.g. You are a taxi driver...',
                           style: GoogleFonts.poppins(
                             fontSize: 12,
                             color: const Color(0xFF6B7280),
                           ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
             const SizedBox(height: 24),
            Text(
              'Popular Scenarios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
             const SizedBox(height: 12),
             GridView.builder(
               physics: const NeverScrollableScrollPhysics(),
               shrinkWrap: true,
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 2,
                 crossAxisSpacing: 16,
                 mainAxisSpacing: 16,
                 childAspectRatio: 0.9,
               ),
               itemCount: scenarios.length,
               itemBuilder: (context, index) {
                 final scene = scenarios[index];
                 return GestureDetector(
                   onTap: () {
                    context.pushNamed(
                      'chat',
                      pathParameters: {'chatId': 'new_${scene['id']}'},
                      extra: {'scenario': scene['title'], 'isScenario': true}
                    );
                   },
                   child: Container(
                     decoration: BoxDecoration(
                       color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                     ),
                     child: Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(scene['icon'] as IconData, size: 40, color: const Color(0xFF2563EB)),
                           const SizedBox(height: 12),
                           Text(
                             scene['title'] as String,
                             textAlign: TextAlign.center,
                             style: GoogleFonts.poppins(
                               fontWeight: FontWeight.w600,
                               fontSize: 14,
                               color: const Color(0xFF1F2937),
                             ),
                           ),
                           const SizedBox(height: 8),
                            Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              scene['level'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                         ],
                       ),
                     ),
                   ),
                 );
               },
             ),
          ],
        ),
      ),
    );
  }
}
