import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommunityAlertsPage extends StatefulWidget {
  const CommunityAlertsPage({super.key});

  @override
  State<CommunityAlertsPage> createState() => _CommunityAlertsPageState();
}

class _CommunityAlertsPageState extends State<CommunityAlertsPage> {
  String _filter = 'all'; // all|emergency|urgent|routine
  String _search = '';
  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pings')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .get();
      _items = snap.docs;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _acceptPing(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('pings').doc(doc.id).update({
        'status': 'assigned',
        'guardian_id': uid,
      });
      // update related chat (simple: find by ping_id)
      final chats = await FirebaseFirestore.instance
          .collection('chats')
          .where('ping_id', isEqualTo: doc.id)
          .limit(1)
          .get();
      if (chats.docs.isNotEmpty) {
        final chatRef = chats.docs.first.reference;
        await chatRef.update({
          'participants': FieldValue.arrayUnion([uid]),
          'messages': FieldValue.arrayUnion([
            {
              'sender_id': uid,
              'message': 'קיבלתי את הבקשה ואעזור',
              'timestamp': FieldValue.serverTimestamp(),
              'message_type': 'system',
            }
          ]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (!mounted) return;
        Navigator.of(context).pushNamed('/chat_detail', arguments: chatRef.id);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('שגיאה בקבלת הבקשה')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((d) {
      final m = d.data();
      final type = (m['ping_type'] as String?) ?? 'routine';
      final title = (m['title'] as String?) ?? '';
      final message = (m['message'] as String?) ?? '';
      final matchesType = _filter == 'all' || _filter == type;
      final matchesSearch = _search.isEmpty || title.contains(_search) || message.contains(_search);
      return matchesType && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('התראות קהילה')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'חיפוש התראות...'),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in ['all', 'emergency', 'urgent', 'routine'])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(t == 'all' ? 'הכל' : t == 'emergency' ? 'חירום' : t == 'urgent' ? 'דחוף' : 'שגרה'),
                          selected: _filter == t,
                          onSelected: (_) => setState(() => _filter = t),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('לא נמצאו התראות'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final d = filtered[i].data();
                          final type = (d['ping_type'] as String?) ?? 'routine';
                          Color border = Colors.blue;
                          if (type == 'emergency') border = Colors.red;
                          if (type == 'urgent') border = Colors.orange;
                          return Card(
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: border, width: 1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text((d['title'] as String?) ?? '',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: border.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(type == 'emergency' ? 'חירום' : type == 'urgent' ? 'דחוף' : 'שגרה',
                                            style: TextStyle(color: border)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text((d['message'] as String?) ?? '-', maxLines: 3),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _acceptPing(filtered[i]),
                                          child: const Text('קבל ועזור'),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}


