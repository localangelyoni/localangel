import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyCompetitionCard extends StatelessWidget {
  const MonthlyCompetitionCard({
    super.key,
    required this.monthlyPoints,
    required this.onViewLeaderboard,
  });

  final int monthlyPoints;
  final VoidCallback onViewLeaderboard;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'he').format(now);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Colors.orange.shade600, Colors.orange.shade400],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.track_changes_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'נקודות החודש',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$monthlyPoints',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              monthName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'התחרה/י על פרסים חודשיים!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 16),
            // View leaderboard button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewLeaderboard,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('צפה בטבלת מובילים'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
