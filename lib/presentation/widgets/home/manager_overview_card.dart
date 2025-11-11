import 'package:flutter/material.dart';

class ManagerOverviewCard extends StatelessWidget {
  const ManagerOverviewCard({
    super.key,
    required this.managedUsersCount,
    required this.activeRequestsCount,
    required this.scheduledCount,
    required this.completedTodayCount,
    this.onManageUsers,
    this.onCreateRequest,
  });

  final int managedUsersCount;
  final int activeRequestsCount;
  final int scheduledCount;
  final int completedTodayCount;
  final VoidCallback? onManageUsers;
  final VoidCallback? onCreateRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.settings,
                  size: 20,
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                const Text(
                  'סקירת מנהל/ת',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Statistics grid
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: managedUsersCount,
                    label: 'משתמשים מנוהלים',
                    color: const Color(0xFFE3F2FD),
                    valueColor: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: activeRequestsCount,
                    label: 'בקשות פעילות',
                    color: const Color(0xFFFFF3E0),
                    valueColor: const Color(0xFFFF9800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    value: scheduledCount,
                    label: 'מתוזמנות',
                    color: const Color(0xFFF3E5F5),
                    valueColor: const Color(0xFF9C27B0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    value: completedTodayCount,
                    label: 'הושלמו היום',
                    color: const Color(0xFFE8F5E9),
                    valueColor: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            OutlinedButton.icon(
              onPressed: onManageUsers,
              icon: const Icon(Icons.people_outline),
              label: const Text('ניהול משתמשים'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCreateRequest,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('יצירת בקשה'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.valueColor,
  });

  final int value;
  final String label;
  final Color color;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

