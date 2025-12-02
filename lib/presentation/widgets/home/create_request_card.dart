import 'package:flutter/material.dart';

class CreateRequestCard extends StatelessWidget {
  const CreateRequestCard({super.key, this.onCreateRequest});

  final VoidCallback? onCreateRequest;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton.icon(
          onPressed: onCreateRequest,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('יצירת בקשה'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: const Color(0xFF7C3AED),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
