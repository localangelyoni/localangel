import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MySupportRequestsPage extends StatefulWidget {
  const MySupportRequestsPage({super.key});

  @override
  State<MySupportRequestsPage> createState() => _MySupportRequestsPageState();
}

class _MySupportRequestsPageState extends State<MySupportRequestsPage> {
  String _filter = 'all'; // all|open|completed
  String _search = '';
  bool _loading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('pings')
          .where('requester_id', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();
      _items = snap.docs;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((d) {
      final m = d.data();
      final status = (m['status'] as String?) ?? 'open';
      final title = (m['title'] as String?) ?? '';
      final message = (m['message'] as String?) ?? '';
      final matchesStatus = _filter == 'all' || _filter == status;
      final matchesSearch =
          _search.isEmpty ||
          title.contains(_search) ||
          message.contains(_search);
      return matchesStatus && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('היסטוריית תמיכה')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'חפש בקשות...',
                  ),
                  onChanged: (v) => setState(() => _search = v.trim()),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final t in ['all', 'open', 'completed'])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text(
                            t == 'all'
                                ? 'הכל'
                                : t == 'open'
                                ? 'פתוח'
                                : 'הושלם',
                          ),
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
                ? const Center(child: Text('אין בקשות'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final d = filtered[i].data();
                      final status = (d['status'] as String?) ?? 'open';
                      Color color = Colors.amber;
                      if (status == 'completed') color = Colors.green;
                      if (status == 'in_progress') color = Colors.blue;
                      return Card(
                        child: ListTile(
                          title: Text((d['title'] as String?) ?? ''),
                          subtitle: Text((d['message'] as String?) ?? '-'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status == 'open'
                                  ? 'פתוח'
                                  : status == 'completed'
                                  ? 'הושלם'
                                  : status == 'in_progress'
                                  ? 'בתהליך'
                                  : status,
                            ),
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
