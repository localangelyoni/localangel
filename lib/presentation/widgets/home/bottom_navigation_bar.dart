import 'package:flutter/material.dart';

enum HomeTab {
  home,
  awards,
  connections,
  notifications,
}

class HomeBottomNavigationBar extends StatelessWidget {
  const HomeBottomNavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    this.onFloatingActionButtonTap,
  });

  final HomeTab currentTab;
  final ValueChanged<HomeTab> onTabChanged;
  final VoidCallback? onFloatingActionButtonTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home,
                label: 'בית',
                isActive: currentTab == HomeTab.home,
                onTap: () => onTabChanged(HomeTab.home),
              ),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                label: 'פרסים',
                isActive: currentTab == HomeTab.awards,
                onTap: () => onTabChanged(HomeTab.awards),
              ),
              const SizedBox(width: 40), // Space for FAB
              _NavItem(
                icon: Icons.people_outline,
                label: 'קשרים',
                isActive: currentTab == HomeTab.connections,
                onTap: () => onTabChanged(HomeTab.connections),
              ),
              _NavItem(
                icon: Icons.notifications_outlined,
                label: 'התראות',
                isActive: currentTab == HomeTab.notifications,
                onTap: () => onTabChanged(HomeTab.notifications),
              ),
            ],
          ),
        ),
        // Floating Action Button
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 28,
          top: -28,
          child: Material(
            elevation: 4,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onFloatingActionButtonTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF7C3AED),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF7C3AED) : Colors.grey;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

