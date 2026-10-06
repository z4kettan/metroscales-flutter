import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Short confirmation or error messages at the bottom of the screen.
class AppToast {
  static void success(BuildContext context, String message) =>
      _show(context, message, Icons.check_circle_rounded, AppColors.success);

  static void error(BuildContext context, Object error) =>
      _show(context, errorText(error), Icons.error_rounded, const Color(0xFFF97066));

  static void info(BuildContext context, String message) =>
      _show(context, message, Icons.info_rounded, const Color(0xFF84CAFF));

  static void _show(BuildContext context, String message, IconData icon, Color iconColor) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ]),
        duration: const Duration(seconds: 3),
      ));
  }

  static String errorText(Object error) {
    final text = error.toString();
    return text.startsWith('Exception: ') ? text.substring(11) : text;
  }
}
