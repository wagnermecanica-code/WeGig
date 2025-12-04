import 'package:flutter/material.dart';

/// Renders the chips that represent availability options inside the post form.
class AvailableForSelector extends StatelessWidget {
  const AvailableForSelector({
    super.key,
    required this.options,
    required this.selectedValues,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selectedValues;
  final void Function(String value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return FilterChip(
          selected: isSelected,
          label: Text(option),
          onSelected: (_) => onToggle(option),
        );
      }).toList(),
    );
  }
}
