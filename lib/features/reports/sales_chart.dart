import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';

/// A bar chart of daily sales. The [selected] day is drawn in the primary
/// colour with its total above it.
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.days, this.selected, this.onTap, this.height = 170});

  final List<DaySales> days;
  final DateTime? selected;
  final ValueChanged<DaySales>? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final max = days.fold<double>(0, (m, d) => d.total > m ? d.total : m);
    final dense = days.length > 10;
    final labelEvery = days.length <= 10 ? 1 : (days.length / 6).ceil();
    final weekday = DateFormat('E');

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, d) in days.indexed)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap == null ? null : () => onTap!(d),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: dense ? 1.5 : 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        height: 20,
                        child: _isSelected(d) && !dense
                            ? FittedBox(
                                child: Text(
                                  moneyCompact(d.total.roundToDouble()),
                                  style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary, fontSize: 12),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: max == 0 ? 0.03 : (d.total / max).clamp(0.03, 1.0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              decoration: BoxDecoration(
                                color: _isSelected(d) ? cs.primary : cs.primaryContainer,
                                borderRadius: BorderRadius.circular(dense ? 4 : 10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 16,
                        child: i % labelEvery == 0
                            ? Text(
                                dense ? '${d.date.day}' : weekday.format(d.date),
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: _isSelected(d) ? FontWeight.w800 : FontWeight.w600,
                                  color: _isSelected(d) ? cs.primary : cs.onSurfaceVariant,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isSelected(DaySales d) => selected != null && dateOnly(selected!) == dateOnly(d.date);
}
