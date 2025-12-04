import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

import 'package:core_ui/services/env_service.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:wegig_app/features/notifications/domain/services/notification_service.dart';
import 'package:wegig_app/features/post/presentation/widgets/genre_selector.dart';
import 'package:wegig_app/features/post/presentation/widgets/instrument_selector.dart';

/// Tema claro personalizado com paleta de cores definida
///
/// Define cores e configurações de tema para a página de edição de posts.
class AppThemeData {
  /// Cor primária do tema (AppColors.primary)
  static const Color primaryColor = AppColors.primary;

  /// Cor secundária do tema (AppColors.accent)
  static const Color secondaryColor = AppColors.accent;

  /// Cor de fundo (branco)
  static const Color backgroundColor = Color(0xFFFFFFFF);

  /// Cor de superfície (cinza claro)
  static const Color surfaceColor = Color(0xFFF5F5F5);

  /// Cor de texto primário
  static const Color textPrimary = Color(0xFF212121);

  /// Cor de texto secundário
  static const Color textSecondary = Color(0xFF616161);

  /// Retorna o tema claro configurado
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        color: backgroundColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textSecondary,
        labelStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        titleLarge: TextStyle(
            color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium: TextStyle(
            color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
      ),
    );
  }
}

/// Página de edição de posts existentes
///
/// Permite editar posts já criados, incluindo:
/// - Alteração de gêneros e instrumentos
/// - Upload/substituição de foto com crop
/// - Edição de localização via mapa
/// - Atualização de link do YouTube
class EditPostPage extends StatefulWidget {
  /// Construtor da página de edição
  const EditPostPage({required this.postData, super.key});

  /// Dados do post a ser editado
  final Map<String, dynamic> postData;

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _formKey = GlobalKey<FormState>();

  // Section 1
  String _postType = 'musician';

  // Section 2
  // ⚡ PERFORMANCE: _instrumentOptions movidos para InstrumentSelector.instrumentOptions

  // ⚡ PERFORMANCE: _genreOptions movidos para GenreSelector.genreOptions

  late Set<String> _selectedInstruments = {};
  late Set<String> _selectedGenres = {};

  // Musicians seeking options (for bands)
  static const List<String> _musicianTypeOptions = [
    'Pianista',
    'Violonista',
    'Violoncelista',
    'Contrabaixista',
    'Harpista',
    'Guitarrista',
    'Baixista elétrico',
    'Baterista',
    'Percussionista',
    'Saxofonista',
    'Trompetista',
    'Trombonista',
    'Flautista',
    'Clarinetista',
    'Oboísta',
    'Fagotista',
    'Tubista',
    'Trompista',
    'Violinista',
    'Violista',
    'Gaitista',
    'Acordeonista',
    'Sanfoneiro',
    'Bandolinista',
    'Banjoísta',
    'Ukulelista',
    'Sitarista',
    'Shamisenista',
    'Kotoísta',
    'Erhuísta',
    'Pipaísta',
    'Guzhenguista',
    'Berimbauísta',
    'Violão de 7 cordas',
    'Viola caipira',
    'Viola de 10 cordas',
    'Cavacoísta',
    'Pandeirista',
    'Tamborimzeira',
    'Cuíquista',
    'Marimbista',
    'Vibrafonista',
    'Xilofonista',
    'Glockenspielista',
    'Timpanista',
    'Zabumbeiro',
    'Alfaiate',
    'Organista',
    'Tecladista',
    'Thereminista',
    'Ondas Martenotista',
    'Outro',
  ];

  late Set<String> _seekingMusicians = {};

