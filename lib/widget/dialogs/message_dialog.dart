import 'package:flutter/material.dart';

Future<String?> showMessageDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Send text message'),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Type a message…',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) {
              return;
            }
            Navigator.of(context).pop(text);
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
