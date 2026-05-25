import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/music_constants.dart';
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

  /// Lista completa de gêneros vinda de [MusicConstants.genreOptions].
  ///
  /// Mantida como getter estático para preservar a API pública e garantir que
  /// qualquer adição em `MusicConstants` apareça automaticamente nos filtros
  /// de busca/home.
  static List<String> get genreOptions => MusicConstants.genreOptions;

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
