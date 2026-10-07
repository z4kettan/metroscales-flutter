import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/brand_mark.dart';

const _destinations = [
  (Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Home'),
  (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Items'),
  (Icons.scale_outlined, Icons.scale_rounded, 'Scales'),
  (Icons.insights_outlined, Icons.insights_rounded, 'Reports'),
  (Icons.widgets_outlined, Icons.widgets_rounded, 'More'),
];

/// The five main tabs: a navigation bar on phones and a navigation rail on
/// tablets and wide windows.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  void _go(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (wide) {
      return Scaffold(
        body: Row(children: [
          NavigationRail(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: _go,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.85,
            leading: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: BrandMark(size: 44)),
            destinations: [
              for (final (icon, selected, label) in _destinations)
                NavigationRailDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: Text(label)),
            ],
          ),
          Expanded(child: shell),
        ]),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final (icon, selected, label) in _destinations)
            NavigationDestination(icon: Icon(icon), selectedIcon: Icon(selected), label: label),
        ],
      ),
    );
  }
}
