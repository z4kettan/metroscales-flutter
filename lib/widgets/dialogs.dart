import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Asks the user to confirm. Returns true only when they tap the confirm button.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  bool danger = false,
  IconData? icon,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(icon ?? (danger ? Icons.warning_amber_rounded : Icons.help_outline_rounded)),
      iconColor: danger ? ctx.cs.error : ctx.cs.secondary,
      title: Text(title, textAlign: TextAlign.center),
      content: Text(message, textAlign: TextAlign.center, style: TextStyle(color: ctx.cs.onSurfaceVariant, height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(88, 44),
            backgroundColor: danger ? ctx.cs.error : null,
            foregroundColor: danger ? ctx.cs.onError : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// A dialog with one text field. Returns the trimmed text, or null if cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirmLabel = 'Save',
  IconData? icon,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      void submit() {
        final v = controller.text.trim();
        if (v.isNotEmpty) Navigator.pop(ctx, v);
      }

      return AlertDialog(
        icon: icon == null ? null : Icon(icon),
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: submit, style: FilledButton.styleFrom(minimumSize: const Size(88, 44)), child: Text(confirmLabel)),
        ],
      );
    },
  );
}
