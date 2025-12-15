import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';

/// Widget para seleção de instrumentos com validação e limite
/// 
/// ⚡ PERFORMANCE: Extraído de post_page.dart para melhor manutenibilidade
/// - Reduz complexidade da página principal
/// - Facilita testes unitários
/// - Reutilizável entre post_page.dart e edit_post_page.dart
class InstrumentSelector extends StatelessWidget {
  /// Cria um widget para seleção de instrumentos
  const InstrumentSelector({
    required this.selectedInstruments,
    required this.onSelectionChanged,
    this.enabled = true,
    this.maxSelections = 5,
    this.title = 'Instrumentos',
    this.placeholder = 'Selecione até 5 instrumentos',
    super.key,
  });

  /// Instrumentos atualmente selecionados
  final Set<String> selectedInstruments;
  
  /// Callback quando a seleção muda
  final ValueChanged<Set<String>> onSelectionChanged;
  
  /// Se o campo está habilitado para edição
  final bool enabled;
  
  /// Número máximo de instrumentos selecionáveis
  final int maxSelections;
  
  /// Título do campo
  final String title;
  
  /// Placeholder quando nenhum instrumento está selecionado
  final String placeholder;

  /// Lista completa de instrumentos disponíveis
  static const List<String> instrumentOptions = <String>[
    'Violão',
    'Guitarra',
    'Baixo',
    'Bateria',
    'Teclado',
    'Piano',
    'Canto',
    'DJ',
    'Saxofone',
    'Trompete',
    'Trombone',
    'Flauta',
    'Clarinete',
    'Oboé',
    'Fagote',
    'Contrabaixo',
    'Percussão',
    'Cajón',
    'Congas',
    'Bongô',
    'Pandeiro',
    'Surdo',
    'Tamborim',
    'Repique',
    'Cuíca',
    'Zabumba',
    'Triângulo',
    'Acordeon',
    'Bandolim',
    'Cavaquinho',
    'Ukulele',
    'Banjo',
    'Harp',
    'Viola Caipira',
    'Sitar',
    'Lira',
    'Cello',
    'Violino',
    'Viola',
    'Gaita',
    'Harmônica',
    'Sintetizador',
    'Sampler',
    'Programação',
    'Beatmaker',
    'Regência',
    'Arranjo',
    'Produção',
    'Backing vocal',
    'Maestro',
    'Técnico de som',
    'Roadie',
    'Luthier',
    'Outro',
  ];

  @override
  Widget build(BuildContext context) {
    return MultiSelectField(
      title: title,
      placeholder: placeholder,
      options: instrumentOptions,
      selectedItems: selectedInstruments,
      maxSelections: maxSelections,
      enabled: enabled,
      onSelectionChanged: onSelectionChanged,
    );
  }

  /// Valida se pelo menos um instrumento foi selecionado (para músicos)
  static String? validateForMusician(Set<String> instruments) {
    if (instruments.isEmpty) {
      return 'Músicos devem selecionar pelo menos um instrumento';
    }
    return null;
  }

  /// Valida se a seleção está dentro do limite
  static String? validateMaxSelections(Set<String> instruments, int max) {
    if (instruments.length > max) {
      return 'Selecione no máximo $max instrumentos';
    }
    return null;
  }

  /// Formata lista de instrumentos para exibição
  /// 
  /// Exemplo: ["Guitarra", "Baixo", "Bateria"] → "Guitarra, Baixo, Bateria"
  static String formatInstruments(Set<String> instruments) {
    if (instruments.isEmpty) return 'Nenhum instrumento selecionado';
    return instruments.join(', ');
  }

  /// Formata lista curta de instrumentos (máx 3)
  /// 
  /// Exemplo: ["Guitarra", "Baixo", "Bateria", "Piano"] → "Guitarra, Baixo e +2"
  static String formatInstrumentsShort(Set<String> instruments, {int maxShow = 3}) {
    if (instruments.isEmpty) return 'Nenhum';
    
    final list = instruments.toList();
    if (list.length <= maxShow) {
      return list.join(', ');
    }
    
    final shown = list.take(maxShow).join(', ');
    final remaining = list.length - maxShow;
    return '$shown e +$remaining';
  }
}
