import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerificationWaitingPage extends StatefulWidget {
  const VerificationWaitingPage({super.key});

  @override
  State<VerificationWaitingPage> createState() => _VerificationWaitingPageState();
}

class _VerificationWaitingPageState extends State<VerificationWaitingPage> {
  String? _managerStatus; // pending | approved | rejected | null
  String? _requestedRole; // manager | null
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      _managerStatus = data['manager_status'] as String?;
      _requestedRole = data['requested_role'] as String?;
      if ((_requestedRole == null) || _managerStatus == 'approved') {
        if (mounted) Navigator.of(context).pop();
        return;
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF9F5FF), Color(0xFFF5EEFF)],
    );

    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: gradient),
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
    }

    final status = _managerStatus ?? 'pending';
    final isPending = status == 'pending';
    final isRejected = status == 'rejected';

    IconData icon;
    Color color;
    String title;
    String description;

    if (isPending) {
      icon = Icons.schedule;
      color = const Color(0xFFF59E0B); // amber
      title = 'בקשת ניהול בבדיקה';
      description = 'הבקשה שלך להפוך למנהל/ת נבדקת על ידי המלאכ/ה המיועד/ת.';
    } else if (isRejected) {
      icon = Icons.cancel_outlined;
      color = const Color(0xFFEF4444); // red
      title = 'בקשת ניהול נדחתה';
      description = 'תוכל/י להמשיך לפעול כשומר/ת. ניתן לנסות שוב בהמשך.';
    } else {
      icon = Icons.verified_outlined;
      color = const Color(0xFF16A34A); // green
      title = 'בקשת ניהול אושרה';
      description = 'ברוך/ה הבא/ה! יש לך כעת יכולות מנהל/ת.';
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 2,
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('סטטוס אימות', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 16),
                      Container(
                        height: 96,
                        width: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(icon, color: color, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description, style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),
                      const Text('הסטטוס הנוכחי שלך', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('תפקיד: '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(isPending
                                ? 'מנהל/ת ממתין/ה'
                                : isRejected
                                    ? 'שומר/ת'
                                    : 'מנהל/ת'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(isPending ? Icons.shield_outlined : Icons.check_circle_outline, color: Colors.black87),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(isPending ? 'מה קורה עכשיו?' : 'ברוך הבא, מנהל/ת!',
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(isPending
                                    ? 'המלאכ/ה המיועד/ת שלך יאשר/תאשר את הבקשה. במידת הצורך נפנה אליך.'
                                    : 'כעת תוכל/י ליצור בקשות עבור מלאכים ולנהל חיבורים.'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/dashboard');
                        },
                        child: const Text('המשך ללוח המחוונים'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




