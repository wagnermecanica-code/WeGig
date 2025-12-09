import 'package:core_ui/models/search_params.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';

/// SearchPage com sistema de abas: Músicos/Bandas + Anúncios
class SearchPageNew extends StatefulWidget {
  const SearchPageNew({
    required this.searchNotifier,
    required this.onApply,
    super.key,
  });

  final ValueNotifier<SearchParams?> searchNotifier;
  final VoidCallback onApply;

  @override
  State<SearchPageNew> createState() => _SearchPageNewState();
}

class _SearchPageNewState extends State<SearchPageNew> with SingleTickerProviderStateMixin {
  // ====================================================================
  // TAB CONTROLLER
  // ====================================================================
  late TabController _tabController;
  
  // ====================================================================
  // CAMPOS COMUNS (TODAS AS ABAS)
  // ====================================================================
  final TextEditingController _usernameController = TextEditingController();
  
  // ====================================================================
  // CAMPOS MÚSICOS/BANDAS (ABA 0)
  // ====================================================================
  String? _selectedPostType; // 'musician' ou 'band'
  String? _selectedLevel;
  final Set<String> _selectedInstruments = {};
  final Set<String> _selectedGenres = {};
  String? _selectedAvailableFor;
  bool _hasYouTube = false;

  // ====================================================================
  // CAMPOS ANÚNCIOS (ABA 1)
  // ====================================================================
  String? _selectedSalesType;
  RangeValues _priceRange = const RangeValues(0, 5000);
  bool _onlyWithDiscount = false;
  bool _onlyActivePromos = true; // Default: mostrar apenas ativos

  // ====================================================================
  // OPÇÕES
  // ====================================================================
  static const List<String> _salesTypeOptions = [
    'Venda',
    'Gravação',
    'Ensaios',
    'Aluguel',
    'Show/Evento',
    'Aula/Workshop',
    'Freela',
    'Promoção',
    'Manutenção/Reparo',
    'Outro',
  ];

