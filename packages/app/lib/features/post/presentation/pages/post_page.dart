import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/post_result.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:wegig_app/features/post/domain/models/post_form_input.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/post/presentation/widgets/photo_carousel_picker.dart';
import 'package:wegig_app/features/post/presentation/widgets/post_form_fields.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Navega para a página de criação de post
void showPostModal(BuildContext context, String postType) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => PostPage(postType: postType),
    ),
  );
}

/// Navega para a página de edição de post
void showEditPostModal(BuildContext context, Map<String, dynamic> postData) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (context) => PostPage(
        postType: (postData['type'] as String?) ?? 'musician',
        existingPostData: postData,
      ),
    ),
  );
}

class PostPage extends ConsumerStatefulWidget {
  const PostPage({
    required this.postType,
    super.key,
    this.existingPostData,
  });
  final String postType;
  final Map<String, dynamic>? existingPostData;

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _youtubeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final FocusNode _locationFocusNode = FocusNode();

  // === Tipo do post ===
  late final String _postType;

  // === Seleções múltiplas ===
  final Set<String> _selectedInstruments = <String>{};
  final Set<String> _selectedGenres = <String>{};
  final Set<String> _selectedAvailableFor = <String>{};

  // === Nível ===
  String _level = 'Intermediário';

  // === Localização ===
  GeoPoint? _selectedLocation;
  String? _selectedCity;
  String? _selectedNeighborhood;
  String? _selectedState;

  // === Foto & Estado ===
  List<String> _photoPaths = [];
  bool _isSaving = false;

  // === Sales-specific fields ===
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  
  String _salesType = 'Venda';
  String _discountMode = 'none'; // 'none', 'percentage', 'fixed'
  double _calculatedFinalPrice = 0.0;
  DateTime _promoStartDate = DateTime.now();
  DateTime _promoEndDate = DateTime.now().add(const Duration(days: 30));

  // === Limites e opções ===
  static const int maxInstruments = 5;
  static const int maxGenres = 5;

  // === Sales type options ===
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

 // Lista para disponibilidade
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

 // ✨ EXPANDIDO: Lista completa de instrumentos com opção "Outros"
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

  // ✨ EXPANDIDO: Lista completa de gêneros musicais com opção "Outros"
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

  @override
  void initState() {
    super.initState();
    _postType = widget.postType;
    
    // Inicializar listeners para sales
    if (_postType == 'sales') {
      _priceController.addListener(_calculateFinalPrice);
      _discountController.addListener(_calculateFinalPrice);
    }
    
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    if (widget.existingPostData == null) return;

    final data = widget.existingPostData!;

    // Carregar dados existentes
    _messageController.text = (data['content'] as String?) ?? '';
    _youtubeController.text = (data['youtubeLink'] as String?) ?? '';
    _level = (data['level'] as String?) ?? 'Intermediário';

    // Instrumentos
    if (data['instruments'] is List) {
      _selectedInstruments.addAll((data['instruments'] as List).cast<String>());
    }

    // Buscando músicos (para bandas)
    if (data['seekingMusicians'] is List) {
      _selectedInstruments
          .addAll((data['seekingMusicians'] as List).cast<String>());
    }

    // Gêneros
    if (data['genres'] is List) {
      _selectedGenres.addAll((data['genres'] as List).cast<String>());
    }

    // Disponível para - buscar do Firestore se existir
    if (data['availableFor'] is List) {
      _selectedAvailableFor
          .addAll((data['availableFor'] as List).cast<String>());
    } else if (data['postId'] != null) {
      // Buscar do Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('posts')
            .doc((data['postId'] as String?) ?? '')
            .get();
        if (doc.exists && doc.data()?['availableFor'] is List) {
          setState(() {
            _selectedAvailableFor
                .addAll((doc.data()!['availableFor'] as List).cast<String>());
          });
        }
      } catch (e) {
        debugPrint('Erro ao buscar availableFor: $e');
      }
    }

    // Localização - buscar endereço completo
    if (data['location'] is GeoPoint) {
      final geoPoint = data['location'] as GeoPoint;
      _selectedLocation = geoPoint;
      _selectedCity = (data['city'] as String?) ?? '';
      _selectedNeighborhood = data['neighborhood'] as String?;
      _selectedState = data['state'] as String?;

      // Buscar endereço completo via reverse geocoding
      await _fetchFullAddress(geoPoint.latitude, geoPoint.longitude);
    }

