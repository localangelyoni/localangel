import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:localangel/presentation/pages/home/home_cubit.dart';
import 'package:localangel/presentation/widgets/home/home_header.dart';
import 'package:localangel/presentation/widgets/home/app_drawer.dart';
import 'package:localangel/presentation/widgets/home/welcome_section.dart';
import 'package:localangel/presentation/widgets/home/active_events_card.dart';
import 'package:localangel/presentation/widgets/home/manager_overview_card.dart';
import 'package:localangel/presentation/widgets/home/user_progress_card.dart';
import 'package:localangel/presentation/widgets/home/community_feed_card.dart';
import 'package:localangel/presentation/widgets/home/create_request_card.dart';
import 'package:localangel/presentation/widgets/home/bottom_navigation_bar.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  HomeTab _currentTab = HomeTab.home;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeCubitProvider);
    
    // Determine role title
    String? roleTitle;
    if (homeState.isManager) {
      roleTitle = 'מנהל/ת';
    } else {
      // Check if user is guardian or angel - for now default to guardian
      roleTitle = 'מסייע/ת קהילה';
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        fullName: homeState.fullName,
        avatarUrl: homeState.avatarUrl,
        roleTitle: roleTitle,
      ),
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            HomeHeader(
              avatarUrl: homeState.avatarUrl,
              onProfileTap: () {
                Navigator.of(context).pushNamed('/settings');
              },
              onMenuTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh data
                  ref.invalidate(homeCubitProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Welcome section
                      WelcomeSection(
                        fullName: homeState.fullName ?? 'משתמש/ת',
                        subtitle: homeState.isManager
                            ? 'נהל/י את המלאכים שלך ועזור/י לקהילה'
                            : 'מוכן/ה לעזור לקהילה היום?',
                      ),
                      const SizedBox(height: 16),
                      // Role-based content
                      if (homeState.isManager) ...[
                        // Manager view
                        ActiveEventsCard(
                          activeEventsCount: homeState.activeRequestsCount,
                        ),
                        ManagerOverviewCard(
                          managedUsersCount: homeState.managedUsersCount,
                          activeRequestsCount: homeState.activeRequestsCount,
                          scheduledCount: homeState.scheduledCount,
                          completedTodayCount: homeState.completedTodayCount,
                          onManageUsers: () {
                            // TODO: Navigate to manage users page
                          },
                          onCreateRequest: () {
                            Navigator.of(context).pushNamed('/create_ping');
                          },
                        ),
                      ] else ...[
                        // Regular user view
                        CreateRequestCard(
                          onCreateRequest: () {
                            Navigator.of(context).pushNamed('/create_ping');
                          },
                        ),
                        UserProgressCard(
                          totalPoints: homeState.totalPoints,
                          nextGoalPoints: homeState.nextGoalPoints,
                          onViewAllRewards: () {
                            Navigator.of(context).pushNamed('/awards');
                          },
                        ),
                        CommunityFeedCard(
                          onShowAll: () {
                            Navigator.of(context).pushNamed('/community_alerts');
                          },
                        ),
                      ],
                      const SizedBox(height: 80), // Space for bottom nav
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HomeBottomNavigationBar(
        currentTab: _currentTab,
        onTabChanged: _onTabChanged,
        onFloatingActionButtonTap: () {
          Navigator.of(context).pushNamed('/create_ping');
        },
      ),
    );
  }

  void _onTabChanged(HomeTab tab) {
    setState(() {
      _currentTab = tab;
    });

    // Handle navigation based on tab
    switch (tab) {
      case HomeTab.home:
        // Already on home
        break;
      case HomeTab.awards:
        Navigator.of(context).pushNamed('/awards');
        break;
      case HomeTab.connections:
        Navigator.of(context).pushNamed('/my_chats');
        break;
      case HomeTab.notifications:
        Navigator.of(context).pushNamed('/community_alerts');
        break;
    }
  }
}

