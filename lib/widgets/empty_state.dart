import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.error = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: error ? cs.errorContainer : cs.secondaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 40, color: error ? cs.onErrorContainer : cs.onSecondaryContainer),
            ),
            const SizedBox(height: 20),
            Text(title, style: context.tt.titleLarge, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: context.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
