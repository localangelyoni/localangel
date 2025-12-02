import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key, this.fullName, this.avatarUrl, this.roleTitle});

  final String? fullName;
  final String? avatarUrl;
  final String? roleTitle;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _isAvailable = true;
  bool _loadingAvailability = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loadingAvailability = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final isAvailable =
          ((data['guardian_preferences'] as Map?)?['is_available'] as bool?) ??
          true;
      if (mounted) {
        setState(() {
          _isAvailable = isAvailable;
          _loadingAvailability = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingAvailability = false);
      }
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isAvailable = value);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'guardian_preferences': {'is_available': value},
      }, SetOptions(merge: true));
    } catch (_) {
      // Revert on error
      if (mounted) {
        setState(() => _isAvailable = !value);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('שגיאה בעדכון הסטטוס')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header with profile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: widget.avatarUrl != null
                        ? NetworkImage(widget.avatarUrl!)
                        : null,
                    child: widget.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.grey, size: 30)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.fullName ?? 'משתמש/ת',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.roleTitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.roleTitle!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home,
                    title: 'דף הבית',
                    onTap: () {
                      Navigator.of(context).pop();
                      // If already on home, do nothing
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'הצ\'אטים שלי',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/my_chats');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    title: 'הקשרים שלי',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/my_chats');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.notifications_outlined,
                    title: 'התראות קהילה',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/community_alerts');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.emoji_events_outlined,
                    title: 'פרסים',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/awards');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.visibility_outlined,
                    title: 'טבלת המובילים',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/leaderboard');
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'הגדרות',
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushNamed('/settings');
                    },
                  ),
                ],
              ),
            ),
            // Guardian status section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'סטטוס שומר/ת',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_loadingAvailability)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isAvailable ? 'זמינ/ה לעזור' : 'לא זמינ/ה',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'מוכנ/ה לעזור לקהילה',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: _toggleAvailability,
                            activeThumbColor: const Color(0xFF7C3AED),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title),
      onTap: onTap,
    );
  }
}
