import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';

/// Widget para seleção de gêneros musicais com validação e limite
/// 
/// ⚡ PERFORMANCE: Extraído de post_page.dart para melhor manutenibilidade
/// - Reduz complexidade da página principal
/// - Facilita testes unitários
/// - Reutilizável entre post_page.dart e edit_post_page.dart
class GenreSelector extends StatelessWidget {
  /// Cria um widget para seleção de gêneros musicais
  const GenreSelector({
    required this.selectedGenres,
    required this.onSelectionChanged,
    this.enabled = true,
    this.maxSelections = 5,
    this.title = 'Gêneros musicais',
    this.placeholder = 'Selecione até 5 gêneros',
    super.key,
  });

  /// Gêneros atualmente selecionados
  final Set<String> selectedGenres;
  
  /// Callback quando a seleção muda
  final ValueChanged<Set<String>> onSelectionChanged;
  
  /// Se o campo está habilitado para edição
  final bool enabled;
  
  /// Número máximo de gêneros selecionáveis
  final int maxSelections;
  
  /// Título do campo
  final String title;
  
  /// Placeholder quando nenhum gênero está selecionado
  final String placeholder;

  /// Lista completa de gêneros musicais disponíveis
  static const List<String> genreOptions = <String>[
    'Rock',
    'Pop',
    'Jazz',
    'Sertanejo',
    'Forró',
    'MPB',
    'Gospel',
    'Eletrônica',
    'Pagode',
    'Samba',
    'Axé',
    'Funk',
    'Rap',
    'Trap',
    'Hip Hop',
    'Reggae',
    'Blues',
    'Soul',
    'R&B',
    'Disco',
    'House',
    'Techno',
    'Trance',
    'Drum and Bass',
    'Dub',
    'Choro',
    'Bossa Nova',
    'Frevo',
    'Maracatu',
    'Coco',
    'Carimbó',
    'Lambada',
    'Brega',
    'Forró Universitário',
    'Forró Pé de Serra',
    'Xote',
    'Xaxado',
    'Vaneira',
    'Valsa',
    'Música Clássica',
    'Ópera',
    'Coral',
    'Música Infantil',
    'Música Experimental',
    'Indie',
    'Alternativo',
    'Punk',
    'Metal',
    'Hardcore',
    'Emo',
    'Grunge',
    'Progressivo',
    'Folk',
    'Country',
    'Bluegrass',
    'World Music',
    'Latina',
    'Cumbia',
    'Salsa',
    'Merengue',
    'Tango',
    'Bolero',
    'Reggaeton',
    'K-pop',
    'J-pop',
    'Música Árabe',
    'Música Africana',
    'Música Oriental',
    'Chillout',
    'Lo-fi',
    'Game Music',
    'Trilha Sonora',
    'Outro',
  ];

  @override
  Widget build(BuildContext context) {
    return MultiSelectField(
      title: title,
      placeholder: placeholder,
      options: genreOptions,
      selectedItems: selectedGenres,
      maxSelections: maxSelections,
      enabled: enabled,
      onSelectionChanged: onSelectionChanged,
    );
  }

  /// Valida se pelo menos um gênero foi selecionado
  static String? validateRequired(Set<String> genres) {
    if (genres.isEmpty) {
      return 'Selecione pelo menos um gênero musical';
    }
    return null;
  }

  /// Valida se a seleção está dentro do limite
  static String? validateMaxSelections(Set<String> genres, int max) {
    if (genres.length > max) {
      return 'Selecione no máximo $max gêneros';
    }
    return null;
  }

  /// Formata lista de gêneros para exibição
  /// 
  /// Exemplo: ["Rock", "Pop", "Jazz"] → "Rock, Pop, Jazz"
  static String formatGenres(Set<String> genres) {
    if (genres.isEmpty) return 'Nenhum gênero selecionado';
    return genres.join(', ');
  }

  /// Formata lista curta de gêneros (máx 3)
  /// 
  /// Exemplo: ["Rock", "Pop", "Jazz", "Blues"] → "Rock, Pop e +2"
  static String formatGenresShort(Set<String> genres, {int maxShow = 3}) {
    if (genres.isEmpty) return 'Nenhum';
    
    final list = genres.toList();
    if (list.length <= maxShow) {
      return list.join(', ');
    }
    
    final shown = list.take(maxShow).join(', ');
    final remaining = list.length - maxShow;
    return '$shown e +$remaining';
  }
}
