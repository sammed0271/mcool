import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: hintText,
      leading: const Icon(Icons.search, size: 20),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12),
      ),
      onChanged: onChanged,
      backgroundColor: WidgetStatePropertyAll(Colors.grey.shade100),
      elevation: const WidgetStatePropertyAll(0),
    );
  }
}
