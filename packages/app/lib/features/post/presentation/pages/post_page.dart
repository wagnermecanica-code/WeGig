import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/post_result.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:wegig_app/features/post/domain/models/post_form_input.dart';
import 'package:wegig_app/features/post/presentation/providers/post_providers.dart';
import 'package:wegig_app/features/post/presentation/widgets/available_for_selector.dart';
import 'package:wegig_app/features/post/presentation/widgets/post_photo_picker.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

/// Navega para a página de criação de post
void showPostModal(BuildContext context, String postType) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => PostPage(postType: postType),
    ),
  );
}

/// Navega para a página de edição de post
void showEditPostModal(BuildContext context, Map<String, dynamic> postData) {
  Navigator.of(context).push(
    MaterialPageRoute(
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
  String? _localPhotoPath;
  String? _remotePhotoUrl;
  bool _isSaving = false;

  // === Limites e opções ===
  static const int maxInstruments = 5;
  static const int maxGenres = 5;

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

  @override
  void initState() {
    super.initState();
    _postType = widget.postType;
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

    // Foto (URL existente)
    if (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) {
      setState(() {
        _remotePhotoUrl = data['photoUrl'] as String?;
        _localPhotoPath = null;
      });
    }
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

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      debugPrint('📷 PostPage: Imagem selecionada: ${picked.path}');

      // Comprimir imagem antes de salvar
      final tempDir = Directory.systemTemp;
      final targetPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_post.jpg';

      debugPrint('📷 PostPage: Comprimindo imagem...');
      final compressed = await FlutterImageCompress.compressAndGetFile(
        picked.path,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressed == null) {
        debugPrint('⚠️ PostPage: Falha na compressão, usando imagem original');
        setState(() {
          _localPhotoPath = picked.path;
          _remotePhotoUrl = null;
        });
      } else {
        final compressedSize = await compressed.length();
        debugPrint(
            '✅ PostPage: Imagem comprimida: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        setState(() {
          _localPhotoPath = compressed.path;
          _remotePhotoUrl = null;
        });
      }
    } catch (e) {
      debugPrint('❌ PostPage: Erro ao selecionar/comprimir imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao processar imagem. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _localPhotoPath = null;
      _remotePhotoUrl = null;
    });
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Preencha todos os campos obrigatórios.', isError: true);
      return;
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
        content: _messageController.text.trim(),
        location: location,
        city: city,
        neighborhood: _selectedNeighborhood,
        state: _selectedState,
        level: _level,
        genres: _selectedGenres.toList(),
        selectedInstruments: _selectedInstruments.toList(),
        availableFor: _selectedAvailableFor.toList(),
        youtubeLink: _youtubeController.text.trim().isEmpty
            ? null
            : _youtubeController.text.trim(),
        localPhotoPath: _localPhotoPath,
        existingPhotoUrl: _remotePhotoUrl,
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
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 28),
          tooltip: 'Fechar',
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
              tooltip: 'Publicar',
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
                                ? 'Editar post'
                                : (_postType == 'musician'
                                    ? 'Quero me juntar\na uma banda'
                                    : 'Quero encontrar\num músico'),
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

                  // Disponível para (lista suspensa)
                  Text('Disponível para', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  FormField<Set<String>>(
                    validator: (_) => _selectedAvailableFor.isEmpty
                        ? 'Selecione pelo menos uma opção'
                        : null,
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AvailableForSelector(
                            options: _availableForOptions,
                            selectedValues: _selectedAvailableFor,
                            onToggle: (value) {
                              setState(() {
                                if (_selectedAvailableFor.contains(value)) {
                                  _selectedAvailableFor.remove(value);
                                } else {
                                  _selectedAvailableFor.add(value);
                                }
                              });
                              state.didChange(_selectedAvailableFor);
                            },
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                state.errorText!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const Divider(thickness: 0.5, height: 48),

                  // Onde (Localização)
                  Text('Onde', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TypeAheadField<Map<String, dynamic>>(
                    controller: _locationController,
                    focusNode: _locationFocusNode,
                    suggestionsCallback: _fetchAddressSuggestions,
                    builder: (context, controller, focusNode) {
                      return TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText:
                              'Buscar localização (cidade, bairro, endereço...)',
                          prefixIcon:
                              const Icon(Icons.place, color: AppColors.primary),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (v) => _selectedLocation == null
                            ? 'Selecione uma localização'
                            : null,
                      );
                    },
                    itemBuilder: (context, suggestion) {
                      return ListTile(
                        leading: const Icon(Icons.location_on,
                            color: AppColors.primary),
                        title: Text(
                          (suggestion['display_name'] as String?) ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    },
                    onSelected: _onAddressSelected,
                    emptyBuilder: (context) => const Padding(
                      padding: EdgeInsets.all(8),
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
                    enabled: !_isSaving,
                    onSelectionChanged: (values) {
                      setState(() {
                        _selectedGenres
                          ..clear()
                          ..addAll(values);
                      });
                    },
                  ),
                  const Divider(thickness: 0.5, height: 48),

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
                  Text('Nível', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _level,
                    items: _levelOptions
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _level = value ?? _level),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 48, thickness: 0.5),

                  // Foto
                  Text('Foto (opcional)', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  PostPhotoPicker(
                    localPhotoPath: _localPhotoPath,
                    remotePhotoUrl: _remotePhotoUrl,
                    onPickPhoto: _pickPhoto,
                    onRemovePhoto: _removePhoto,
                  ),
                  const Divider(height: 48, thickness: 0.5),

                  // Mensagem
                  Text('Mensagem', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    minLines: 2,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText: 'Conte um pouco sobre a oportunidade...',
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
                      counterText: '${_messageController.text.length}/150',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v == null || v.trim().isEmpty
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

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
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
