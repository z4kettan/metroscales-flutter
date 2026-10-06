import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, required this.color, required this.background, this.dot = false});

  final String label;
  final Color color;
  final Color background;
  final bool dot;

  factory StatusPill.online(bool online) => online
      ? const StatusPill('Online', color: AppColors.success, background: AppColors.successSoft, dot: true)
      : const StatusPill('Offline', color: AppColors.textSecondary, background: AppColors.divider, dot: true);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (dot) ...[
            Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}

/// The item's PLU in a small rounded box.
class PluBadge extends StatelessWidget {
  const PluBadge(this.plu, {super.key});
  final int plu;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(10)),
        child: Text(
          '$plu',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontSize: 14),
        ),
      );
}
