import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.avatarUrl,
    this.onMenuTap,
    this.onProfileTap,
  });

  final String? avatarUrl;
  final VoidCallback? onMenuTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profile picture
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          ),
          // Logo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.volunteer_activism,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                'Local Angel',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C3AED),
                    ),
              ),
            ],
          ),
          // Menu icon
          IconButton(
            onPressed: onMenuTap ?? () {},
            icon: const Icon(Icons.menu),
            color: Colors.black87,
          ),
        ],
      ),
    );
  }
}

