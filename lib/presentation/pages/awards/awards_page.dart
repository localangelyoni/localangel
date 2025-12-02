import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localangel/presentation/pages/awards/awards_cubit.dart';
import 'package:localangel/presentation/widgets/awards/badge_card.dart';
import 'package:localangel/presentation/widgets/awards/my_awards_summary_card.dart';
import 'package:localangel/presentation/widgets/awards/monthly_competition_card.dart';
import 'package:localangel/presentation/widgets/awards/winners_banner.dart';

class AwardsPage extends ConsumerWidget {
  const AwardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final awardsState = ref.watch(awardsCubitProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'הפרסים שלי',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: awardsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(awardsCubitProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Text(
                        'צבור/י נקודות והתחרה/י על פרסים מדהימים!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Winners banner
                    const WinnersBanner(),
                    const SizedBox(height: 16),
                    // My Awards Summary Card (Purple)
                    MyAwardsSummaryCard(
                      totalPoints: awardsState.totalPoints,
                      nextGoalPoints: awardsState.nextGoalPoints,
                      onViewAllAwards: () {
                        // Scroll to badges section or show all badges
                        // For now, just show a message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('כל הפרסים מוצגים למטה'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Monthly Competition Card (Orange)
                    MonthlyCompetitionCard(
                      monthlyPoints: awardsState.monthlyPoints,
                      onViewLeaderboard: () {
                        Navigator.of(context).pushNamed('/leaderboard');
                      },
                    ),
                    const SizedBox(height: 24),
                    // Achievement Badges section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events_outlined,
                                color: Color(0xFF7C3AED),
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'תגי הישג',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBadgesGrid(context, awardsState.earnedBadges),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBadgesGrid(BuildContext context, List<String> earnedBadges) {
    // Define all available badges - updated based on images
    final allBadges = [
      {
        'id': 'first_help',
        'title': 'לב מסייע',
        'description': 'השלמת את בקשת התמיכה הראשונה שלך',
        'icon': Icons.favorite,
        'pointsRequired': 10,
        'color': Colors.pink,
      },
      {
        'id': 'reliable_helper',
        'title': 'שומר/ת אמין/ה',
        'description': 'השלמת 10 בקשות תמיכה',
        'icon': Icons.verified,
        'pointsRequired': 50,
        'color': Colors.amber,
      },
      {
        'id': 'helper_10',
        'title': 'מסייע/ת פעיל/ה',
        'description': 'סיימת 10 בקשות עזרה',
        'icon': Icons.volunteer_activism,
        'pointsRequired': 50,
        'color': Colors.orange,
      },
      {
        'id': 'helper_50',
        'title': 'מסייע/ת מנוסה',
        'description': 'סיימת 50 בקשות עזרה',
        'icon': Icons.stars,
        'pointsRequired': 200,
        'color': Colors.amber,
      },
      {
        'id': 'helper_100',
        'title': 'מסייע/ת מוביל/ה',
        'description': 'סיימת 100 בקשות עזרה',
        'icon': Icons.emoji_events,
        'pointsRequired': 500,
        'color': const Color(0xFF7C3AED),
      },
      {
        'id': 'early_bird',
        'title': 'ציפור מוקדמת',
        'description': 'עזרת בשעות הבוקר המוקדמות',
        'icon': Icons.wb_sunny,
        'pointsRequired': 30,
        'color': Colors.yellow.shade700,
      },
      {
        'id': 'night_owl',
        'title': 'ינשוף לילה',
        'description': 'עזרת בשעות הלילה המאוחרות',
        'icon': Icons.nightlight_round,
        'pointsRequired': 30,
        'color': Colors.indigo,
      },
      {
        'id': 'weekend_warrior',
        'title': 'לוחם/ת סוף שבוע',
        'description': 'עזרת בסופי שבוע',
        'icon': Icons.weekend,
        'pointsRequired': 40,
        'color': Colors.green,
      },
      {
        'id': 'community_champion',
        'title': 'אלוף/ת הקהילה',
        'description': 'הגעת ל-1000 נקודות',
        'icon': Icons.military_tech,
        'pointsRequired': 1000,
        'color': Colors.purple,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: allBadges.length,
      itemBuilder: (context, index) {
        final badge = allBadges[index];
        final isEarned = earnedBadges.contains(badge['id'] as String);
        return BadgeCard(
          title: badge['title'] as String,
          description: badge['description'] as String,
          icon: badge['icon'] as IconData,
          color: badge['color'] as Color,
          isEarned: isEarned,
        );
      },
    );
  }
}
