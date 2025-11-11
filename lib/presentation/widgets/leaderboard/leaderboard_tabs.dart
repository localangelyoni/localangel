import 'package:flutter/material.dart';
import 'package:localangel/presentation/pages/leaderboard/leaderboard_cubit.dart';

class LeaderboardTabs extends StatelessWidget {
  const LeaderboardTabs({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  final LeaderboardType currentType;
  final ValueChanged<LeaderboardType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'טבלת מובילים חודשית',
              isSelected: currentType == LeaderboardType.monthly,
              onTap: () => onTypeChanged(LeaderboardType.monthly),
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'טבלת מובילים בכל הזמנים',
              isSelected: currentType == LeaderboardType.allTime,
              onTap: () => onTypeChanged(LeaderboardType.allTime),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(
                  right: BorderSide(color: Colors.grey.shade300, width: 1),
                )
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

