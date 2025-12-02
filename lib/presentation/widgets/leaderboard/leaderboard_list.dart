import 'package:flutter/material.dart';
import 'package:localangel/presentation/pages/leaderboard/leaderboard_cubit.dart';

class LeaderboardList extends StatelessWidget {
  const LeaderboardList({
    super.key,
    required this.entries,
    required this.currentUserRank,
  });

  final List<LeaderboardEntry> entries;
  final int currentUserRank;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'אין נתונים להצגה',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'דירוג',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'יומר/ת',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  'נקודות',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // List items
        ...entries.map(
          (entry) => _LeaderboardItem(
            entry: entry,
            isCurrentUser: entry.rank == currentUserRank,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  const _LeaderboardItem({required this.entry, required this.isCurrentUser});

  final LeaderboardEntry entry;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFF3E8FF) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF7C3AED), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 60,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? const Color(0xFF7C3AED) : Colors.black87,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF7C3AED),
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.fullName.isNotEmpty
                        ? entry.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              entry.fullName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                color: isCurrentUser ? const Color(0xFF7C3AED) : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points
          SizedBox(
            width: 80,
            child: Text(
              '${entry.points}',
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? const Color(0xFF7C3AED) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
