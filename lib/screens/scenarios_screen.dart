import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/language_provider.dart';
import '../constants/theme.dart';

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
      backgroundColor: AppTheme.retroSky,
      body: SafeArea(
        child: Column(
          children: [
            // Retro Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.retroUi,
                border: Border.all(color: AppTheme.retroDark, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: AppTheme.retroDark,
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.retroDark, size: 28),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        (translations['scenarios'] ?? 'SCENARIOS').toUpperCase(),
                        style: GoogleFonts.pressStart2p(
                          fontSize: 16,
                          color: AppTheme.retroDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section ("Practice Real Life")
                    Container(
                      padding: const EdgeInsets.all(20),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.retroPrimary,
                        border: Border.all(color: AppTheme.retroDark, width: 4),
                        boxShadow: const [
                          BoxShadow(
                            color: AppTheme.retroDark,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppTheme.retroDark, width: 3),
                            ),
                            child: const Center(
                              child: Icon(Icons.theater_comedy, color: AppTheme.retroDark, size: 28),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            translations['practiceRealLife'] ?? 'Practice Real Life',
                            style: GoogleFonts.pressStart2p(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            translations['chooseSituation'] ?? 'Choose a situation to master your conversation skills',
                            style: GoogleFonts.spaceMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    Text(
                      translations['createYourOwn'] ?? 'Create Your Own',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                             const Shadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
                        ]
                      ),
                    ),
                    const SizedBox(height: 12),

                    // "Create Custom" Card
                    GestureDetector(
                      onTap: () {
                        context.pushNamed(
                          'chat',
                          pathParameters: {'chatId': 'new_custom'},
                          extra: {'isScenario': true}
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.retroLight,
                          border: Border.all(color: AppTheme.retroDark, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: AppTheme.retroDark,
                              offset: Offset(4, 4),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.retroAccent,
                                border: Border.all(color: AppTheme.retroDark, width: 3),
                              ),
                              child: const Center(
                                child: Icon(Icons.add, color: AppTheme.retroDark),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    translations['startCustom'] ?? 'Start Custom',
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 12,
                                      color: AppTheme.retroDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    translations['customPlaceholder'] ?? 'E.g. You are a taxi driver...',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.retroDark.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    
                    Text(
                      'POPULAR',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 14,
                        color: Colors.white,
                        shadows: [
                             const Shadow(color: AppTheme.retroDark, offset: Offset(2, 2)),
                        ]
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Grid Layout
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: scenarios.length,
                      itemBuilder: (context, index) {
                        final scene = scenarios[index];
                        // Assign colors based on index for variety
                        final cardColor = index % 2 == 0 ? Colors.white : AppTheme.retroLight;
                        final iconBgColor = index % 3 == 0 ? AppTheme.retroGrass : (index % 3 == 1 ? AppTheme.retroSkyLight : AppTheme.retroOrange);

                        return GestureDetector(
                          onTap: () {
                            context.pushNamed(
                              'chat',
                              pathParameters: {'chatId': 'new_${scene['id']}'},
                              extra: {'scenario': scene['title'], 'isScenario': true}
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              border: Border.all(color: AppTheme.retroDark, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppTheme.retroDark,
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                )
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: iconBgColor,
                                    border: Border.all(color: AppTheme.retroDark, width: 3),
                                  ),
                                  child: Icon(scene['icon'] as IconData, color: AppTheme.retroDark, size: 24),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (scene['title'] as String).toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.pressStart2p(
                                    fontSize: 10,
                                    color: AppTheme.retroDark,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.retroDark,
                                  ),
                                  child: Text(
                                    (scene['level'] as String).toUpperCase(),
                                    style: GoogleFonts.pressStart2p(
                                      fontSize: 6,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
