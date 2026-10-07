import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// A tonal card with an optional heading, used to group content.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.icon, this.trailing, required this.child, this.padding});

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(20, 18, trailing == null ? 20 : 8, 4),
              child: Row(children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: context.cs.primary),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(title!, style: context.tt.titleMedium)),
                ?trailing,
              ]),
            ),
          Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ],
      ),
    );
  }
}

/// A heading above a group of cards.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 24, 0, 10),
        child: Row(children: [
          Expanded(child: Text(text, style: context.tt.titleMedium)),
          ?trailing,
        ]),
      );
}

/// A label on the left and a value on the right.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.icon});
  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: context.cs.onSurfaceVariant),
              const SizedBox(width: 14),
            ],
            Text(label, style: TextStyle(color: context.cs.onSurfaceVariant)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

/// A rounded square holding an icon, in one of the scheme's container colours.
class IconBox extends StatelessWidget {
  const IconBox(this.icon, {super.key, this.size = 44, this.background, this.foreground});
  final IconData icon;
  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? context.cs.primaryContainer,
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(icon, size: size * 0.5, color: foreground ?? context.cs.onPrimaryContainer),
      );
}
