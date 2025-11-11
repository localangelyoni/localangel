import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localangel/presentation/pages/leaderboard/leaderboard_cubit.dart';
import 'package:localangel/presentation/widgets/leaderboard/user_progress_card.dart';
import 'package:localangel/presentation/widgets/leaderboard/leaderboard_tabs.dart';
import 'package:localangel/presentation/widgets/leaderboard/monthly_competition_section.dart';
import 'package:localangel/presentation/widgets/leaderboard/leaderboard_list.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardState = ref.watch(leaderboardCubitProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'טבלת מובילי השומרים',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: leaderboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(leaderboardCubitProvider);
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
                        'ראו מי עושה את ההשפעה הגדולה ביותר בקהילה',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // User progress card
                    UserProgressCard(
                      monthlyPoints: leaderboardState.monthlyPoints,
                      totalPoints: leaderboardState.totalPoints,
                      fullName: leaderboardState.fullName ?? 'משתמש/ת',
                      avatarUrl: leaderboardState.avatarUrl,
                    ),
                    const SizedBox(height: 16),
                    // Leaderboard tabs
                    LeaderboardTabs(
                      currentType: leaderboardState.currentLeaderboardType,
                      onTypeChanged: (type) {
                        ref.read(leaderboardCubitProvider.notifier).switchLeaderboardType(type);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Monthly competition section (only for monthly view)
                    if (leaderboardState.currentLeaderboardType == LeaderboardType.monthly)
                      const MonthlyCompetitionSection(),
                    const SizedBox(height: 16),
                    // Leaderboard list
                    LeaderboardList(
                      entries: leaderboardState.leaderboard,
                      currentUserRank: leaderboardState.currentUserRank,
                    ),
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
    );
  }
}

