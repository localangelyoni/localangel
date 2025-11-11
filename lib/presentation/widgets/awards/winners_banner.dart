import 'package:flutter/material.dart';

class WinnersBanner extends StatelessWidget {
  const WinnersBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Banner image placeholder
        Container(
          height: 180,
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.grey.shade300,
            image: const DecorationImage(
              image: AssetImage('assets/logo.png'),
              fit: BoxFit.cover,
              onError: null,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        // View all winners button
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/leaderboard');
                },
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('צפה בכל הזוכים'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