    // Fotos (URLs existentes - suporte para lista ou single)
    setState(() {
      final photoUrls = data['photoUrls'] as List<dynamic>?;
      final photoUrl = data['photoUrl'] as String?;
      
      if (photoUrls != null && photoUrls.isNotEmpty) {
        _photoPaths = photoUrls.cast<String>().toList();
      } else if (photoUrl != null && photoUrl.isNotEmpty) {
        _photoPaths = [photoUrl];
      }
    });
  }

  Future<void> _fetchFullAddress(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'to-sem-banda-app'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = (address['road'] as String?) ?? '';
          final neighbourhood = (address['neighbourhood'] as String?) ??
              (address['suburb'] as String?) ??
              (address['quarter'] as String?) ??
              '';
          final city = (address['city'] as String?) ??
              (address['town'] as String?) ??
              (address['village'] as String?) ??
              (address['municipality'] as String?) ??
              '';
          final state = (address['state'] as String?) ?? '';

          final parts = <String>[];
          if (road.isNotEmpty) parts.add(road);
          if (neighbourhood.isNotEmpty) parts.add(neighbourhood);
          if (city.isNotEmpty) parts.add(city);

          setState(() {
            _locationController.text = parts.join(', ');
            _selectedCity = city;
            _selectedNeighborhood =
                neighbourhood.isNotEmpty ? neighbourhood : null;
            _selectedState = state.isNotEmpty ? state : null;
          });
        }
      }
    } catch (e) {
      debugPrint('Erro ao buscar endereço completo: $e');
      // Fallback para cidade apenas
      setState(() {
        _locationController.text = _selectedCity ?? '';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _youtubeController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    
    // Dispose sales-specific controllers
    if (_postType == 'sales') {
      _titleController.dispose();
      _priceController.dispose();
      _discountController.dispose();
      _whatsappController.dispose();
    }
    
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(
    String query,
  ) async {
    if (query.isEmpty) return [];
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5',
    );
    final response = await http.get(
      url,
      headers: {'User-Agent': 'to-sem-banda-app'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List<dynamic>;
      return data
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
    }
    return [];
  }

  void _onAddressSelected(Map<String, dynamic> suggestion) {
    final lat = double.tryParse((suggestion['lat'] as String?) ?? '') ?? 0.0;
    final lon = double.tryParse((suggestion['lon'] as String?) ?? '') ?? 0.0;

    if (lat != 0.0 && lon != 0.0) {
      final address = suggestion['address'] as Map<String, dynamic>?;

      // Extrair componentes do endereço
      final road = (address?['road'] as String?) ?? '';
      final neighbourhood = (address?['neighbourhood'] as String?) ??
          (address?['suburb'] as String?) ??
          (address?['quarter'] as String?) ??
          '';
      final city = (address?['city'] as String?) ??
          (address?['town'] as String?) ??
          (address?['village'] as String?) ??
          (address?['municipality'] as String?) ??
          '';
      final state = (address?['state'] as String?) ?? '';

      // Montar string formatada: rua, bairro, cidade
      final parts = <String>[];
      if (road.isNotEmpty) parts.add(road);
      if (neighbourhood.isNotEmpty) parts.add(neighbourhood);
      if (city.isNotEmpty) parts.add(city);

      setState(() {
        _selectedLocation = GeoPoint(lat, lon);
        _locationController.text = parts.isNotEmpty
            ? parts.join(', ')
            : (suggestion['display_name'] as String?) ?? '';
        _selectedCity = city;
        _selectedNeighborhood = neighbourhood.isNotEmpty ? neighbourhood : null;
        _selectedState = state.isNotEmpty ? state : null;
      });
      _locationFocusNode.unfocus();
    }
  }

  void _calculateFinalPrice() {
    final priceStr = _priceController.text.replaceAll(RegExp(r'[^\d]'), '');
    final price = double.tryParse(priceStr) ?? 0.0;
    
    if (_discountMode == 'none' || _discountController.text.isEmpty) {
      setState(() => _calculatedFinalPrice = price / 100);
      return;
    }
    
    final discountStr = _discountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final discountValue = double.tryParse(discountStr) ?? 0.0;
    
    if (_discountMode == 'percentage') {
      final discountAmount = (price * discountValue) / 10000;
      setState(() => _calculatedFinalPrice = (price / 100) - discountAmount);
    } else if (_discountMode == 'fixed') {
      setState(() => _calculatedFinalPrice = (price / 100) - (discountValue / 100));
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Preencha todos os campos obrigatórios.', isError: true);
      return;
    }

    // Validações específicas por tipo
    if (_postType == 'sales') {
      // Sales: fotos, título, descrição, tipo, preço, localização (SEM gêneros/instrumentos)
      if (_photoPaths.isEmpty) {
        _showSnackBar('Adicione pelo menos uma foto do produto/serviço.', isError: true);
        return;
      }
      if (_titleController.text.trim().isEmpty) {
        _showSnackBar('Título é obrigatório para anúncios.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        _showSnackBar('Descrição é obrigatória para anúncios.', isError: true);
        return;
      }
      if (_priceController.text.isEmpty || _calculatedFinalPrice <= 0) {
        _showSnackBar('Preço deve ser maior que zero.', isError: true);
        return;
      }
      if (_promoEndDate.isBefore(_promoStartDate)) {
        _showSnackBar('Data de fim deve ser após a data de início.', isError: true);
        return;
      }
      // Sales NÃO precisa de gêneros ou instrumentos
    } else if (_postType == 'musician') {
      // Musician: instrumentos, gêneros, descrição, localização
      if (_selectedInstruments.isEmpty) {
        _showSnackBar('Selecione pelo menos um instrumento.', isError: true);
        return;
      }
      if (_selectedGenres.isEmpty) {
        _showSnackBar('Selecione pelo menos um gênero musical.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        _showSnackBar('Mensagem é obrigatória.', isError: true);
        return;
      }
    } else if (_postType == 'band') {
      // Band: músicos procurados, gêneros, descrição, localização
      if (_selectedInstruments.isEmpty) {
        _showSnackBar('Selecione pelo menos um instrumento/músico procurado.', isError: true);
        return;
      }
      if (_selectedGenres.isEmpty) {
        _showSnackBar('Selecione pelo menos um gênero musical.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        _showSnackBar('Mensagem é obrigatória.', isError: true);
        return;
      }
    }

    final location = _selectedLocation;
    final city = _selectedCity;
    if (location == null || city == null) {
      _showSnackBar('Selecione uma localização válida.', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final input = PostFormInput(
        postId: widget.existingPostData?['postId'] as String?,
        type: _postType,
        
        // Campos específicos de sales
        title: _postType == 'sales' ? _titleController.text.trim() : null,
        salesType: _postType == 'sales' ? _salesType : null,
        price: _postType == 'sales' ? _calculatedFinalPrice : null,
        discountMode: _postType == 'sales' ? _discountMode : null,
        discountValue: _postType == 'sales' && _discountController.text.isNotEmpty
            ? double.tryParse(_discountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0
            : null,
        promoStartDate: _postType == 'sales' ? _promoStartDate : null,
        promoEndDate: _postType == 'sales' ? _promoEndDate : null,
        whatsappNumber: _postType == 'sales' && _whatsappController.text.isNotEmpty
            ? _whatsappController.text.replaceAll(RegExp(r'\D'), '')
            : null,
        
        // Campos comuns
        content: _messageController.text.trim(),
        location: location,
        city: city,
        neighborhood: _selectedNeighborhood,
        state: _selectedState,
        photoPaths: _photoPaths,
        youtubeLink: _youtubeController.text.trim().isEmpty ? null : _youtubeController.text.trim(),
        
        // Campos de musician/band (null para sales)
        level: _postType != 'sales' ? _level : null,
        genres: _postType != 'sales' ? _selectedGenres.toList() : <String>[],
        selectedInstruments: _postType != 'sales' ? _selectedInstruments.toList() : <String>[],
        availableFor: _postType != 'sales' ? _selectedAvailableFor.toList() : <String>[],
        
        createdAt: _maybeExtractDate(widget.existingPostData?['createdAt']),
        expiresAt: _maybeExtractDate(widget.existingPostData?['expiresAt']),
      );

      final notifier = ref.read(postNotifierProvider.notifier);
      final result = await notifier.savePost(input);

      if (!mounted) return;

      if (result is PostSuccess) {
        _showSnackBar(
          result.message ??
              (input.isEditing
                  ? 'Post atualizado com sucesso!'
                  : 'Post criado com sucesso!'),
        );
        Navigator.of(context).pop(true);
      } else if (result is PostValidationError) {
        _showSnackBar(
          result.errors.values.join('\n'),
          isError: true,
        );
      } else if (result is PostFailure) {
        _showSnackBar(result.message, isError: true);
      } else {
        _showSnackBar(
          'Não foi possível salvar o post. Tente novamente.',
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ PostPage: erro ao salvar post - $e');
      debugPrint('$stackTrace');
      if (mounted) {
        _showSnackBar('Erro ao salvar post: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  DateTime? _maybeExtractDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    // Ler provider apenas uma vez, sem observar mudanças para evitar rebuild loops
    final profileAsync = ref.read(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 28),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _submitPost,
              icon: const Icon(
                Icons.send_rounded,
                size: 26,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
          ),
        ),
        error: (err, stack) => const Center(
          child: Text('Erro ao carregar perfil. Tente novamente.'),
        ),
        data: (profileState) {
          final profile = profileState.activeProfile;

          return AbsorbPointer(
            absorbing: _isSaving,
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 24,
                ),
                children: [
                  // Card de Título
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Foto do perfil
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: profile?.photoUrl != null &&
                                    profile!.photoUrl!.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: profile.photoUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Icon(
                                      _postType == 'musician'
                                          ? Icons.person
                                          : Icons.groups,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      _postType == 'musician'
                                          ? Icons.person
                                          : Icons.groups,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  )
                                : Icon(
                                    _postType == 'musician'
                                        ? Icons.person
                                        : Icons.groups,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            widget.existingPostData != null
                                ? (_postType == 'sales' ? 'Editar anúncio' : 'Editar post')
                                : (_postType == 'sales'
                                    ? 'Quero oferecer um\nproduto ou serviço'
                                    : (_postType == 'musician'
                                        ? 'Quero me juntar\na uma banda'
                                        : 'Quero encontrar\num músico')),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Renderização condicional baseada no tipo
                  if (_postType == 'sales') 
                    ..._buildSalesFields()
                  else
                    ..._buildMusicianBandFields(),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ====================================================================
  // SALES FIELDS
  // ====================================================================
  
  List<Widget> _buildSalesFields() {
    return [
      // 1. Fotos (obrigatória)
      const Text(
        'Fotos do produto/serviço *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      PhotoCarouselPicker(
        photoPaths: _photoPaths,
        onPhotosChanged: (paths) => setState(() => _photoPaths = paths),
        maxPhotos: 4,
      ),
      const Divider(height: 48, thickness: 0.5),

      // 2. Título do anúncio
      const Text(
        'Título do anúncio *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _titleController,
        maxLength: 80,
        decoration: InputDecoration(
          hintText: 'Ex: Estúdio de gravação profissional',
          counterText: '${_titleController.text.length}/80',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Título é obrigatório' : null,
        onChanged: (_) => setState(() {}),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 3. Descrição
      const Text(
        'Descrição *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _messageController,
        maxLength: 600,
        maxLines: 6,
        decoration: InputDecoration(
          hintText: 'Descreva o que você está oferecendo...',
          counterText: '${_messageController.text.length}/600',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Descrição é obrigatória' : null,
        onChanged: (_) => setState(() {}),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 4. Tipo do anúncio
      const Text(
        'Tipo do anúncio *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _salesTypeOptions.map((type) {
          final isSelected = _salesType == type;
          return FilterChip(
            label: Text(type),
            selected: isSelected,
            onSelected: (selected) => setState(() => _salesType = type),
            backgroundColor: Theme.of(context).cardColor,
            selectedColor: AppColors.primary.withValues(alpha: 0.1),
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
      const Divider(height: 48, thickness: 0.5),

      // 5. Preço
      const Text(
        'Preço *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _priceController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixText: 'R\$ ',
          hintText: '0,00',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _CurrencyInputFormatter(),
        ],
        validator: (v) => v == null || v.isEmpty ? 'Preço é obrigatório' : null,
      ),
      const Divider(height: 48, thickness: 0.5),

      // 6. Desconto
      const Text(
        'Desconto (opcional)',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: FilterChip(
              label: const Text('Sem desconto'),
              selected: _discountMode == 'none',
              onSelected: (selected) => setState(() {
                _discountMode = 'none';
                _discountController.clear();
              }),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: const Text('% desconto'),
              selected: _discountMode == 'percentage',
              onSelected: (selected) => setState(() {
                _discountMode = 'percentage';
                _discountController.clear();
              }),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilterChip(
              label: const Text('R\$ off'),
              selected: _discountMode == 'fixed',
              onSelected: (selected) => setState(() {
                _discountMode = 'fixed';
                _discountController.clear();
              }),
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
      if (_discountMode != 'none') ...[
        const SizedBox(height: 12),
        TextFormField(
          controller: _discountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: _discountMode == 'percentage' ? '' : 'R\$ ',
            suffixText: _discountMode == 'percentage' ? '%' : '',
            hintText: _discountMode == 'percentage' ? '0' : '0,00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          inputFormatters: _discountMode == 'percentage'
              ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)]
              : [FilteringTextInputFormatter.digitsOnly, _CurrencyInputFormatter()],
        ),
      ],
      const Divider(height: 48, thickness: 0.5),

      // 7. Valor final
      const Text(
        'Valor final',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'R\$ ${_calculatedFinalPrice.toStringAsFixed(2).replaceAll('.', ',')}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (_discountMode != 'none' && _discountController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _discountMode == 'percentage'
                      ? '-${_discountController.text}%'
                      : 'R\$ ${_discountController.text} off',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 8. Validade da promoção
      const Text(
        'Validade da promoção *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 8),
      Text(
        'Datas desabilitadas ficam acinzentadas no calendário',
        style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _promoStartDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  helpText: 'Data de início (até 30 dias)',
                  cancelText: 'Cancelar',
                  confirmText: 'OK',
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() {
                    _promoStartDate = date;
                    // Ajusta data de término automaticamente se necessário
                    if (_promoEndDate.isBefore(date) || _promoEndDate.isAfter(date.add(const Duration(days: 30)))) {
                      _promoEndDate = date.add(const Duration(days: 30));
                    }
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text('De: ${_promoStartDate.day}/${_promoStartDate.month}/${_promoStartDate.year.toString().substring(2)}'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _promoEndDate.isAfter(_promoStartDate.add(const Duration(days: 30)))
                      ? _promoStartDate.add(const Duration(days: 30))
                      : _promoEndDate,
                  firstDate: _promoStartDate,
                  lastDate: _promoStartDate.add(const Duration(days: 30)),
                  helpText: 'Data de término (máx: 30 dias após início)',
                  cancelText: 'Cancelar',
                  confirmText: 'OK',
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) setState(() => _promoEndDate = date);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text('Até: ${_promoEndDate.day}/${_promoEndDate.month}/${_promoEndDate.year.toString().substring(2)}'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Início: até 30 dias de hoje • Término: até 30 dias após início',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
              ),
            ),
          ],
        ),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 9. Localização
      const Text(
        'Localização *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      TypeAheadField<Map<String, dynamic>>(
        controller: _locationController,
        focusNode: _locationFocusNode,
        suggestionsCallback: _fetchAddressSuggestions,
        itemBuilder: (BuildContext context, Map<String, dynamic> suggestion) {
          final address = suggestion['address'] as Map<String, dynamic>? ?? {};
          final road = (address['road'] ?? address['pedestrian'] ?? '') as String;
          final houseNumber = (address['house_number'] ?? '') as String;
          final neighbourhood = (address['neighbourhood'] ??
              address['suburb'] ??
              address['quarter'] ??
              '') as String;
          final city = (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              '') as String;
          final state = (address['state'] ?? '') as String;
          final streetLine = [road, houseNumber].where((e) => e.isNotEmpty).join(', ');
          final List<String> secondaryParts = [];
          if (neighbourhood.isNotEmpty) secondaryParts.add(neighbourhood);
          if (city.isNotEmpty) secondaryParts.add(city);
          if (state.isNotEmpty) secondaryParts.add(state);
          final secondaryLine = secondaryParts.join(' • ');
          return ListTile(
            leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
            title: Text(
              streetLine.isNotEmpty ? streetLine : (suggestion['display_name'] as String?)?.split(',').first ?? 'Localização',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: secondaryLine.isNotEmpty
                ? Text(
                    secondaryLine,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
          );
        },
        onSelected: _onAddressSelected,
        builder: (context, controller, focusNode) {
          return TextFormField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: 'Digite o endereço',
              hintText: 'Ex: Rua das Flores, São Paulo',
              prefixIcon: const Icon(Iconsax.location),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Iconsax.close_circle, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          controller.clear();
                          _selectedLocation = null;
                          _selectedCity = null;
                          _selectedNeighborhood = null;
                          _selectedState = null;
                        });
                        focusNode.unfocus();
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Localização é obrigatória';
              }
              if (_selectedLocation == null) {
                return 'Selecione uma localização da lista';
              }
              return null;
            },
          );
        },
        hideOnEmpty: true,
        hideOnLoading: false,
        hideOnError: false,
        debounceDuration: Duration.zero,
        loadingBuilder: (context) => const Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Erro ao buscar endereços: $error'),
        ),
        emptyBuilder: (context) => const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Nenhum endereço encontrado'),
        ),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 10. WhatsApp
      const Text(
        'WhatsApp para contato (opcional)',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _whatsappController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.phone),
          hintText: 'Ex: (11) 98765-4321',
          helperText: 'Clientes poderão falar diretamente no WhatsApp',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _PhoneInputFormatter(),
        ],
      ),
    ];
  }

  // ====================================================================
  // MUSICIAN/BAND FIELDS
  // ====================================================================
  
  List<Widget> _buildMusicianBandFields() {
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    
    return [
      // Disponível para
      MultiSelectField(
                    title: 'Disponível para',
                    placeholder: 'Selecione suas disponibilidades',
                    options: _availableForOptions,
                    selectedItems: _selectedAvailableFor,
                    maxSelections: 8,
                    onSelectionChanged: (values) {
                      setState(() {
                        _selectedAvailableFor
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),
                  const Divider(thickness: 0.5, height: 48),

                  // Localização
                  const Text(
                    'Localização',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TypeAheadField<Map<String, dynamic>>(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    suggestionsCallback: _fetchAddressSuggestions,
                    itemBuilder: (BuildContext context, Map<String, dynamic> suggestion) {
                      final address = suggestion['address'] as Map<String, dynamic>? ?? {};

                      // Extrai os componentes com fallback
                      final road = (address['road'] ?? address['pedestrian'] ?? '') as String;
                      final houseNumber = (address['house_number'] ?? '') as String;
                      final neighbourhood = (address['neighbourhood'] ??
                          address['suburb'] ??
                          address['quarter'] ??
                          '') as String;
                      final city = (address['city'] ??
                          address['town'] ??
                          address['village'] ??
                          address['municipality'] ??
                          '') as String;
                      final state = (address['state'] ?? '') as String;

                      // Monta a linha principal (rua + número)
                      final streetLine = [road, houseNumber].where((e) => e.isNotEmpty).join(', ');

                      // Monta a linha secundária (bairro • cidade - estado)
                      final List<String> secondaryParts = [];
                      if (neighbourhood.isNotEmpty) secondaryParts.add(neighbourhood);
                      if (city.isNotEmpty) secondaryParts.add(city);
                      if (state.isNotEmpty) secondaryParts.add(state);

                      final secondaryLine = secondaryParts.join(' • ');

                      return ListTile(
                        leading: const Icon(Icons.location_on, color: AppColors.primary, size: 20),
                        title: Text(
                          streetLine.isNotEmpty ? streetLine : (suggestion['display_name'] as String?)?.split(',').first ?? 'Localização',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: secondaryLine.isNotEmpty
                            ? Text(
                                secondaryLine,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                      );
                    },
                    onSelected: _onAddressSelected,
                    builder: (context, controller, focusNode) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Digite o endereço',
                          hintText: 'Ex: Rua das Flores, São Paulo',
                          prefixIcon: Icon(Iconsax.location),
                          suffixIcon: controller.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Iconsax.close_circle,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      controller.clear();
                                      _selectedLocation = null;
                                      _selectedCity = null;
                                      _selectedNeighborhood = null;
                                      _selectedState = null;
                                    });
                                    focusNode.unfocus();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Localização é obrigatória';
                          }
                          if (_selectedLocation == null) {
                            return 'Selecione uma localização da lista';
                          }
                          return null;
                        },
                      );
                    },
                    hideOnEmpty: true,
                    hideOnLoading: false,
                    hideOnError: false,
                    debounceDuration: Duration.zero,
                    loadingBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                    errorBuilder: (context, error) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Erro ao buscar endereços: $error'),
                    ),
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Nenhum endereço encontrado'),
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
                  const SizedBox(height: 16),

                  // Instrumentos
                  MultiSelectField(
                    title: 'Instrumentos',
                    placeholder: 'Selecione até 5 instrumentos',
                    options: _instrumentOptions,
                    selectedItems: _selectedInstruments,
                    maxSelections: maxInstruments,
                    enabled: !_isSaving,
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
                  Column(
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
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _levelOptions.map((level) {
                          final isSelected = _level == level;
                          return FilterChip(
                            label: Text(level),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _level = level;
                              });
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
                  ),
                  const Divider(height: 48, thickness: 0.5),

                  // Fotos
                  Text('Fotos (opcional, até 4)', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  PhotoCarouselPicker(
                    photoPaths: _photoPaths,
                    onPhotosChanged: (paths) => setState(() => _photoPaths = paths),
                    maxPhotos: 4,
                  ),
                  const Divider(height: 48, thickness: 0.5),

                  // Mensagem
                  Text('Mensagem', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  PostFormFields(
                    descriptionController: _messageController,
                    descriptionValidator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obrigatório'
                        : null,
                  ),
                  const Divider(height: 48, thickness: 0.5),

                  // YouTube
                  Text('YouTube (opcional)', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _youtubeController,
                    decoration: InputDecoration(
                      hintText: 'https://youtu.be/...',
                      prefixIcon: const Icon(Icons.link),
                      suffixIcon: _youtubeController.text.isEmpty
                          ? null
                          : _extractYouTubeVideoId(_youtubeController.text) !=
                                  null
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.error_outline,
                                  color: Colors.red),
                      helperText: _youtubeController.text.isNotEmpty
                          ? (_extractYouTubeVideoId(_youtubeController.text) !=
                                  null
                              ? '✓ Vídeo encontrado'
                              : '✗ URL inválida')
                          : null,
                      helperStyle: TextStyle(
                        color:
                            _extractYouTubeVideoId(_youtubeController.text) !=
                                    null
                                ? Colors.green
                                : Colors.red,
                        fontSize: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final url = v.trim();
                      final ytRegex = RegExp(
                        r'^(https?://)?(www\.)?(youtube\.com|youtu\.be)/.+',
                      );
                      if (!ytRegex.hasMatch(url)) {
                        return 'Insira um link válido do YouTube';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  // Preview do vídeo YouTube
                  if (_youtubeController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildYouTubePreview(_youtubeController.text),
                  ],
    ];
  }

  String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);

      // youtu.be format
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }

      // youtube.com formats
      if (uri.host.contains('youtube.com')) {
        if (uri.pathSegments.contains('watch')) {
          return uri.queryParameters['v'];
        } else if (uri.pathSegments.contains('embed') &&
            uri.pathSegments.length > 1) {
          return uri.pathSegments[uri.pathSegments.indexOf('embed') + 1];
        } else if (uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.last;
        }
      }
    } catch (e) {
      debugPrint('Erro ao extrair videoId: $e');
    }
    return null;
  }

  Widget _buildYouTubePreview(String url) {
    final videoId = _extractYouTubeVideoId(url);

    if (videoId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Link do YouTube inválido',
                style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                height: 200,
                color: Colors.grey.shade300,
                child: const Icon(Icons.error, size: 40, color: Colors.red),
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// INPUT FORMATTERS
// ====================================================================

/// Formatter para moeda brasileira (centavos)
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final value = int.parse(newValue.text);
    final formatted = (value / 100).toStringAsFixed(2).replaceAll('.', ',');
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formatter para telefone brasileiro
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    
    if (digits.length <= 2) {
      formatted = '($digits';
    } else if (digits.length <= 7) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2)}';
    } else if (digits.length <= 11) {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else {
      formatted = '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7, 11)}';
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
