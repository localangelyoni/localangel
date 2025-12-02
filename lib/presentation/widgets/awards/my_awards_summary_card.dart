import 'package:flutter/material.dart';

class MyAwardsSummaryCard extends StatelessWidget {
  const MyAwardsSummaryCard({
    super.key,
    required this.totalPoints,
    required this.nextGoalPoints,
    required this.onViewAllAwards,
  });

  final int totalPoints;
  final int nextGoalPoints;
  final VoidCallback onViewAllAwards;

  @override
  Widget build(BuildContext context) {
    final progress = nextGoalPoints > 0
        ? (totalPoints / nextGoalPoints).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFF7C3AED),
            const Color(0xFF7C3AED).withValues(alpha: 0.8),
          ],
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
                  Icons.emoji_events_outlined,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'סה"כ הנקודות שלי',
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
              '$totalPoints',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            Text(
              'התקדמות ליעד הבא',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$nextGoalPoints נקודות',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            // View all awards button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewAllAwards,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('צפה בכל הפרסים'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF7C3AED),
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
