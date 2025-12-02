import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:localangel/presentation/widgets/leaderboard/prize_card.dart';

class MonthlyCompetitionSection extends StatelessWidget {
  const MonthlyCompetitionSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM yyyy', 'he').format(now);
    final monthNameShort = DateFormat('MMMM', 'he').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF7C3AED),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'תחרות חודשית - $monthNameShort $now.year',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            monthName,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '3 השומרים המובילים בכל חודש זוכים בפרסים אמיתיים מעסקים מקומיים!',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(height: 16),
        // Prize cards
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              PrizeCard(
                rank: 1,
                prizeTitle: 'שובר מסעדה מובחרת',
                prizeImageUrl: null, // Will use placeholder
                medalColor: Colors.amber,
              ),
              const SizedBox(width: 12),
              PrizeCard(
                rank: 2,
                prizeTitle: 'חבילת יום ספא',
                prizeImageUrl: null,
                medalColor: Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              PrizeCard(
                rank: 3,
                prizeTitle: 'שובר קניות',
                prizeImageUrl: null,
                medalColor: Colors.brown.shade400,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Current leader card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3E8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                'מוביל/ה נוכחי/ת:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 8),
              const Text(
                'orion chassid',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              const Text(
                '20 נקודות',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
