import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum Tone { success, warning, danger, neutral, primary }

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = Tone.neutral, this.dot = false});

  final String label;
  final Tone tone;
  final bool dot;

  factory StatusPill.online(bool online) =>
      online ? const StatusPill('Online', tone: Tone.success, dot: true) : const StatusPill('Offline', dot: true);

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final s = context.status;
    final (bg, fg, dotColor) = switch (tone) {
      Tone.success => (s.successContainer, s.onSuccessContainer, s.success),
      Tone.warning => (s.warningContainer, s.onWarningContainer, s.warning),
      Tone.danger => (cs.errorContainer, cs.onErrorContainer, cs.error),
      Tone.primary => (cs.primaryContainer, cs.onPrimaryContainer, cs.primary),
      Tone.neutral => (cs.surfaceContainerHighest, cs.onSurfaceVariant, cs.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 6),
        ],
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg)),
      ]),
    );
  }
}

/// The item's PLU in a rounded tonal square.
class PluBadge extends StatelessWidget {
  const PluBadge(this.plu, {super.key, this.size = 48});
  final int plu;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: context.cs.primaryContainer, borderRadius: BorderRadius.circular(size * 0.32)),
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$plu',
              style: TextStyle(fontWeight: FontWeight.w800, color: context.cs.onPrimaryContainer, fontSize: 16),
            ),
          ),
        ),
      );
}
