// WEGIG – HOME SEARCH BAR
// Extracted from HomePage for better maintainability
// Handles address search with TypeAhead

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:iconsax/iconsax.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.suggestionsCallback,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final Future<List<Map<String, dynamic>>> Function(String) suggestionsCallback;
  final void Function(Map<String, dynamic>) onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TypeAheadField<Map<String, dynamic>>(
        controller: controller,
        focusNode: focusNode,
        builder: (context, controller, focusNode) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Buscar por cidade ou região...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Iconsax.search_normal, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
          );
        },
        suggestionsCallback: suggestionsCallback,
        itemBuilder: (context, suggestion) {
          final displayName = suggestion['display_name'] as String? ?? '';
          return ListTile(
            leading: const Icon(Iconsax.location, color: Colors.blue),
            title: Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          );
        },
        onSelected: onSuggestionSelected,
        emptyBuilder: (context) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nenhum resultado encontrado',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        errorBuilder: (context, error) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Erro ao buscar endereços',
            style: TextStyle(color: Colors.red[300]),
          ),
        ),
      ),
    );
  }
}
