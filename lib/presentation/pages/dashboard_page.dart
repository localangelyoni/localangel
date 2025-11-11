import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() => _fullName = (doc.data() ?? {})['full_name'] as String?);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _fullName == null ? 'משתמש/ת' : _fullName!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('בית'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('ברוך שובך, $greeting', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('מוכן/ה לעזור לקהילה היום?', style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('אירועים פעילים', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('אין אירועים פעילים כרגע', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.of(context).pushNamed('/create_ping'),
            child: const Text('יצירת בקשה'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pushNamed('/community_alerts'),
            child: const Text('התראות קהילה'),
          ),
        ],
      ),
    );
  }
}


