import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A full-width primary button that shows a spinner while [busy].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          child: busy
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3, color: context.cs.onSurface.withValues(alpha: 0.5)),
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                  Text(label),
                ]),
        ),
      );
}

/// Actions pinned to the bottom of a form screen.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: context.cs.surfaceContainer,
        child: SafeArea(
          top: false,
          child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), child: child),
        ),
      );
}
