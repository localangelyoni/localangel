import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({super.key, this.chatId});
  final String? chatId;

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  DocumentSnapshot<Map<String, dynamic>>? _chat;
  bool _loading = true;
  String _newMessage = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    // switch to stream: listen for changes
    final id = widget.chatId;
    if (id != null) {
      FirebaseFirestore.instance.collection('chats').doc(id).snapshots().listen((doc) {
        if (mounted) setState(() => _chat = doc);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final id = widget.chatId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('chats').doc(id).get();
      if (mounted) setState(() => _chat = doc);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    final id = _chat?.id;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (id == null || uid == null || _newMessage.trim().isEmpty) return;
    final msg = {
      'sender_id': uid,
      'message': _newMessage.trim(),
      'timestamp': FieldValue.serverTimestamp(),
      'message_type': 'text',
    };
    await FirebaseFirestore.instance.collection('chats').doc(id).update({
      'messages': FieldValue.arrayUnion([msg]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    setState(() => _newMessage = '');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_chat == null || !_chat!.exists) {
      return const Scaffold(body: Center(child: Text('הצ\'אט לא נמצא')));
    }
    final data = _chat!.data()!;
    final messages = (data['messages'] as List?)?.cast<Map>() ?? [];
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('צ\'אט')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                final mine = m['sender_id'] == uid;
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFF7C3AED) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      (m['message'] as String?) ?? '',
                      style: TextStyle(color: mine ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _newMessage = v),
                    controller: TextEditingController(text: _newMessage),
                    decoration: const InputDecoration(hintText: 'כתבו הודעה...'),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _send, child: const Icon(Icons.send, size: 18)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