  static const List<String> _levelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Profissional',
  ];

  static const List<String> _instrumentOptions = [
    'Violão', 'Guitarra', 'Baixo', 'Bateria', 'Teclado', 'Piano',
    'Canto', 'DJ', 'Saxofone', 'Trompete', 'Percussão', 'Outro',
  ];

  static const List<String> _genreOptions = [
    'Rock', 'Pop', 'Jazz', 'Sertanejo', 'Forró', 'MPB', 'Gospel',
    'Eletrônica', 'Pagode', 'Samba', 'Axé', 'Funk', 'Rap', 'Blues', 'Outro',
  ];

  static const List<String> _availableForOptions = [
    'Ensaios regulares',
    'Free lance',
    'Gravações',
    'Apresentações ao vivo',
    'Turnês',
    'Criação de conteúdo digital',
    'Produção',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    
    _tabController = TabController(length: 2, vsync: this);
    
    // Carregar valores existentes (se houver)
    final current = widget.searchNotifier.value;
    if (current != null) {
      _usernameController.text = current.searchUsername ?? '';
      
      // Músicos/Bandas
      _selectedPostType = current.postType;
      _selectedLevel = current.level;
      _selectedInstruments.addAll(current.instruments);
      _selectedGenres.addAll(current.genres);
      _selectedAvailableFor = current.availableFor;
      _hasYouTube = current.hasYoutube ?? false;
      
      // Anúncios
      _selectedSalesType = current.salesType;
      _priceRange = RangeValues(
        current.minPrice ?? 0,
        current.maxPrice ?? 5000,
      );
      _onlyWithDiscount = current.onlyWithDiscount ?? false;
      _onlyActivePromos = current.onlyActivePromos ?? true;
      
      // Se está filtrando sales, vai para aba Anúncios
      if (current.postType == 'sales' || current.salesType != null) {
        _tabController.index = 1;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final isAnunciosTab = _tabController.index == 1;
    
    final currentParams = widget.searchNotifier.value;
    
    widget.searchNotifier.value = SearchParams(
      // Campos obrigatórios mantidos do anterior
      city: currentParams?.city ?? '',
      maxDistanceKm: currentParams?.maxDistanceKm ?? 20.0,
      
      // Username (comum a todas abas)
      searchUsername: _usernameController.text.trim().isEmpty 
          ? null 
          : _usernameController.text.trim(),
      
      // Músicos/Bandas (apenas se aba 0 ativa)
      postType: isAnunciosTab ? 'sales' : _selectedPostType,
      level: !isAnunciosTab ? _selectedLevel : null,
      instruments: !isAnunciosTab ? _selectedInstruments : {},
      genres: !isAnunciosTab ? _selectedGenres : {},
      availableFor: !isAnunciosTab ? _selectedAvailableFor : null,
      hasYoutube: !isAnunciosTab ? (_hasYouTube ? true : null) : null,
      
      // Anúncios (apenas se aba 1 ativa)
      salesType: isAnunciosTab ? _selectedSalesType : null,
      minPrice: isAnunciosTab && _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: isAnunciosTab && _priceRange.end < 5000 ? _priceRange.end : null,
      onlyWithDiscount: isAnunciosTab ? (_onlyWithDiscount ? true : null) : null,
      onlyActivePromos: isAnunciosTab ? (_onlyActivePromos ? true : null) : null,
    );
    
    widget.onApply();
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _usernameController.clear();
      
      // Músicos/Bandas
      _selectedPostType = null;
      _selectedLevel = null;
      _selectedInstruments.clear();
      _selectedGenres.clear();
      _selectedAvailableFor = null;
      _hasYouTube = false;
      
      // Anúncios
      _selectedSalesType = null;
      _priceRange = const RangeValues(0, 5000);
      _onlyWithDiscount = false;
      _onlyActivePromos = true;
    });
    
    final currentParams = widget.searchNotifier.value;
    widget.searchNotifier.value = SearchParams(
      city: currentParams?.city ?? '',
      maxDistanceKm: currentParams?.maxDistanceKm ?? 20.0,
    );
    widget.onApply();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 28, color: AppColors.primary),
        ),
        title: const Text(
          'Filtros de Busca',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearFilters,
            child: const Text(
              'Limpar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(
              icon: Icon(Iconsax.user),
              text: 'Músicos/Bandas',
            ),
            Tab(
              icon: Icon(Iconsax.tag),
              text: 'Anúncios',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMusicianBandFilters(),
          _buildSalesFilters(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _applyFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Aplicar Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ====================================================================
  // ABA 0: MÚSICOS/BANDAS
  // ====================================================================
  Widget _buildMusicianBandFilters() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Buscar por @username (comum)
        _buildUsernameSearch(),
        const Divider(height: 32),
        
        // 2. Tipo de post
        _buildPostTypeSelector(),
        const Divider(height: 32),
        
        // 3. Instrumentos
        _buildInstrumentsSelector(),
        const Divider(height: 32),
        
        // 4. Gêneros
        _buildGenresSelector(),
        const Divider(height: 32),
        
        // 5. Nível
        _buildLevelSelector(),
        const Divider(height: 32),
        
        // 6. Disponível para
        _buildAvailableForSelector(),
        const Divider(height: 32),
        
        // 7. YouTube
        _buildYouTubeSwitch(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ====================================================================
  // ABA 1: ANÚNCIOS
  // ====================================================================
  Widget _buildSalesFilters() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Buscar por @username (comum)
        _buildUsernameSearch(),
        const Divider(height: 32),
        
        // 2. Tipo de anúncio
        _buildSalesTypeSelector(),
        const Divider(height: 32),
        
        // 3. Faixa de preço
        _buildPriceRangeSlider(),
        const Divider(height: 32),
        
        // 4. Apenas com desconto
        _buildDiscountSwitch(),
        const Divider(height: 32),
        
        // 5. Apenas promoções ativas
        _buildActivePromosSwitch(),
        const SizedBox(height: 16),
      ],
    );
  }

  // ====================================================================
  // WIDGETS COMUNS
  // ====================================================================
  
  Widget _buildUsernameSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buscar por @username',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _usernameController,
          decoration: InputDecoration(
            hintText: 'Ex: @joaomusico',
            prefixIcon: const Icon(Iconsax.search_normal_1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  // ====================================================================
  // WIDGETS MÚSICOS/BANDAS
  // ====================================================================
  
  Widget _buildPostTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de post',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Músico'),
              selected: _selectedPostType == 'musician',
              onSelected: (selected) {
                setState(() {
                  _selectedPostType = selected ? 'musician' : null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            ),
            FilterChip(
              label: const Text('Banda'),
              selected: _selectedPostType == 'band',
              onSelected: (selected) {
                setState(() {
                  _selectedPostType = selected ? 'band' : null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInstrumentsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Instrumentos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${_selectedInstruments.length}/5',
              style: TextStyle(
                fontSize: 14,
                color: _selectedInstruments.length >= 5 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _instrumentOptions.map((instrument) {
            final isSelected = _selectedInstruments.contains(instrument);
            final isDisabled = !isSelected && _selectedInstruments.length >= 5;
            
            return FilterChip(
              label: Text(instrument),
              selected: isSelected,
              onSelected: isDisabled ? null : (selected) {
                setState(() {
                  if (selected) {
                    _selectedInstruments.add(instrument);
                  } else {
                    _selectedInstruments.remove(instrument);
                  }
                });
              },
              backgroundColor: isDisabled ? Colors.grey[200] : null,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGenresSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gêneros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              '${_selectedGenres.length}/5',
              style: TextStyle(
                fontSize: 14,
                color: _selectedGenres.length >= 5 ? Colors.red : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _genreOptions.map((genre) {
            final isSelected = _selectedGenres.contains(genre);
            final isDisabled = !isSelected && _selectedGenres.length >= 5;
            
            return FilterChip(
              label: Text(genre),
              selected: isSelected,
              onSelected: isDisabled ? null : (selected) {
                setState(() {
                  if (selected) {
                    _selectedGenres.add(genre);
                  } else {
                    _selectedGenres.remove(genre);
                  }
                });
              },
              backgroundColor: isDisabled ? Colors.grey[200] : null,
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLevelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nível',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _levelOptions.map((level) {
            return FilterChip(
              label: Text(level),
              selected: _selectedLevel == level,
              onSelected: (selected) {
                setState(() {
                  _selectedLevel = selected ? level : null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAvailableForSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponível para',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableForOptions.map((option) {
            return FilterChip(
              label: Text(option),
              selected: _selectedAvailableFor == option,
              onSelected: (selected) {
                setState(() {
                  _selectedAvailableFor = selected ? option : null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildYouTubeSwitch() {
    return SwitchListTile(
      title: const Text('Apenas com YouTube'),
      value: _hasYouTube,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _hasYouTube = value;
        });
      },
    );
  }

  // ====================================================================
  // WIDGETS ANÚNCIOS
  // ====================================================================
  
  Widget _buildSalesTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de anúncio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _salesTypeOptions.map((type) {
            return FilterChip(
              label: Text(type),
              selected: _selectedSalesType == type,
              onSelected: (selected) {
                setState(() {
                  _selectedSalesType = selected ? type : null;
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.1),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Faixa de preço',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              'R\$ ${_priceRange.start.toInt()} - R\$ ${_priceRange.end.toInt()}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 5000,
          divisions: 50,
          activeColor: AppColors.primary,
          labels: RangeLabels(
            'R\$ ${_priceRange.start.toInt()}',
            'R\$ ${_priceRange.end.toInt()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('R\$ 0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Text('R\$ 5.000', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountSwitch() {
    return SwitchListTile(
      title: const Text('Apenas com desconto'),
      subtitle: const Text('Mostrar apenas anúncios com promoção'),
      value: _onlyWithDiscount,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _onlyWithDiscount = value;
        });
      },
    );
  }

  Widget _buildActivePromosSwitch() {
    return SwitchListTile(
      title: const Text('Apenas promoções ativas'),
      subtitle: const Text('Ocultar anúncios expirados'),
      value: _onlyActivePromos,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        setState(() {
          _onlyActivePromos = value;
        });
      },
    );
  }
}
