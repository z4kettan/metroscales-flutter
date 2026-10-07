import 'package:flutter/material.dart';

/// Short confirmation or error messages at the bottom of the screen.
class AppToast {
  static void success(BuildContext context, String message) => _show(context, message, Icons.check_circle_rounded);

  static void error(BuildContext context, Object error) =>
      _show(context, errorText(error), Icons.error_rounded, isError: true);

  static void info(BuildContext context, String message) => _show(context, message, Icons.info_rounded);

  static void _show(BuildContext context, String message, IconData icon, {bool isError = false}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final cs = Theme.of(context).colorScheme;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        backgroundColor: isError ? cs.errorContainer : null,
        content: Row(children: [
          Icon(icon, color: isError ? cs.onErrorContainer : cs.inversePrimary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: isError ? cs.onErrorContainer : cs.onInverseSurface)),
          ),
        ]),
        duration: const Duration(seconds: 3),
      ));
  }

  static String errorText(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
