import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Widget de chips de filtro por gênero
/// Usado em search_page e home_page para filtrar posts por gênero musical
class GenreFilterChips extends StatelessWidget {
  const GenreFilterChips({
    required this.selectedGenres,
    required this.onGenreToggle,
    super.key,
    this.maxGenres = 5,
  });
  final Set<String> selectedGenres;
  final void Function(String) onGenreToggle;
  final int maxGenres;

  static const List<String> genreOptions = <String>[
    'Rock',
    'Pop',
    'Jazz',
    'Blues',
    'Country',
    'Reggae',
    'Eletrônica',
    'Hip Hop',
    'Funk',
    'Samba',
    'Pagode',
    'MPB',
    'Sertanejo',
    'Forró',
    'Gospel',
    'Metal',
    'Punk',
    'Indie',
    'Alternativo',
    'Clássica',
    'Soul',
    'R&B',
    'Bossa Nova',
    'Axé',
    'Arrocha',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: genreOptions.map((genre) {
        final isSelected = selectedGenres.contains(genre);
        final canSelect = selectedGenres.length < maxGenres || isSelected;

        return FilterChip(
          label: Text(genre),
          selected: isSelected,
          onSelected: canSelect ? (selected) => onGenreToggle(genre) : null,
          backgroundColor: Colors.white,
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
