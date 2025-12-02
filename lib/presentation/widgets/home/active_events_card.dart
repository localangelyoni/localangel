import 'package:flutter/material.dart';

class ActiveEventsCard extends StatelessWidget {
  const ActiveEventsCard({super.key, this.activeEventsCount = 0});

  final int activeEventsCount;

  @override
  Widget build(BuildContext context) {
    final hasEvents = activeEventsCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.black87),
                const SizedBox(width: 8),
                const Text(
                  'אירועים פעילים',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!hasEvents) ...[
              Center(
                child: Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'אין אירועים פעילים',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'אשר/י בקשות קהילתיות כדי לראות אירועים כאן',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              // TODO: Show active events list when implemented
              Text(
                '$activeEventsCount אירועים פעילים',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
