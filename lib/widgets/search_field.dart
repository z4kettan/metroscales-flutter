import 'package:flutter/material.dart';

/// A Material 3 search bar that reports what the user types.
class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.onChanged, this.hint = 'Search', this.trailing});

  final ValueChanged<String> onChanged;
  final String hint;
  final Widget? trailing;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SearchBar(
        controller: _controller,
        hintText: widget.hint,
        elevation: const WidgetStatePropertyAll(0),
        constraints: const BoxConstraints(minHeight: 54),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
        leading: const Icon(Icons.search_rounded),
        onChanged: (v) {
          setState(() {});
          widget.onChanged(v);
        },
        trailing: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Clear',
              onPressed: () {
                _controller.clear();
                setState(() {});
                widget.onChanged('');
              },
            )
          else
            ?widget.trailing,
        ],
      );
}