  static const List<String> _levelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Profissional',
  ];
  static const List<String> _bandLevelOptions = [
    'Em formação',
    'Ativa (ensaios regulares)',
    'Procurando membros',
    'Em turnê',
    'Em hiato',
  ];

  String _level = 'Intermediário';

  // Section 3
  final _cityController = TextEditingController();
  double _maxDistanceKm = 20;

  // Section 4
  final _messageController = TextEditingController();

  // Section 5 & 6
  String? _photoLocalPath;
  String? _photoUrl;
  final _youtubeController = TextEditingController();

  bool _isSaving = false;


  String? _name;
  String? _profilePhotoUrl;
  String? _seeking;

  // Location search (Airbnb-style address search like HomePage)
  final _locationSearchController = TextEditingController();
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _isSearchingLocation = false;
  Timer? _searchDebounce; // Timer para compatibilidade com código legado
  LatLng? _selectedLocation;
  bool _showLocationSuggestions = false;
  String? _fetchedCity;
  String? _fetchedNeighborhood;
  String? _fetchedState;
  bool _locationValidated = false;

  /// Helper para extrair ID do vídeo do YouTube de diferentes formatos de URL
  String? _extractYoutubeVideoId(String url) {
    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\?\/]+)'),
      RegExp(r'youtube\.com\/embed\/([^&\?\/]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadPostData();
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _searchDebounce?.cancel();
    _cityController.dispose();
    _messageController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  Future<void> _loadPostData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // CRITICAL: Load ACTIVE profile data for avatar, not main profile
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final activeProfileId = data['activeProfileId'] as String? ?? user.uid;

        // Se activeProfileId é o uid, usar dados do perfil principal
        if (activeProfileId == user.uid) {
          _name = (data['name'] as String?) ?? '';
          _profilePhotoUrl = data['photoUrl'] as String?;
        } else {
          // Buscar dados do perfil secundário ativo
          final profilesList = data['profiles'] as List<dynamic>?;
          if (profilesList != null) {
            try {
              final activeProfile = profilesList
                  .cast<Map<String, dynamic>>()
                  .firstWhere((p) => p['profileId'] == activeProfileId);
              _name = (activeProfile['name'] as String?) ?? '';
              _profilePhotoUrl = activeProfile['photoUrl'] as String?;
            } catch (_) {
              _name = (data['name'] as String?) ?? '';
              _profilePhotoUrl = data['photoUrl'] as String?;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('EditPostPage: Erro ao carregar dados do perfil: $e');
    }

    // Load post data
    final post = widget.postData;

    if (!mounted) return;
    setState(() {
      _postType = post['type'] as String? ?? 'musician';
      _selectedInstruments = (post['instruments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};
      _selectedGenres = (post['genres'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};
      _seekingMusicians = (post['seekingMusicians'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};
      _level = post['level'] as String? ?? 'Intermediário';
      _cityController.text = post['city'] as String? ?? '';
      _maxDistanceKm = (post['maxDistanceKm'] as num?)?.toDouble() ?? 20.0;
      _messageController.text = post['message'] as String? ?? '';
      _photoUrl = post['photoUrl'] as String?;
      _youtubeController.text = post['youtubeLink'] as String? ?? '';
      _fetchedCity = post['city'] as String?;
      _fetchedNeighborhood = post['neighborhood'] as String?;
      _fetchedState = post['state'] as String?;

      // Extract location if available
      final loc = post['location'];
      if (loc is Map<String, dynamic>) {
        // Location comes as Map from home_page.dart
        _selectedLocation = LatLng(
          (loc['latitude'] as num).toDouble(),
          (loc['longitude'] as num).toDouble(),
        );
        _locationValidated = true; // Already has valid location
        // Campo de texto será preenchido após reverse geocoding
      } else if (loc is GeoPoint) {
        // Fallback for GeoPoint format
        _selectedLocation = LatLng(loc.latitude, loc.longitude);
        _locationValidated = true;
        // Campo de texto será preenchido após reverse geocoding
      }

      // Extract seeking
      final seekingList = post['seeking'] as List<dynamic>?;
      if (seekingList != null && seekingList.isNotEmpty) {
        _seeking = seekingList.first.toString();
      }
    });

    // Se tem localização, buscar detalhes completos via reverse geocoding
    if (_selectedLocation != null) {
      _fetchLocationDetails(_selectedLocation!);
    }
  }

  Future<void> _fetchLocationDetails(LatLng location) async {
    try {
      // Tentar obter do .env, senão usar fallback
      final apiKey = EnvService.get('GOOGLE_MAPS_API_KEY') ??
          EnvService.get('GOOGLE_MAPS_API_KEY_ANDROID') ??
          'AIzaSyAXwop4LH9uEhO3uaFxr9_a1m06IWFN6Ho'; // Fallback

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${location.latitude},${location.longitude}&key=$apiKey&language=pt-BR',
      );

      debugPrint(
          '🔍 Buscando detalhes da localização: ${location.latitude}, ${location.longitude}');

      final response = await http.get(url);
      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] != 'OK') {
          debugPrint('❌ Geocoding API error: ${data['status']}');
          return;
        }

        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];

          String? neighborhood;
          String? city;
          String? state;

          final addressComponents =
              (result['address_components'] as List<dynamic>?) ?? [];
          for (final component in addressComponents) {
            final componentMap = component as Map<String, dynamic>;
            final types =
                (componentMap['types'] as List<dynamic>?)?.cast<String>() ?? [];
            if (types.contains('sublocality') ||
                types.contains('sublocality_level_1')) {
              neighborhood = componentMap['long_name'] as String?;
            } else if (types.contains('administrative_area_level_2') ||
                types.contains('locality')) {
              city = componentMap['long_name'] as String?;
            } else if (types.contains('administrative_area_level_1')) {
              state = componentMap['short_name'] as String?;
            }
          }

          debugPrint('📍 Detalhes encontrados: $neighborhood, $city, $state');

          if (mounted) {
            setState(() {
              _fetchedNeighborhood = neighborhood;
              _fetchedCity = city ?? _fetchedCity;
              _fetchedState = state;

              final formatted = formatCleanLocation(
                neighborhood: neighborhood,
                city: city,
                state: state,
                fallback: '',
              );
              if (formatted.isNotEmpty) {
                _locationSearchController.text = formatted;
                debugPrint(
                    '✅ Campo de localização atualizado: ${_locationSearchController.text}');
              } else {
                debugPrint('⚠️ Nenhum detalhe de localização para exibir');
              }
            });
          }
        } else {
          debugPrint('⚠️ Nenhum resultado encontrado');
        }
      } else {
        debugPrint('❌ Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar detalhes da localização: $e');
    }
  }

  Future<void> _showInstrumentPicker() async {
    final allOptions = List<String>.from(InstrumentSelector.instrumentOptions);
    for (final s in _selectedInstruments) {
      if (!allOptions.contains(s)) allOptions.add(s);
    }

    final tempSelected = {..._selectedInstruments};
    var search = '';
    final addController = TextEditingController();

    await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            final filtered = allOptions
                .where((e) => e.toLowerCase().contains(search.toLowerCase()))
                .toList()
              ..sort((a, b) => a.compareTo(b));
            return AlertDialog(
              title: const Text('Selecionar instrumentos'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Pesquisar...'),
                        onChanged: (v) => setStateDialog(() => search = v)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final selected = tempSelected.contains(item);
                            return CheckboxListTile(
                              value: selected,
                              title: Text(item),
                              onChanged: (v) => setStateDialog(() => v!
                                  ? tempSelected.add(item)
                                  : tempSelected.remove(item)),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: addController,
                              decoration: const InputDecoration(
                                  hintText:
                                      'Adicionar instrumento personalizado'))),
                      IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final v = addController.text.trim();
                            if (v.isNotEmpty) {
                              if (!allOptions.contains(v)) allOptions.add(v);
                              setStateDialog(() {
                                tempSelected.add(v);
                                addController.clear();
                              });
                            }
                          })
                    ])
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedInstruments = tempSelected);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar')),
              ],
            );
          });
        });
  }

  Future<void> _showGenrePicker() async {
    final allOptions = List<String>.from(GenreSelector.genreOptions);
    for (final s in _selectedGenres) {
      if (!allOptions.contains(s)) allOptions.add(s);
    }

    final tempSelected = {..._selectedGenres};
    var search = '';
    final addController = TextEditingController();

    await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            final filtered = allOptions
                .where((e) => e.toLowerCase().contains(search.toLowerCase()))
                .toList()
              ..sort((a, b) => a.compareTo(b));
            return AlertDialog(
              title: const Text('Selecionar gêneros'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Pesquisar...'),
                        onChanged: (v) => setStateDialog(() => search = v)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final selected = tempSelected.contains(item);
                            return CheckboxListTile(
                              value: selected,
                              title: Text(item),
                              onChanged: (v) => setStateDialog(() => v!
                                  ? tempSelected.add(item)
                                  : tempSelected.remove(item)),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: addController,
                              decoration: const InputDecoration(
                                  hintText: 'Adicionar gênero personalizado'))),
                      IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final v = addController.text.trim();
                            if (v.isNotEmpty) {
                              if (!allOptions.contains(v)) allOptions.add(v);
                              setStateDialog(() {
                                tempSelected.add(v);
                                addController.clear();
                              });
                            }
                          })
                    ])
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedGenres = tempSelected);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar')),
              ],
            );
          });
        });
  }

  Future<void> _showSeekingMusiciansPicker() async {
    final allOptions = List<String>.from(_musicianTypeOptions);
    for (final s in _seekingMusicians) {
      if (!allOptions.contains(s)) allOptions.add(s);
    }

    final tempSelected = {..._seekingMusicians};
    var search = '';
    final addController = TextEditingController();

    await showDialog<void>(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
            final filtered = allOptions
                .where((e) => e.toLowerCase().contains(search.toLowerCase()))
                .toList()
              ..sort((a, b) => a.compareTo(b));
            return AlertDialog(
              title: const Text('Músicos Procurados'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Pesquisar...'),
                        onChanged: (v) => setStateDialog(() => search = v)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final item = filtered[idx];
                            final selected = tempSelected.contains(item);
                            return CheckboxListTile(
                              value: selected,
                              title: Text(item),
                              onChanged: (v) => setStateDialog(() => v!
                                  ? tempSelected.add(item)
                                  : tempSelected.remove(item)),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: TextField(
                              controller: addController,
                              decoration: const InputDecoration(
                                  hintText: 'Adicionar tipo personalizado'))),
                      IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            final v = addController.text.trim();
                            if (v.isNotEmpty) {
                              if (!allOptions.contains(v)) allOptions.add(v);
                              setStateDialog(() {
                                tempSelected.add(v);
                                addController.clear();
                              });
                            }
                          })
                    ])
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar')),
                ElevatedButton(
                    onPressed: () {
                      setState(() => _seekingMusicians = tempSelected);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Salvar')),
              ],
            );
          });
        });
  }

  ImageProvider<Object> _createImageProvider(String pathOrUrl) {
    if (pathOrUrl.startsWith('http')) {
      return NetworkImage(pathOrUrl);
    }

    var candidate = pathOrUrl;
    if (candidate.startsWith('file://')) {
      try {
        candidate = Uri.parse(candidate).toFilePath();
      } catch (_) {
        candidate = candidate.replaceFirst('file://', '');
      }
    }

    final f = File(candidate);
    if (f.existsSync()) {
      return FileImage(f);
    }

    return const AssetImage('assets/avatar_placeholder.png');
  }

  Future<void> _pickAndCropImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 95,
    );

    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Ajustar foto',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Ajustar foto',
          aspectRatioLockEnabled: true,
        ),
      ],
    );

    if (cropped != null) {
      setState(() {
        _photoLocalPath = cropped.path;
        _photoUrl = null;
      });
    }
  }

  Future<void> _updatePost() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar instrumentos: banda procurando banda não precisa informar instrumentos
    final isBandSeekingBand = _postType == 'band' &&
        !_seekingMusicians.any((m) => m.toLowerCase().contains('músico'));

    if (_selectedInstruments.isEmpty && !isBandSeekingBand) {
      AppSnackBar.showWarning(
        context,
        'Selecione pelo menos um instrumento',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'Usuário não autenticado';

      final postId = widget.postData['postId'] as String?;
      if (postId == null || postId.isEmpty) throw 'ID do post não encontrado';

      var photoUrl = _photoUrl;

      // Se trocou a foto → faz upload da nova e deleta a antiga
      if (_photoLocalPath != null) {
        // Deleta foto antiga (se existir)
        if (photoUrl != null && photoUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(photoUrl).delete();
          } catch (_) {}
        }

        final fileName =
            '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref =
            FirebaseStorage.instance.ref().child('posts').child(fileName);
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          File(_photoLocalPath!).absolute.path,
          '${_photoLocalPath!}_compressed.jpg',
          quality: 85,
          minWidth: 1080,
        );
        await ref.putFile(File(compressedFile?.path ?? _photoLocalPath!));
        photoUrl = await ref.getDownloadURL();
      }

      // YouTube link
      String? youtubeLink;
      final videoId = _extractYoutubeVideoId(_youtubeController.text.trim());
      if (videoId != null) {
        youtubeLink = 'https://www.youtube.com/watch?v=$videoId';
      }

      // Atualiza o post no Firestore com TODOS os campos necessários
      await FirebaseFirestore.instance.collection('posts').doc(postId).update({
        'type': _postType,
        'seekingMusicians':
            _postType == 'band' ? _seekingMusicians.toList() : <String>[],
        'instruments': _selectedInstruments.toList(),
        'genres': _selectedGenres.toList(),
        'level': _level,
        'message': _messageController.text.trim(),
        'photoUrl': photoUrl,
        'activeProfileName': _name ?? '',
        'activeProfilePhotoUrl': _profilePhotoUrl ?? '',
        'youtubeLink': youtubeLink,
        'city': _fetchedCity ?? _cityController.text.trim(),
        'neighborhood': _fetchedNeighborhood ?? '',
        'state': _fetchedState ?? '',
        'location': _selectedLocation != null
            ? GeoPoint(
                _selectedLocation!.latitude, _selectedLocation!.longitude)
            : (widget.postData['location'] is GeoPoint
                ? widget.postData['location']
                : FieldValue.delete()),
        'maxDistanceKm': _maxDistanceKm,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Post atualizado com sucesso!',
        );

        await _notifyInterestFollowers(postId);

        Navigator.of(context).pop(true); // sinaliza que foi atualizado
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Erro ao atualizar: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _notifyInterestFollowers(String postId) async {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      final notificationService = container.read(notificationServiceProvider);

      await notificationService.createInterestNewPostNotifications(
        postId: postId,
        authorName: _name ?? '',
        genres: _selectedGenres.toList(),
        instruments: _selectedInstruments.toList(),
        seeking: _postType == 'band'
            ? _seekingMusicians.toList()
            : const <String>[],
        city: _fetchedCity ?? _cityController.text.trim(),
      );

      debugPrint('EditPostPage: ✅ Notificações de interesse atualizadas para $postId');
    } catch (e) {
      debugPrint('EditPostPage: ❌ Erro ao criar notificações de interesse: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.lightTheme; // Usar tema personalizado

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: AppThemeData.backgroundColor,
        appBar: AppBar(
          title: const Text('Editar Post'),
          elevation: 0,
        ),
        // Barra de progresso global no topo durante salvamento
        body: Stack(
          children: [
            SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Barra de progresso linear no topo
                    if (_isSaving)
                      const LinearProgressIndicator(
                        backgroundColor: Color(0xFFE0E0E0),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),

                    // Conteúdo scrollável
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header com perfil do usuário
                            Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor: AppThemeData.primaryColor
                                          .withValues(alpha: 0.1),
                                      backgroundImage:
                                          (_profilePhotoUrl != null &&
                                                  _profilePhotoUrl!.isNotEmpty)
                                              ? _createImageProvider(
                                                  _profilePhotoUrl!)
                                              : null,
                                      child: (_profilePhotoUrl == null ||
                                              _profilePhotoUrl!.isEmpty)
                                          ? const Icon(Iconsax.user,
                                              size: 32,
                                              color: AppThemeData.primaryColor)
                                          : null,
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _name ?? 'Carregando...',
                                            style: theme.textTheme.titleLarge,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Editando seu post',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: O que você busca
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.secondaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Iconsax.search_normal,
                                            color: AppThemeData.secondaryColor,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('O que você busca?',
                                            style: theme.textTheme.titleLarge),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Radio<String>(
                                        value: 'musician',
                                        groupValue:
                                            _seeking, // groupValue ainda é o padrão correto para Radio
                                        onChanged: (v) => setState(() =>
                                            _seeking =
                                                (_seeking == v ? null : v)),
                                        activeColor: AppThemeData.primaryColor,
                                      ),
                                      title: const Text('Músico'),
                                      subtitle: const Text(
                                          'Procuro um músico para tocar junto'),
                                      onTap: () => setState(() => _seeking =
                                          (_seeking == 'musician'
                                              ? null
                                              : 'musician')),
                                    ),
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Radio<String>(
                                        value: 'band',
                                        groupValue:
                                            _seeking, // groupValue ainda é o padrão correto para Radio
                                        onChanged: (v) => setState(() =>
                                            _seeking =
                                                (_seeking == v ? null : v)),
                                        activeColor: AppThemeData.primaryColor,
                                      ),
                                      title: const Text('Banda'),
                                      subtitle: const Text(
                                          'Procuro uma banda para me juntar'),
                                      onTap: () => setState(() => _seeking =
                                          (_seeking == 'band' ? null : 'band')),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: Instrumentos (com ícone 🎸)
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text('🎸',
                                              style: TextStyle(fontSize: 24)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _postType == 'musician'
                                              ? 'Meus instrumentos'
                                              : 'Instrumentos que procuramos',
                                          style: theme.textTheme.titleLarge,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // AnimatedSwitcher para animações suaves
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Wrap(
                                        key: ValueKey(
                                            _selectedInstruments.length),
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ..._selectedInstruments.map((i) =>
                                              Chip(
                                                label: Text(i),
                                                deleteIcon: const Icon(
                                                    Icons.close,
                                                    size: 18),
                                                onDeleted: () => setState(() =>
                                                    _selectedInstruments
                                                        .remove(i)),
                                                backgroundColor: AppThemeData
                                                    .primaryColor
                                                    .withValues(alpha: 0.1),
                                                labelStyle: const TextStyle(
                                                    color: AppThemeData
                                                        .primaryColor),
                                              )),
                                          ActionChip(
                                            label: const Text('+ Adicionar'),
                                            onPressed: _showInstrumentPicker,
                                            backgroundColor:
                                                AppThemeData.surfaceColor,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_selectedInstruments.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        child: Text(
                                          'Selecione pelo menos um instrumento',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: Gêneros musicais (com ícone 🎵)
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.secondaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text('🎵',
                                              style: TextStyle(fontSize: 24)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Gêneros Musicais',
                                                  style: theme
                                                      .textTheme.titleLarge),
                                              Text(
                                                'Máximo 3 gêneros',
                                                style: theme
                                                    .textTheme.bodyMedium
                                                    ?.copyWith(fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // AnimatedSwitcher para chips
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Wrap(
                                        key: ValueKey(_selectedGenres.length),
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ..._selectedGenres.map((g) => Chip(
                                                label: Text(g),
                                                deleteIcon: const Icon(
                                                    Icons.close,
                                                    size: 18),
                                                onDeleted: () => setState(() =>
                                                    _selectedGenres.remove(g)),
                                                backgroundColor: AppThemeData
                                                    .secondaryColor
                                                    .withValues(alpha: 0.1),
                                                labelStyle: const TextStyle(
                                                    color: AppThemeData
                                                        .secondaryColor),
                                              )),
                                          if (_selectedGenres.length < 3)
                                            ActionChip(
                                              label: const Text('+ Adicionar'),
                                              onPressed: _showGenrePicker,
                                              backgroundColor:
                                                  AppThemeData.surfaceColor,
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Validação dinâmica
                                    if (_selectedGenres.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          '⚠️ Você selecionou ${_selectedGenres.length} gêneros. Remova ${_selectedGenres.length - 3} antes de salvar.',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Músicos procurados (only for bands)
                            if (_postType == 'band')
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppThemeData.primaryColor
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text('👥',
                                                style: TextStyle(fontSize: 24)),
                                          ),
                                          const SizedBox(width: 12),
                                          Text('Músicos Procurados',
                                              style:
                                                  theme.textTheme.titleLarge),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          ..._seekingMusicians.map((m) => Chip(
                                                label: Text(m),
                                                deleteIcon: const Icon(
                                                    Icons.close,
                                                    size: 18),
                                                onDeleted: () => setState(() =>
                                                    _seekingMusicians
                                                        .remove(m)),
                                              )),
                                          ActionChip(
                                            label: const Text('+ Adicionar'),
                                            onPressed:
                                                _showSeekingMusiciansPicker,
                                            backgroundColor:
                                                AppThemeData.surfaceColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Nível
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Nível',
                                        style: theme.textTheme.titleMedium),
                                    const SizedBox(height: 8),
                                    Builder(builder: (context) {
                                      final options = (_seeking == 'band')
                                          ? _bandLevelOptions
                                          : _levelOptions;
                                      final dropdownValue =
                                          (options.contains(_level))
                                              ? _level
                                              : null;
                                      return DropdownButtonFormField<String>(
                                        value: dropdownValue,
                                        decoration: InputDecoration(
                                          labelText: 'Selecione o nível',
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                          filled: true,
                                          fillColor: AppThemeData.surfaceColor,
                                        ),
                                        items: options
                                            .map((o) => DropdownMenuItem(
                                                value: o, child: Text(o)))
                                            .toList(),
                                        onChanged: (v) =>
                                            setState(() => _level = v ?? ''),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: Localização (com ícone 📍)
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text('📍',
                                              style: TextStyle(fontSize: 24)),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('Localização',
                                            style: theme.textTheme.titleLarge),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Material(
                                      elevation: 1,
                                      borderRadius: BorderRadius.circular(12),
                                      child: TextField(
                                        controller: _locationSearchController,
                                        decoration: InputDecoration(
                                          hintText:
                                              'Buscar endereço do ensaio/vaga...',
                                          hintStyle: TextStyle(
                                              color: AppThemeData.textSecondary
                                                  .withValues(alpha: 0.6)),
                                          prefixIcon: const Icon(Icons.search,
                                              color: AppThemeData.primaryColor),
                                          suffixIcon: _isSearchingLocation
                                              ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Color(
                                                                  0xFFE47911)),
                                                    ),
                                                  ),
                                                )
                                              : _locationSearchController
                                                      .text.isNotEmpty
                                                  ? IconButton(
                                                      icon: const Icon(
                                                          Iconsax.close_circle),
                                                      color: AppThemeData
                                                          .textSecondary,
                                                      onPressed: () {
                                                        setState(() {
                                                          _locationSearchController
                                                              .clear();
                                                          _locationSuggestions =
                                                              [];
                                                          _showLocationSuggestions =
                                                              false;
                                                          _selectedLocation =
                                                              null;
                                                          _cityController
                                                              .clear();
                                                          _fetchedCity = null;
                                                          _fetchedNeighborhood =
                                                              null;
                                                          _fetchedState = null;
                                                          _locationValidated =
                                                              false;
                                                        });
                                                      },
                                                    )
                                                  : _locationValidated
                                                      ? const Icon(
                                                          Iconsax.tick_circle,
                                                          color: Colors.green)
                                                      : null,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: AppThemeData.surfaceColor,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 14),
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedLocation = null;
                                            _locationValidated = false;
                                            _showLocationSuggestions =
                                                value.length >= 3;
                                          });

                                          // Debounce search
                                          _searchDebounce?.cancel();
                                          if (value.length >= 3) {
                                            _searchDebounce = Timer(
                                                const Duration(
                                                    milliseconds: 500),
                                                () async {
                                              setState(() =>
                                                  _isSearchingLocation = true);

                                              try {
                                                final query =
                                                    Uri.encodeComponent(
                                                        '$value, Brasil');
                                                final uri = Uri.parse(
                                                    'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1');
                                                final response = await http
                                                    .get(uri, headers: {
                                                  'User-Agent':
                                                      'to_sem_banda_app'
                                                });

                                                if (response.statusCode ==
                                                    200) {
                                                  final data = json
                                                      .decode(response.body);
                                                  if (data is List) {
                                                    setState(() {
                                                      _locationSuggestions =
                                                          data.map((item) {
                                                        return {
                                                          'display_name': item[
                                                                  'display_name']
                                                              .toString(),
                                                          'lat': double.tryParse(
                                                                  item['lat']
                                                                      .toString()) ??
                                                              0.0,
                                                          'lon': double.tryParse(
                                                                  item['lon']
                                                                      .toString()) ??
                                                              0.0,
                                                          'city': item[
                                                                      'address']
                                                                  ?['city'] ??
                                                              item['address']
                                                                  ?['town'] ??
                                                              item['address']?[
                                                                  'village'] ??
                                                              '',
                                                          'neighbourhood': item[
                                                                      'address']
                                                                  ?[
                                                                  'neighbourhood'] ??
                                                              item['address']
                                                                  ?['suburb'] ??
                                                              '',
                                                          'state': item[
                                                                      'address']
                                                                  ?['state'] ??
                                                              '',
                                                        };
                                                      }).toList();
                                                    });
                                                  }
                                                }
                                              } catch (e) {
                                                debugPrint(
                                                    'Erro ao buscar localização: $e');
                                              } finally {
                                                if (mounted) {
                                                  setState(() =>
                                                      _isSearchingLocation =
                                                          false);
                                                }
                                              }
                                            });
                                          } else {
                                            setState(() {
                                              _locationSuggestions = [];
                                              _showLocationSuggestions = false;
                                            });
                                          }
                                        },
                                      ),
                                    ),

                                    // Location suggestions
                                    if (_showLocationSuggestions &&
                                        _locationSuggestions.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(top: 12),
                                        constraints: const BoxConstraints(
                                            maxHeight: 200),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppThemeData.primaryColor
                                                  .withValues(alpha: 0.3)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppThemeData.primaryColor
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          itemCount:
                                              _locationSuggestions.length,
                                          separatorBuilder: (context, index) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final suggestion =
                                                _locationSuggestions[index];
                                            return ListTile(
                                              leading: const Icon(
                                                  Iconsax.location,
                                                  color: AppThemeData
                                                      .primaryColor),
                                              title: Text(
                                                (suggestion['display_name']
                                                        as String?) ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppThemeData
                                                        .textPrimary),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              onTap: () {
                                                final lat =
                                                    (suggestion['lat'] as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final lon =
                                                    (suggestion['lon'] as num?)
                                                            ?.toDouble() ??
                                                        0.0;
                                                final city = (suggestion['city']
                                                        as String?) ??
                                                    '';
                                                final neighbourhood =
                                                    suggestion['neighbourhood']
                                                        as String?;
                                                final state =
                                                    suggestion['state']
                                                        as String?;

                                                setState(() {
                                                  _locationSearchController
                                                      .text = (suggestion[
                                                              'display_name']
                                                          as String?) ??
                                                      '';
                                                  _selectedLocation =
                                                      LatLng(lat, lon);
                                                  _showLocationSuggestions =
                                                      false;
                                                  _locationSuggestions = [];
                                                  _cityController.text = city;
                                                  _fetchedCity = city;
                                                  _fetchedNeighborhood =
                                                      neighbourhood;
                                                  _fetchedState = state;
                                                  _locationValidated = true;
                                                });

                                                debugPrint(
                                                    'EditPostPage: localização selecionada: $city, lat=$lat, lng=$lon');
                                              },
                                            );
                                          },
                                        ),
                                      ),

                                    // Validated location display
                                    if (_locationValidated &&
                                        (_fetchedCity != null ||
                                            _fetchedNeighborhood != null))
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.green.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Iconsax.tick_circle,
                                                  color: Colors.green.shade700,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  formatCleanLocation(
                                                    neighborhood:
                                                        _fetchedNeighborhood,
                                                    city: _fetchedCity,
                                                    state: _fetchedState,
                                                    fallback:
                                                        'Localização validada',
                                                  ),
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Colors.green.shade900,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // Warning when location not selected
                                    if (!_locationValidated &&
                                        _locationSearchController.text.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.orange.shade300),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(Iconsax.info_circle,
                                                  color: Colors.orange.shade700,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Digite o endereço do ensaio/vaga e selecione uma opção da lista',
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors
                                                          .orange.shade900),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                    const SizedBox(height: 16),

                                    // Slider de distância
                                    Text(
                                      'Ensaios em até ${_maxDistanceKm.toInt()} km desta localização',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600),
                                    ),
                                    SliderTheme(
                                      data: SliderThemeData(
                                        activeTrackColor:
                                            AppThemeData.primaryColor,
                                        inactiveTrackColor: AppThemeData
                                            .primaryColor
                                            .withValues(alpha: 0.2),
                                        thumbColor: AppThemeData.primaryColor,
                                        overlayColor: AppThemeData.primaryColor
                                            .withValues(alpha: 0.2),
                                        valueIndicatorColor:
                                            AppThemeData.primaryColor,
                                      ),
                                      child: Slider(
                                        min: 5,
                                        max: 80,
                                        divisions: 15,
                                        value: _maxDistanceKm,
                                        label: '${_maxDistanceKm.toInt()} km',
                                        onChanged: (v) =>
                                            setState(() => _maxDistanceKm = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: Mensagem
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.secondaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Iconsax.message,
                                              color:
                                                  AppThemeData.secondaryColor,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Mensagem',
                                                  style: theme
                                                      .textTheme.titleLarge),
                                              Text('Máximo 240 caracteres',
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _messageController,
                                      maxLength: 240,
                                      minLines: 3,
                                      maxLines: 6,
                                      style: const TextStyle(
                                          color: AppThemeData.textPrimary),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Escreva uma mensagem curta sobre a vaga/procura...',
                                        hintStyle: TextStyle(
                                            color: AppThemeData.textSecondary
                                                .withValues(alpha: 0.6)),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                              color: AppThemeData.surfaceColor),
                                        ),
                                        filled: true,
                                        fillColor: AppThemeData.surfaceColor,
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Escreva uma mensagem'
                                              : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: Foto
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Iconsax.camera,
                                              color: AppThemeData.primaryColor,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Text('Foto (opcional)',
                                            style: theme.textTheme.titleLarge),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: _pickAndCropImage,
                                      child: Container(
                                        width: double.infinity,
                                        height: 180,
                                        decoration: BoxDecoration(
                                          color: AppThemeData.surfaceColor,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppThemeData.primaryColor
                                                  .withValues(alpha: 0.3),
                                              width: 2),
                                        ),
                                        child: _photoLocalPath != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: Image.file(
                                                    File(_photoLocalPath!),
                                                    fit: BoxFit.cover),
                                              )
                                            : (_photoUrl != null &&
                                                    _photoUrl!.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    child: CachedNetworkImage(
                                                      imageUrl: _photoUrl!,
                                                      fit: BoxFit.cover,
                                                      memCacheWidth: 640,
                                                      memCacheHeight: 480,
                                                      placeholder:
                                                          (context, url) =>
                                                              const ColoredBox(
                                                        color: AppThemeData
                                                            .surfaceColor,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            valueColor:
                                                                AlwaysStoppedAnimation<
                                                                        Color>(
                                                                    Color(
                                                                        0xFFE47911)),
                                                          ),
                                                        ),
                                                      ),
                                                      errorWidget: (context,
                                                              url, error) =>
                                                          const ColoredBox(
                                                        color: AppThemeData
                                                            .surfaceColor,
                                                        child: Icon(
                                                            Iconsax.danger,
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  )
                                                : Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Iconsax.camera,
                                                          size: 48,
                                                          color: AppThemeData
                                                              .textSecondary
                                                              .withValues(
                                                                  alpha: 0.5)),
                                                      const SizedBox(height: 8),
                                                      Text(
                                                          'Toque para adicionar foto',
                                                          style: theme.textTheme
                                                              .bodyMedium),
                                                    ],
                                                  )),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Card: YouTube com pré-visualização
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Iconsax.play_circle,
                                              color: Colors.red,
                                              size: 24),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('YouTube',
                                                  style: theme
                                                      .textTheme.titleLarge),
                                              Text(
                                                  'Adicione um vídeo (opcional)',
                                                  style: theme
                                                      .textTheme.bodyMedium
                                                      ?.copyWith(fontSize: 12)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _youtubeController,
                                      style: const TextStyle(
                                          color: AppThemeData.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'https://youtu.be/...',
                                        hintStyle: TextStyle(
                                            color: AppThemeData.textSecondary
                                                .withValues(alpha: 0.6)),
                                        prefixIcon: const Icon(Iconsax.link,
                                            color: AppThemeData.primaryColor),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: AppThemeData.surfaceColor,
                                      ),
                                      onChanged: (_) => setState(
                                          () {}), // Recarrega para mostrar preview
                                    ),
                                    // Pré-visualização do thumbnail do YouTube
                                    if (_youtubeController.text.isNotEmpty)
                                      Builder(
                                        builder: (context) {
                                          final videoId =
                                              _extractYoutubeVideoId(
                                                  _youtubeController.text);
                                          if (videoId != null) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 12),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: Colors.red
                                                          .withValues(
                                                              alpha: 0.3)),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      CachedNetworkImage(
                                                        imageUrl:
                                                            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                                                        width: double.infinity,
                                                        height: 150,
                                                        fit: BoxFit.cover,
                                                        memCacheWidth: 640,
                                                        memCacheHeight: 360,
                                                        placeholder:
                                                            (context, url) =>
                                                                Container(
                                                          height: 150,
                                                          color: AppThemeData
                                                              .surfaceColor,
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                          Color>(
                                                                      Color(
                                                                          0xFFE47911)),
                                                            ),
                                                          ),
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Container(
                                                          height: 150,
                                                          color: AppThemeData
                                                              .surfaceColor,
                                                          child: const Center(
                                                            child: Icon(
                                                                Icons
                                                                    .error_outline,
                                                                color:
                                                                    Colors.red,
                                                                size: 48),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.6),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                            Iconsax.play,
                                                            color: Colors.white,
                                                            size: 40),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Espaço extra para o botão fixo não sobrepor conteúdo
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botão fixo no rodapé
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  top: false,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _updatePost,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppThemeData.primaryColor,
                      disabledBackgroundColor:
                          AppThemeData.primaryColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'ATUALIZAR POST',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
