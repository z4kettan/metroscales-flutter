import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../models/sales.dart';

/// A simple bar chart of daily sales. The highlighted bar is [selected].
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.days, this.selected, this.onTap, this.height = 150});

  final List<DaySales> days;
  final DateTime? selected;
  final ValueChanged<DaySales>? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
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
                  padding: EdgeInsets.symmetric(horizontal: dense ? 1.5 : 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: max == 0 ? 0.02 : (d.total / max).clamp(0.02, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _isSelected(d) ? AppColors.primary : AppColors.primary.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(dense ? 3 : 6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 14,
                        child: i % labelEvery == 0
                            ? Text(
                                dense ? '${d.date.day}' : weekday.format(d.date),
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: _isSelected(d) ? FontWeight.w700 : FontWeight.w500,
                                  color: _isSelected(d) ? AppColors.primary : AppColors.textMuted,
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
