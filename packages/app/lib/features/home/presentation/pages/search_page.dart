import 'package:core_ui/models/search_params.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';

/// SearchPage - Página de filtros de busca
/// Renderizada dentro do BottomNavScaffold (BottomNavigationBar permanece visível)
class SearchPage extends StatefulWidget {
  const SearchPage({
    required this.searchNotifier,
    required this.onApply,
    super.key,
  });
  final ValueNotifier<SearchParams?> searchNotifier;
  final VoidCallback onApply;

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  // === Tipo de post ===
  String? _selectedPostType; // 'musician' ou 'band'

  // === Seleções múltiplas ===
  final Set<String> _selectedInstruments = <String>{};
  final Set<String> _selectedGenres = <String>{};
  final Set<String> _selectedAvailableFor = <String>{};

  // === Nível ===
  String? _selectedLevel;

  // === YouTube ===
  bool _hasYoutube = false;

  // === Limites e opções ===
  static const int maxInstruments = 5;
  static const int maxGenres = 5;

  @override
  void initState() {
    super.initState();
    _loadExistingFilters();
  }

  /// Carrega filtros existentes do searchNotifier
  void _loadExistingFilters() {
    final currentParams = widget.searchNotifier.value;
    if (currentParams != null) {
      _selectedPostType = currentParams.postType;
      _selectedAvailableFor.clear();
      if (currentParams.availableFor != null) {
        _selectedAvailableFor.add(currentParams.availableFor!);
      }
      _selectedGenres
        ..clear()
        ..addAll(currentParams.genres);
      _selectedInstruments
        ..clear()
        ..addAll(currentParams.instruments);
      _selectedLevel = currentParams.level;
      _hasYoutube = currentParams.hasYoutube ?? false;
    }
  }

  static const List<String> _availableForOptions = <String>[
    'Ensaios regulares',
    'Free lance',
    'Gravações',
    'Apresentações ao vivo',
    'Turnês',
    'Criação de conteúdo digital',
    'Produção',
    'Outros',
  ];

  static const List<String> _instrumentOptions = <String>[
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

  static const List<String> _genreOptions = <String>[
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

  static const List<String> _levelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Profissional',
  ];

  /// Aplica os filtros selecionados (método público para acesso externo)
  void applyFilters() {
    final sp = SearchParams(
      city: 'São Paulo', // TODO: Obter da localização do usuário
      maxDistanceKm: 50, // TODO: Permitir configuração
      postType: _selectedPostType,
      availableFor:
          _selectedAvailableFor.isEmpty ? null : _selectedAvailableFor.first,
      genres: _selectedGenres,
      instruments: _selectedInstruments,
      level: _selectedLevel,
      hasYoutube: _hasYoutube,
    );
    widget.searchNotifier.value = sp;
    widget.onApply();
  }

  /// Limpa todos os filtros (método público para acesso externo)
  void clearFilters() {
    setState(() {
      _selectedPostType = null;
      _selectedAvailableFor.clear();
      _selectedGenres.clear();
      _selectedInstruments.clear();
      _selectedLevel = null;
      _hasYoutube = false;
    });
    widget.searchNotifier.value = null;
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          children: [
            // Título da página
            Text(
              'Filtros de busca',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // Tipo de post (Banda ou Músico)
            Text('Tipo de post', style: sectionTitleStyle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TypeFilterButton(
                    icon: Icons.person,
                    label: 'Músico\n(buscando banda)',
                    isSelected: _selectedPostType == 'musician',
                    onTap: () {
                      setState(() {
                        _selectedPostType =
                            _selectedPostType == 'musician' ? null : 'musician';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeFilterButton(
                    icon: Icons.groups,
                    label: 'Banda\n(buscando músico)',
                    isSelected: _selectedPostType == 'band',
                    onTap: () {
                      setState(() {
                        _selectedPostType =
                            _selectedPostType == 'band' ? null : 'band';
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(thickness: 0.5, height: 48),

            // Disponível para (lista suspensa)
            Text('Disponível para', style: sectionTitleStyle),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedAvailableFor.isNotEmpty
                  ? _selectedAvailableFor.first
                  : null,
              hint: const Text('Selecione uma opção'),
              items: _availableForOptions
                  .map(
                    (option) =>
                        DropdownMenuItem(value: option, child: Text(option)),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAvailableFor.clear();
                  if (value != null) _selectedAvailableFor.add(value);
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const Divider(thickness: 0.5, height: 48),

            // Gêneros musicais
            MultiSelectField(
              title: 'Gêneros musicais',
              placeholder: 'Selecione até 5 gêneros',
              options: _genreOptions,
              selectedItems: _selectedGenres,
              maxSelections: maxGenres,
              onSelectionChanged: (values) {
                setState(() {
                  _selectedGenres
                    ..clear()
                    ..addAll(values);
                });
              },
            ),
            const Divider(thickness: 0.5, height: 48),

            // Instrumentos de busca
            MultiSelectField(
              title: 'Instrumentos de busca',
              placeholder: 'Selecione até 5 instrumentos',
              options: _instrumentOptions,
              selectedItems: _selectedInstruments,
              maxSelections: maxInstruments,
              onSelectionChanged: (values) {
                setState(() {
                  _selectedInstruments
                    ..clear()
                    ..addAll(values);
                });
              },
            ),
            const Divider(thickness: 0.5, height: 48),

            // Nível
            Text('Nível', style: sectionTitleStyle),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedLevel,
              hint: const Text('Selecione o nível'),
              items: _levelOptions
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedLevel = value),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const Divider(height: 48, thickness: 0.5),

            // Vídeo no YouTube
            Text('Vídeo', style: sectionTitleStyle),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Apenas posts com vídeo no YouTube'),
              value: _hasYoutube,
              onChanged: (value) => setState(() => _hasYoutube = value),
              activeTrackColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: clearFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Limpar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Aplicar filtros',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget para botão de filtro de tipo (Banda/Músico)
class _TypeFilterButton extends StatelessWidget {
  const _TypeFilterButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
