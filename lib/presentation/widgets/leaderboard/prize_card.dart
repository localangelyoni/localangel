import 'package:flutter/material.dart';

class PrizeCard extends StatelessWidget {
  const PrizeCard({
    super.key,
    required this.rank,
    required this.prizeTitle,
    this.prizeImageUrl,
    required this.medalColor,
  });

  final int rank;
  final String prizeTitle;
  final String? prizeImageUrl;
  final Color medalColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          // Medal
          Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.emoji_events, size: 64, color: medalColor),
              Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Prize title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              prizeTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          // Prize image placeholder
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade200,
              image: prizeImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(prizeImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: prizeImageUrl == null
                ? Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  )
                : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
