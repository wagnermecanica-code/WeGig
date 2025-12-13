import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/models/search_params.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app/router/app_router.dart';

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
  // USERNAME PREVIEW (BUSCA EM TEMPO REAL)
  // ====================================================================
  final Debouncer _usernameDebouncer = Debouncer(milliseconds: 500);
  ProfileEntity? _usernamePreviewProfile;
  bool _isSearchingUsername = false;
  String? _usernameSearchError;
  
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
  final Set<String> _selectedSalesTypes = {};
  RangeValues _priceRange = const RangeValues(0, 5000);
  bool _onlyWithDiscount = false;
  bool _onlyActivePromos = false; // Default: mostrar todos os anúncios

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
    
    // Listener para busca de username em tempo real
    _usernameController.addListener(_onUsernameChanged);
    
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
      _selectedSalesTypes
        ..clear()
        ..addAll(current.salesTypes);
      _priceRange = RangeValues(
        current.minPrice ?? 0,
        current.maxPrice ?? 5000,
      );
      _onlyWithDiscount = current.onlyWithDiscount ?? false;
      _onlyActivePromos = current.onlyActivePromos ?? false;
      
      // Se está filtrando sales, vai para aba Anúncios
      if (current.postType == 'sales' || current.salesTypes.isNotEmpty) {
        _tabController.index = 1;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameDebouncer.cancel();
    _tabController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
  
  // ====================================================================
  // USERNAME SEARCH LOGIC
  // ====================================================================
  
  void _onUsernameChanged() {
    final username = _usernameController.text.trim().toLowerCase();
    
    if (username.isEmpty) {
      setState(() {
        _usernamePreviewProfile = null;
        _isSearchingUsername = false;
        _usernameSearchError = null;
      });
      return;
    }
    
    // Debounce para não fazer muitas requisições
    _usernameDebouncer.run(() => _searchUsernamePreview(username));
  }
  
  Future<void> _searchUsernamePreview(String username) async {
    if (!mounted) return;
    
    setState(() {
      _isSearchingUsername = true;
      _usernameSearchError = null;
    });
    
    try {
      final profilesRef = FirebaseFirestore.instance.collection('profiles');
      
      // Buscar por usernameLowercase (índice otimizado)
      var snapshot = await profilesRef
          .where('usernameLowercase', isEqualTo: username)
          .limit(1)
          .get();
      
      // Fallback para perfis antigos sem usernameLowercase
      if (snapshot.docs.isEmpty) {
        snapshot = await profilesRef
            .where('username', isEqualTo: username)
            .limit(1)
            .get();
      }
      
      if (!mounted) return;
      
      setState(() {
        _usernamePreviewProfile = snapshot.docs.isNotEmpty
            ? ProfileEntity.fromFirestore(snapshot.docs.first)
            : null;
        _isSearchingUsername = false;
      });
    } catch (error) {
      debugPrint('❌ Erro ao buscar username: $error');
      if (!mounted) return;
      setState(() {
        _usernameSearchError = 'Erro ao buscar perfil';
        _isSearchingUsername = false;
        _usernamePreviewProfile = null;
      });
    }
  }

  void _applyFilters() {
    final isAnunciosTab = _tabController.index == 1;
    
    debugPrint('🔍 SearchPageNew._applyFilters: isAnunciosTab = $isAnunciosTab');
    debugPrint('🔍 SearchPageNew._applyFilters: _selectedSalesTypes = $_selectedSalesTypes');
    debugPrint('🔍 SearchPageNew._applyFilters: _priceRange = $_priceRange');
    debugPrint('🔍 SearchPageNew._applyFilters: _onlyWithDiscount = $_onlyWithDiscount');
    debugPrint('🔍 SearchPageNew._applyFilters: _onlyActivePromos = $_onlyActivePromos');
    
    final currentParams = widget.searchNotifier.value;
    
    final searchParams = SearchParams(
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
      salesTypes: isAnunciosTab ? Set.of(_selectedSalesTypes) : {},
      minPrice: isAnunciosTab && _priceRange.start > 0 ? _priceRange.start : null,
      maxPrice: isAnunciosTab && _priceRange.end < 5000 ? _priceRange.end : null,
      onlyWithDiscount: isAnunciosTab ? (_onlyWithDiscount ? true : null) : null,
      onlyActivePromos: isAnunciosTab ? (_onlyActivePromos ? true : null) : null,
    );
    
    debugPrint('🔍 SearchPageNew: SearchParams.postType = ${searchParams.postType}');
    debugPrint('🔍 SearchPageNew: SearchParams.salesTypes = ${searchParams.salesTypes}');
    debugPrint('🔍 SearchPageNew: SearchParams.minPrice = ${searchParams.minPrice}');
    debugPrint('🔍 SearchPageNew: SearchParams.maxPrice = ${searchParams.maxPrice}');
    
    widget.searchNotifier.value = searchParams;
    widget.onApply();
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
      _selectedSalesTypes.clear();
      _priceRange = const RangeValues(0, 5000);
      _onlyWithDiscount = false;
      _onlyActivePromos = false;
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
              icon: Icon(Iconsax.people),
            ),
            Tab(
              icon: Icon(Iconsax.tag),
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
            hintText: 'nome.de.usuario',
            prefixIcon: const Icon(Iconsax.search_normal_1),
            prefixText: '@',
            prefixStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: _isSearchingUsername
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _usernameController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _usernameController.clear();
                          setState(() {
                            _usernamePreviewProfile = null;
                            _usernameSearchError = null;
                          });
                        },
                      )
                    : null,
          ),
          inputFormatters: [
            // Permite letras, números, pontos e underscores (padrão Instagram)
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
            // Converte para lowercase
            TextInputFormatter.withFunction((oldValue, newValue) {
              return newValue.copyWith(text: newValue.text.toLowerCase());
            }),
          ],
          textInputAction: TextInputAction.done,
        ),
        // Preview do perfil encontrado
        _buildUsernamePreview(),
      ],
    );
  }
  
  Widget _buildUsernamePreview() {
    // Erro na busca
    if (_usernameSearchError != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _usernameSearchError!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.red[600],
          ),
        ),
      );
    }
    
    // Nenhum username digitado ou buscando
    if (_usernameController.text.trim().isEmpty || _isSearchingUsername) {
      return const SizedBox.shrink();
    }
    
    // Perfil não encontrado
    if (_usernamePreviewProfile == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            Icon(Iconsax.info_circle, size: 16, color: Colors.grey[500]),
            const SizedBox(width: 6),
            Text(
              'Nenhum perfil encontrado com esse username',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    // Card do perfil encontrado
    final profile = _usernamePreviewProfile!;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Fecha a página de busca e navega para o perfil
            Navigator.of(context).pop();
            context.pushProfile(profile.profileId);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: profile.photoUrl != null
                      ? CachedNetworkImageProvider(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? Text(
                          profile.name.isNotEmpty
                              ? profile.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.username ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (profile.city.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Iconsax.location,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile.city,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Chip de tipo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: profile.isBand
                        ? AppColors.accent.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    profile.isBand ? 'Banda' : 'Músico',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: profile.isBand
                          ? AppColors.accent
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
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
              selected: _selectedSalesTypes.contains(type),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSalesTypes.add(type);
                  } else {
                    _selectedSalesTypes.remove(type);
                  }
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
