import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The Metro Scales logo: a scale icon on a teal tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF14958A), AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(size * 0.28),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: size * 0.4, offset: Offset(0, size * 0.12)),
          ],
        ),
        child: Icon(Icons.scale_rounded, color: Colors.white, size: size * 0.52),
      );
}
