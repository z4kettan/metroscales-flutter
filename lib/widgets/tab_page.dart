import 'package:flutter/material.dart';

import 'branch_switcher.dart';

/// A main tab: a Material 3 large top app bar that collapses as the page
/// scrolls, with the branch chip, then the page's slivers.
class TabPage extends StatelessWidget {
  const TabPage({
    super.key,
    required this.title,
    required this.slivers,
    this.actions = const [],
    this.bottom,
    this.onRefresh,
    this.floatingActionButton,
    this.showBranch = true,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget> actions;
  final PreferredSizeWidget? bottom;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    final scroll = CustomScrollView(
      slivers: [
        SliverAppBar.large(
          title: Text(title),
          actions: [
            if (showBranch) const Padding(padding: EdgeInsets.only(right: 4), child: BranchChip()),
            ...actions,
            const SizedBox(width: 8),
          ],
          bottom: bottom,
        ),
        ...slivers,
      ],
    );
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: onRefresh == null ? scroll : RefreshIndicator(onRefresh: onRefresh!, edgeOffset: 160, child: scroll),
    );
  }
}

/// Standard padding for page content inside a [TabPage].
class SliverPagePadding extends StatelessWidget {
  const SliverPagePadding({super.key, required this.sliver, this.bottom = 24});
  final Widget sliver;
  final double bottom;

  @override
  Widget build(BuildContext context) =>
      SliverPadding(padding: EdgeInsets.fromLTRB(16, 4, 16, bottom), sliver: sliver);
}
