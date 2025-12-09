import 'package:flutter/material.dart';
import 'package:core_ui/theme/app_colors.dart';

class GenreSelector extends StatelessWidget {
  final Set<String> selectedGenres;
  final ValueChanged<Set<String>> onSelectionChanged;

  const GenreSelector({
    super.key,
    required this.selectedGenres,
    required this.onSelectionChanged,
  });

  static const List<String> genreOptions = [
    'Rock', 'Pop', 'Jazz', 'Blues', 'Metal', 'Reggae',
    'MPB', 'Samba', 'Pagode', 'Forró', 'Sertanejo',
    'Eletrônica', 'Hip Hop', 'Rap', 'Funk', 'Clássica',
    'Gospel', 'Soul', 'R&B', 'Indie', 'Punk', 'Outro'
  ];

  static String? validateRequired(Set<String> genres) {
    if (genres.isEmpty) return 'Selecione pelo menos um gênero';
    return null;
  }

  static String? validateMaxSelections(Set<String> genres, int max) {
    if (genres.length > max) return 'Selecione no máximo $max gêneros';
    return null;
  }

  static String formatGenres(Set<String> genres) {
    if (genres.isEmpty) return '';
    return genres.join(', ');
  }

  static String formatGenresShort(Set<String> genres, {int maxShow = 3}) {
    if (genres.isEmpty) return '';
    final list = genres.toList();
    if (list.length <= maxShow) return list.join(', ');
    return '${list.take(maxShow).join(', ')} +${list.length - maxShow}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gêneros Musicais',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genreOptions.map((genre) {
            final isSelected = selectedGenres.contains(genre);
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = Set<String>.from(selectedGenres);
                if (selected) {
                  newSelection.add(genre);
                } else {
                  newSelection.remove(genre);
                }
                onSelectionChanged(newSelection);
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
