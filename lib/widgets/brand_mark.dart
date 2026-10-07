import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// The Metro Scales logo: a scale icon on a rounded primary tile.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: context.cs.primary, borderRadius: BorderRadius.circular(size * 0.34)),
        child: Icon(Icons.scale_rounded, color: context.cs.onPrimary, size: size * 0.54),
      );
}
