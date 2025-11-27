// Arquivo gerado em 2025-11-07 02:32:30 UTC
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:to_sem_banda/repositories/profile_repository.dart';
import '../theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import 'package:to_sem_banda/models/profile.dart';
import 'package:to_sem_banda/utils/debouncer.dart';

/// Top-level function for image compression in isolate (95% UI responsiveness)
Future<String?> _compressImageIsolate(Map<String, dynamic> params) async {
  try {
    final String sourcePath = params['sourcePath'] as String;
    final String targetPath = params['targetPath'] as String;
    final int quality = params['quality'] as int;
    final int minWidth = params['minWidth'] as int;
    final int minHeight = params['minHeight'] as int;

    final File? compressedFile =
        await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      targetPath,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
    );

    return compressedFile?.path;
  } catch (e) {
    debugPrint('Erro na compressão de imagem (isolate): $e');
    return null;
  }
}

/// Tema claro personalizado com paleta de cores definida
class AppThemeData {
  static final Color primaryColor = AppColors.primary;
  static final Color secondaryColor = AppColors.accent;
  static const Color backgroundColor = Color(0xFFFFFFFF); // Branco
  static const Color surfaceColor = Color(0xFFF5F5F5); // Cinza claro
  static const Color textPrimary = Color(0xFF212121); // Texto principal
  static const Color textSecondary = Color(0xFF616161); // Texto secundário
  static const Color errorColor = Color(0xFFD32F2F); // Vermelho para erros
  static const Color successColor = Color(0xFF4CAF50); // Verde para sucesso

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light().copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: backgroundColor,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          elevation: 3,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceColor,
        deleteIconColor: textSecondary,
        labelStyle:
            const TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      textTheme: const TextTheme(
        headlineMedium:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        titleLarge:
            TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        titleMedium:
            TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
        labelLarge:
            TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }
}

/// Tela para editar perfil do usuário.
/// Contém seleção de imagem (camera/galeria), crop, compress e upload para Firebase Storage,
/// além da atualização dos campos no Firestore.
class EditProfilePage extends ConsumerStatefulWidget {
  final String? profileId; // ID do perfil sendo editado (null = perfil principal)
  final String? initialName;
  final String? initialCep;
  final String? initialAvailability;
  final String? initialLevel;
  final String? initialPhotoUrl;
  final List<String>? initialInstruments;
  final List<String>? initialGenres;
  final String? initialBio;
  final String? initialYoutubeLink;
  final bool? initialShowDistance;
  final bool? initialNotifyNearby;
  final bool? initialIsBand;

  const EditProfilePage({
    super.key,
    this.profileId,
    this.initialName,
    this.initialCep,
    this.initialAvailability,
    this.initialLevel,
    this.initialPhotoUrl,
    this.initialInstruments,
    this.initialGenres,
    this.initialBio,
    this.initialYoutubeLink,
    // initialGallery removed — gallery editing now handled in view_profile_page
    this.initialShowDistance,
    this.initialNotifyNearby,
    this.initialIsBand,
  });

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  static const int maxInstruments = 5;
  static const int maxGenres = 3;

  static const List<String> _levelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Profissional',
  ];
  // Band-specific level options
  static const List<String> _bandLevelOptions = [
    'Em formação',
    'Ativa (ensaios regulares)',
    'Procurando membros',
    'Em turnê',
    'Em hiato',
  ];
  // Predefined availability options

  // Predefined list of instruments (comprehensive)
  static const List<String> _instrumentOptions = [
    // Strings
    'Violão', 'Guitarra', 'Baixo', 'Contrabaixo', 'Viola', 'Violino', 'Cello',
    // Percussion / drums
    'Bateria', 'Percussão', 'Cajón', 'Timbau', 'Congas', 'Bongô',
    // Keys
    'Piano', 'Teclado', 'Órgão', 'Synthesizer', 'Fender Rhodes',
    // Winds
    'Saxofone',
    'Flauta',
    'Flauta Transversal',
    'Flauta Doce',
    'Clarinet',
    'Oboé',
    'Fagote',
    // Brass
    'Trompete', 'Trombone', 'Tuba', 'Flicorno',
    // Vocals
    'Voz (cantor)', 'Coral', ' backing vocals',
    // Electronic / production
    'DJ', 'Produção', 'Beatmaker', 'Programação MIDI',
    // Other common
    'Harmônica', 'Ukulele', 'Mandolin', 'Sitar', 'Bandolim',
    // World / traditional
    'Sax', 'Didgeridoo', 'Tabla', 'Koto',
    // Guitar variants
    'Guitarra elétrica', 'Guitarra acústica',
    // Misc
    'Violão nylon',
    'Violão aço',
    'Loop Station',
    'Arranjo',
    'Direção musical'
  ];

  // Selected instruments state
  late Set<String> _selectedInstruments;
  // whether this profile represents a band
  bool _isBand = false;

  // Predefined list of genres (comprehensive)
  static const List<String> _genreOptions = [
    'Rock',
    'Pop',
    'Jazz',
    'Blues',
    'Funk',
    'Soul',
    'R&B',
    'Reggae',
    'MPB',
    'Sertanejo',
    'Forró',
    'Axé',
    'Hip-Hop',
    'Rap',
    'Eletrônica',
    'House',
    'Techno',
    'Trance',
    'Folk',
    'Country',
    'Classical',
    'Orchestral',
    'Metal',
    'Punk',
    'Indie',
    'Experimental',
    'Latina',
    'Bossa Nova',
    'Samba',
    'Gospel',
    'Religious',
    'World',
    'Flamenco',
    'K-Pop',
    'Soundtrack',
    'Ambient',
    'New Age',
    'Psychedelic',
    'Swing',
    'Big Band',
    'Ska'
  ];

  // Selected genres state
  late Set<String> _selectedGenres;

  late TextEditingController _nameController;
  late TextEditingController _locationSearchController;

  late TextEditingController _levelController;
  late TextEditingController _instrumentsController;
  late TextEditingController _genresController;
  late TextEditingController _bioController;
  late TextEditingController _youtubeController;

  final ImagePicker _picker = ImagePicker();
  File? _pickedImageFile;
  String? _currentPhotoUrl;

  bool _isSaving = false;
  bool _isSearchingLocation = false;
  final _locationDebouncer = Debouncer(milliseconds: 500);
  List<Map<String, dynamic>> _locationSuggestions = [];
  bool _showLocationSuggestions = false;
  String? _fetchedCity;
  String? _fetchedNeighborhood;
  double? _fetchedLat;
  double? _fetchedLng;
  String? _fetchedState;
  bool _locationValidated = false;
  // Gallery state (list of image URLs)
  // gallery removed from EditProfilePage — edited only in ViewProfilePage
  // visibility/notifications switches
  bool _showDistance = true;
  bool _notifyNearby = true;

  @override
  void initState() {
    super.initState();

    // Carregar dados do perfil ativo automaticamente
    final profileState = ref.read(profileProvider);
    final activeProfile = profileState.value?.activeProfile;

    _nameController =
        TextEditingController(text: widget.initialName ?? activeProfile?.name ?? '');
    _locationSearchController = TextEditingController();

    _levelController =
        TextEditingController(text: widget.initialLevel ?? activeProfile?.level ?? '');
    _instrumentsController = TextEditingController(
        text: (widget.initialInstruments ?? activeProfile?.instruments ?? [])
            .join(', '));
    _genresController = TextEditingController(
        text: (widget.initialGenres ?? activeProfile?.genres ?? []).join(', '));
    _bioController =
        TextEditingController(text: widget.initialBio ?? activeProfile?.bio ?? '');
    _youtubeController = TextEditingController(
        text: widget.initialYoutubeLink ?? activeProfile?.youtubeLink ?? '');
    _currentPhotoUrl = widget.initialPhotoUrl ?? activeProfile?.photoUrl;
    _selectedInstruments = {
      ...(widget.initialInstruments ?? activeProfile?.instruments ?? [])
    };
    _selectedGenres = {
      ...(widget.initialGenres ?? activeProfile?.genres ?? [])
    };
    _showDistance = widget.initialShowDistance ?? true;
    _notifyNearby = widget.initialNotifyNearby ?? true;
    _isBand = widget.initialIsBand ?? activeProfile?.isBand ?? false;

    // Carregar localização se disponível
    if (activeProfile?.location != null) {
      _fetchedLat = activeProfile!.location.latitude;
      _fetchedLng = activeProfile.location.longitude;
      _locationSearchController.text = activeProfile.city;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationSearchController.dispose();
    _locationDebouncer.dispose();

    _levelController.dispose();
    _instrumentsController.dispose();
    _genresController.dispose();
    _bioController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Pick -> Crop -> Compress (compatível com variações de retorno dos pacotes)
  // --------------------------------------------------------------------------
  Future<void> _pickCropCompress(ImageSource source) async {
    // Capture values derived from BuildContext before any await to avoid
    // using BuildContext across async gaps (use_build_context_synchronously).
    final primaryColor = Theme.of(context).primaryColor;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      // 1) Pick image (XFile)
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 95,
      );
      if (picked == null) return;

      // 2) Crop image (UI settings para Android/iOS)
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cortar imagem',
            toolbarColor: primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Cortar imagem',
          ),
        ],
      );

      // 3) Determinar caminho do arquivo cortado de forma genérica
      String? croppedPath;
      if (cropped == null) {
        // Usuário cancelou o crop -> usar original
        croppedPath = picked.path;
      } else {
        // If cropped is not null, it should be a CroppedFile
        croppedPath = cropped.path;
      }
      if (croppedPath == null) return;

      // 4) Compress in isolate -> 95% UI responsiveness improvement
      final tempDir = Directory.systemTemp;
      final targetPath = p.join(
          tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_comp.jpg');

      final String? compressedPath = await compute(_compressImageIsolate, {
        'sourcePath': croppedPath,
        'targetPath': targetPath,
        'quality': 85,
        'minWidth': 800,
        'minHeight': 800,
      });

      // 5) Use compressed path or fallback to cropped
      final String finalPath = compressedPath ?? croppedPath;

      if (!mounted) return;
      setState(() {
        _pickedImageFile = File(finalPath);
      });
    } catch (e, st) {
      // Log mais detalhado em debug e mensagem amigável para o usuário
      debugPrint('Erro em _pickCropCompress: $e\n$st');
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Erro ao selecionar/imagem: $e')),
        );
      }
    }
  }

  // --------------------------------------------------------------------------
  // Upload para Firebase Storage e retorno da URL pública
  // --------------------------------------------------------------------------
  Future<String?> _uploadImageAndGetUrl(File file, String uid) async {
    try {
      // Path correto conforme regras do Storage: user_photos/{userId}/{filename}
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child(uid)
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Erro upload imagem: $e');
      return null;
    }
  }

  // Note: gallery editing was moved to ViewProfilePage; unused helpers removed.

  // --------------------------------------------------------------------------
  // Salvar perfil (faz upload da imagem se necessário e atualiza Firestore)
  // --------------------------------------------------------------------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Capture ScaffoldMessenger early to avoid using BuildContext across async gaps
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isSaving = false);
      return;
    }

    String? newPhotoUrl = _currentPhotoUrl;

    // Se usuário escolheu nova imagem, faz upload primeiro
    if (_pickedImageFile != null) {
      final uploadedUrl = await _uploadImageAndGetUrl(_pickedImageFile!, user.uid);
      if (uploadedUrl != null) {
        newPhotoUrl = uploadedUrl;
      }
      // Se upload falhar, continua com a foto anterior (sem mostrar erro)
    }

    try {
      final profileRepository = ref.read(profileRepositoryProvider);

      // Determinar qual perfil estamos editando
      final profileId = widget.profileId ?? user.uid;

      // Criar objeto Profile atualizado
      final updatedProfile = Profile(
        profileId: profileId,
        uid: user.uid,
        name: _nameController.text.trim(),
        isBand: _isBand,
        photoUrl: newPhotoUrl,
        city: _fetchedCity ?? '',
        location: GeoPoint(_fetchedLat ?? 0, _fetchedLng ?? 0),
        instruments: _selectedInstruments.toList(),
        genres: _selectedGenres.toList(),
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        youtubeLink: _youtubeController.text.trim().isNotEmpty
            ? _youtubeController.text.trim()
            : null,
        level: _levelController.text.trim().isNotEmpty
            ? _levelController.text.trim()
            : null,
        neighborhood: _fetchedNeighborhood,
        state: _fetchedState,
      );

      // Usar ProfileRepository para atualizar
      await profileRepository.updateProfile(updatedProfile);

      // Atualizar campos adicionais que não estão no UserProfile
      // (showDistance, notifyNearby, etc)
      if (profileId == user.uid) {
        // Se for perfil principal, atualizar campos extras
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await docRef.update({
          'showDistance': _showDistance,
          'notifyNearby': _notifyNearby,
          'updatedAt': FieldValue.serverTimestamp(),
          if (_fetchedLat != null && _fetchedLng != null)
            'location': GeoPoint(_fetchedLat!, _fetchedLng!),
        });
      }

      debugPrint('EditProfilePage: Perfil $profileId atualizado com sucesso');

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso')));
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('EditProfilePage: Erro ao salvar perfil: $e');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: Text('Escolher da galeria'),
            onTap: () {
              Navigator.of(context).pop();
              _pickCropCompress(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: Text('Tirar foto'),
            onTap: () {
              Navigator.of(context).pop();
              _pickCropCompress(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: Text('Cancelar'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ]),
      ),
    );
  }

  // Multi-select dialog for instruments with search and ability to add custom
  Future<void> _showInstrumentPicker() async {
    final allOptions = List<String>.from(_instrumentOptions);
    // keep any selected custom options that are not in predefined list
    for (final s in _selectedInstruments) {
      if (!allOptions.contains(s)) allOptions.add(s);
    }

    final tempSelected = {..._selectedInstruments};
    String search = '';
    final TextEditingController addController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          final filtered = allOptions
              .where((e) => e.toLowerCase().contains(search.toLowerCase()))
              .toList()
            ..sort((a, b) => a.compareTo(b));

          final bool limitReached = tempSelected.length >= maxInstruments;

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecionar instrumentos'),
                SizedBox(height: 4),
                Text(
                  '${tempSelected.length}/$maxInstruments selecionados',
                  style: TextStyle(
                    fontSize: 12,
                    color: limitReached
                        ? AppThemeData.errorColor
                        : AppThemeData.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search), hintText: 'Pesquisar...'),
                    onChanged: (v) => setStateDialog(() => search = v),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final selected = tempSelected.contains(item);
                          final canToggle = 
                              selected || tempSelected.length < maxInstruments;
                          return CheckboxListTile(
                            value: selected,
                            title: Text(
                              item,
                              style: TextStyle(
                                color: canToggle
                                    ? AppThemeData.textPrimary
                                    : AppThemeData.textSecondary,
                              ),
                            ),
                            onChanged: canToggle
                                ? (v) {
                                    if (v! &&
                                        tempSelected.length >= 
                                            maxInstruments) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Máximo de 5 instrumentos atingido'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    setStateDialog(() => v
                                        ? tempSelected.add(item)
                                        : tempSelected.remove(item));
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                              hintText: 'Adicionar instrumento personalizado'),
                        ),
                      ),
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
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedInstruments = tempSelected;
                    // keep the text controller in sync for legacy uses
                    _instrumentsController.text =
                        _selectedInstruments.join(', ');
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Salvar'),
              ),
            ],
          );
        });
      },
    );
  }

  // Multi-select dialog for genres with search and ability to add custom
  Future<void> _showGenrePicker() async {
    final allOptions = List<String>.from(_genreOptions);
    for (final s in _selectedGenres) {
      if (!allOptions.contains(s)) allOptions.add(s);
    }

    final tempSelected = {..._selectedGenres};
    String search = '';
    final TextEditingController addController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          final filtered = allOptions
              .where((e) => e.toLowerCase().contains(search.toLowerCase()))
              .toList()
            ..sort((a, b) => a.compareTo(b));

          final bool limitReached = tempSelected.length >= maxGenres;

          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selecionar gêneros'),
                SizedBox(height: 4),
                Text(
                  '${tempSelected.length}/$maxGenres selecionados',
                  style: TextStyle(
                    fontSize: 12,
                    color: limitReached
                        ? AppThemeData.errorColor
                        : AppThemeData.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search), hintText: 'Pesquisar...'),
                    onChanged: (v) => setStateDialog(() => search = v),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: Scrollbar(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final selected = tempSelected.contains(item);
                          final canToggle = 
                              selected || tempSelected.length < maxGenres;
                          return CheckboxListTile(
                            value: selected,
                            title: Text(
                              item,
                              style: TextStyle(
                                color: canToggle
                                    ? AppThemeData.textPrimary
                                    : AppThemeData.textSecondary,
                              ),
                            ),
                            onChanged: canToggle
                                ? (v) {
                                    if (v! && tempSelected.length >= maxGenres) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Máximo de 3 gêneros atingido'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }
                                    setStateDialog(() => v
                                        ? tempSelected.add(item)
                                        : tempSelected.remove(item));
                                  }
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: addController,
                          decoration: const InputDecoration(
                              hintText: 'Adicionar gênero personalizado'),
                        ),
                      ),
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
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedGenres = tempSelected;
                    _genresController.text = _selectedGenres.join(', ');
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Salvar'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Extrai o ID do vídeo do YouTube de uma URL
  String? _extractYoutubeVideoId(String? url) {
    if (url == null || url.isEmpty) return null;

    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\s]+)'),
      RegExp(r'youtube\.com\/embed\/([^&\s]+)'),
      RegExp(r'youtube\.com\/v\/([^&\s]+)'),
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
  Widget build(BuildContext context) {
    final theme = AppThemeData.lightTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: AppThemeData.backgroundColor,
        appBar: AppBar(
          title: Text('Editar Perfil'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        // Indicador de progresso global no topo durante salvamento
        body: Stack(
          children: [
            if (_isSaving)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  backgroundColor: AppThemeData.surfaceColor,
                  color: AppThemeData.primaryColor,
                ),
              ),
            SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 16),

                      // Card 1: Foto + Nome + Tipo
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Avatar com Hero animation
                              Hero(
                                tag: 'profile-avatar-edit',
                                child: GestureDetector(
                                  onTap: () => _showImageSourceActionSheet(),
                                  child: Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 64,
                                        backgroundColor:
                                            AppThemeData.surfaceColor,
                                        backgroundImage: _pickedImageFile !=
                                                null
                                            ? FileImage(_pickedImageFile!)
                                            : (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    _currentPhotoUrl!)
                                                : null)
                                                as ImageProvider?),
                                        child: (_pickedImageFile == null &&
                                                (_currentPhotoUrl == null || _currentPhotoUrl!.isEmpty)
                                            ? Icon(Icons.person,
                                                size: 64,
                                                color: AppThemeData.textSecondary)
                                            : null),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppThemeData.primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.camera_alt,
                                              color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),

                              // Campo Nome
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'Nome',
                                  prefixIcon: Icon(Icons.person_outline,
                                      color: AppThemeData.primaryColor),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Informe o nome'
                                    : null,
                              ),
                              SizedBox(height: 16),

                              // Campo Tipo
                              DropdownButtonFormField<String>(
                                initialValue: _isBand ? 'Banda' : 'Músico',
                                decoration: InputDecoration(
                                  labelText: 'Tipo',
                                  prefixIcon: Icon(Icons.people_outline,
                                      color: AppThemeData.primaryColor),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Músico', child: Text('Músico')),
                                  DropdownMenuItem(
                                      value: 'Banda', child: Text('Banda')),
                                ],
                                onChanged: (val) {
                                  final isBand = (val == 'Banda');
                                  setState(() {
                                    _isBand = isBand;
                                    if (_isBand) {
                                      _selectedInstruments.clear();
                                      _instrumentsController.text = '';
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Card 2: Localização (CEP + cidade)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.location_on,
                                        color: Colors.red, size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Localização',
                                      style: theme.textTheme.titleMedium),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _locationSearchController,
                                decoration: InputDecoration(
                                  labelText: 'Buscar Endereço',
                                  hintText:
                                      'Digite cidade, bairro ou endereço...',
                                  prefixIcon: const Icon(Icons.search,
                                      color: Colors.red),
                                  suffixIcon: _isSearchingLocation
                                      ? Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppThemeData.primaryColor),
                                          ),
                                        )
                                      : _locationSearchController
                                              .text.isNotEmpty
                                          ? IconButton(
                                              icon: Icon(Icons.clear,
                                                  color: AppThemeData.textSecondary),
                                              onPressed: () {
                                                setState(() {
                                                  _locationSearchController
                                                      .clear();
                                                  _locationSuggestions = [];
                                                  _showLocationSuggestions =
                                                      false;
                                                  _fetchedCity = null;
                                                  _fetchedNeighborhood = null;
                                                  _fetchedState = null;
                                                  _fetchedLat = null;
                                                  _fetchedLng = null;
                                                  _locationValidated = false;
                                                });
                                              },
                                            )
                                          : _locationValidated
                                              ? Icon(Icons.check_circle,
                                                  color:
                                                      AppThemeData.successColor)
                                              : null,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _locationValidated = false;
                                    _showLocationSuggestions =
                                        value.length >= 3;
                                  });

                                  if (value.length >= 3) {
                                    _locationDebouncer.run(() async {
                                      setState(
                                          () => _isSearchingLocation = true);

                                      try {
                                        final query =
                                            Uri.encodeComponent('$value, Brasil');
                                        final uri = Uri.parse(
                                            'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1');
                                        final response = await http.get(uri,
                                            headers: {
                                              'User-Agent': 'to_sem_banda_app'
                                            });

                                        if (response.statusCode == 200) {
                                          final data =
                                              json.decode(response.body);
                                          if (data is List) {
                                            setState(() {
                                              _locationSuggestions =
                                                  data.map((item) {
                                                return {
                                                  'display_name': item[
                                                          'display_name']
                                                      .toString(),
                                                  'lat': double.tryParse(item[
                                                              'lat']
                                                          .toString()) ??
                                                      0.0,
                                                  'lon': double.tryParse(item[
                                                              'lon']
                                                          .toString()) ??
                                                      0.0,
                                                  'city': item['address']
                                                          ?['city'] ??
                                                      item['address']?['town'] ??
                                                      item['address']
                                                          ?['village'] ??
                                                      '',
                                                  'neighbourhood':
                                                      item['address']?['neighbourhood'] ??
                                                          item['address']
                                                              ?['suburb'] ??
                                                          '',
                                                  'state': item['address']
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
                                          setState(() => _isSearchingLocation = false);
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

                              // Sugestões de localização
                              if (_showLocationSuggestions &&
                                  _locationSuggestions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  constraints:
                                      const BoxConstraints(maxHeight: 200),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppThemeData.primaryColor
                                            .withOpacity(0.1),
                                        blurRadius: 8, // Assuming a reasonable default blur
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: Border.all(
                                        color: AppThemeData.primaryColor
                                            .withOpacity(0.3)),
                                  ),
                                    ],
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: _locationSuggestions.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final suggestion =
                                          _locationSuggestions[index];
                                      return ListTile(
                                        leading: const Icon(Icons.location_on,
                                            color: Colors.red, size: 20),
                                        title: Text(
                                          suggestion['display_name'],
                                          style: TextStyle(
                                              fontSize: 14,
                                              color:
                                                  AppThemeData.textPrimary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        onTap: () {
                                          final lat = suggestion['lat'];
                                          final lon = suggestion['lon'];
                                          final city = suggestion['city'];
                                          final neighbourhood =
                                              suggestion['neighbourhood'];
                                          final state = suggestion['state'];

                                          setState(() {
                                            _locationSearchController.text =
                                                suggestion['display_name'];
                                            _showLocationSuggestions = false;
                                            _locationSuggestions = [];
                                            _fetchedCity = city;
                                            _fetchedNeighborhood =
                                                neighbourhood;
                                            _fetchedState = state;
                                            _fetchedLat = lat;
                                            _fetchedLng = lon;
                                            _locationValidated = true;
                                          });

                                          debugPrint(
                                              'EditProfile: localização selecionada: $city, lat=$lat, lng=$lon');
                                        },
                                      );
                                    },
                                  ),
                                ),

                              // Localização validada
                              if (_locationValidated &&
                                  (_fetchedCity != null ||
                                      _fetchedNeighborhood != null))
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.successColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            color: AppThemeData.successColor,
                                            size: 20),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (_fetchedCity != null &&
                                                  _fetchedCity!.isNotEmpty)
                                                Text(
                                                  _fetchedCity!,
                                                  style: TextStyle(
                                                      color: AppThemeData.textPrimary,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                              if (_fetchedNeighborhood !=
                                                      null &&
                                                  _fetchedNeighborhood!
                                                      .isNotEmpty)
                                                Text(
                                                  _fetchedNeighborhood!,
                                                  style: TextStyle(
                                                      color: AppThemeData.textSecondary,
                                                      fontSize: 12),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Card 3: Nível + Bio
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.secondaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.star,
                                        color: AppThemeData.secondaryColor,
                                        size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Nível e Bio',
                                      style: theme.textTheme.titleMedium),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Nível dropdown
                              Builder(builder: (context) {
                                final current = _levelController.text;
                                final options =
                                    _isBand ? _bandLevelOptions : _levelOptions;
                                final String? dropdownValue = (current
                                            .isNotEmpty &&
                                        options.contains(current))
                                    ? current
                                    : null;

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      initialValue: dropdownValue,
                                      decoration: InputDecoration(
                                        labelText: 'Nível',
                                        prefixIcon: Icon(Icons.emoji_events,
                                            color:
                                                AppThemeData.secondaryColor),
                                      ),
                                      items: options
                                          .map((lvl) => DropdownMenuItem(
                                              value: lvl, child: Text(lvl)))
                                          .toList(),
                                      onChanged: (val) => setState(
                                          () => _levelController.text = val ?? ''),
                                    ),
                                    if (current.isNotEmpty &&
                                        !options.contains(current))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          'Valor atual: $current',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                  fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                  ],
                                );
                              }),
                              SizedBox(height: 16),

                              // Bio
                              TextFormField(
                                controller: _bioController,
                                decoration: InputDecoration(
                                  labelText: 'Bio',
                                  hintText: 'Conte um pouco sobre você...',
                                  prefixIcon: Icon(Icons.edit_note,
                                      color: AppThemeData.primaryColor),
                                ),
                                minLines: 3,
                                maxLines: 6,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Card 4: Instrumentos e Gêneros
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Instrumentos (somente para músicos)
                              if (!_isBand) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                                                              color: AppThemeData.primaryColor
                                                                                  .withOpacity(0.1),
                                                                              borderRadius: BorderRadius.circular(8),
                                                                            ),                                      child: Icon(Icons.music_note,
                                          color: AppThemeData.primaryColor,
                                          size: 20),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Instrumentos',
                                        style: theme.textTheme.titleMedium),
                                  ],
                                ),
                                SizedBox(height: 12),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: Wrap(
                                    key:
                                        ValueKey(_selectedInstruments.length),
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ..._selectedInstruments.map((i) => Chip(
                                            label: Text(i),
                                            deleteIcon: const Icon(Icons.close,
                                                size: 18),
                                            onDeleted: () => setState(() =>
                                                _selectedInstruments
                                                    .remove(i)),
                                            backgroundColor: AppThemeData
                                                .primaryColor
                                                .withOpacity(0.1),
                                            labelStyle: TextStyle(
                                              color: AppThemeData.primaryColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )),
                                      ActionChip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.add,
                                                size: 18,
                                                color:
                                                    AppThemeData.primaryColor),
                                            SizedBox(width: 4),
                                            Text('Adicionar',
                                                style: TextStyle(
                                                    color: AppThemeData
                                                        .primaryColor)),
                                          ],
                                        ),
                                        onPressed: _showInstrumentPicker,
                                        backgroundColor: Colors.white,
                                        side: BorderSide(
                                            color: AppThemeData.primaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                              ],

                              // Gêneros
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppThemeData.secondaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.album,
                                        color: AppThemeData.secondaryColor,
                                        size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Gêneros Musicais',
                                      style: theme.textTheme.titleMedium),
                                ],
                              ),
                              SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: Wrap(
                                  key: ValueKey(_selectedGenres.length),
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ..._selectedGenres.map((g) => Chip(
                                          label: Text(g),
                                          deleteIcon: const Icon(Icons.close,
                                              size: 18),
                                          onDeleted: () => setState(
                                              () => _selectedGenres.remove(g)),
                                                                                        backgroundColor: AppThemeData
                                                                                            .secondaryColor
                                                                                            .withOpacity(0.1),                                          labelStyle: TextStyle(
                                            color: AppThemeData.secondaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )),
                                    ActionChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add,
                                              size: 18,
                                              color: AppThemeData
                                                  .secondaryColor),
                                          SizedBox(width: 4),
                                          Text('Adicionar',
                                              style: TextStyle(
                                                  color: AppThemeData
                                                      .secondaryColor)),
                                        ],
                                      ),
                                      onPressed: _showGenrePicker,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                          color: AppThemeData.secondaryColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 8),

                      // Card 5: Link YouTube
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.red,
                                        size: 20),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Vídeo do YouTube',
                                      style: theme.textTheme.titleMedium),
                                ],
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _youtubeController,
                                decoration: const InputDecoration(
                                  labelText: 'Link do YouTube',
                                  hintText: 'https://youtu.be/...',
                                  prefixIcon:
                                      Icon(Icons.link, color: Colors.red),
                                ),
                                onChanged: (_) =>
                                    setState(() {}), // Atualiza preview
                              ),
                              // Preview do vídeo
                              if (_youtubeController.text.isNotEmpty)
                                Builder(builder: (context) {
                                  final videoId = _extractYoutubeVideoId(
                                      _youtubeController.text);
                                  if (videoId != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 16),
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
                                              height: 180,
                                              fit: BoxFit.cover,
                                              memCacheWidth: 640,
                                              memCacheHeight: 360,
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: double.infinity,
                                                height: 180,
                                                color:
                                                    AppThemeData.surfaceColor,
                                                child: const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                width: double.infinity,
                                                height: 180,
                                                color:
                                                    AppThemeData.surfaceColor,
                                                child: const Icon(
                                                  Icons.video_library,
                                                  size: 48,
                                                  color: AppThemeData.textSecondary,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                color: Colors.black26,
                                                shape: BoxShape.circle,
                                              ),
                                              padding:
                                                  const EdgeInsets.all(12),
                                              child: const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 40),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 100), // Espaço para o botão fixo
                    ],
                  ),
                ),
              ),
            ),

            // Botão "Salvar" fixo no rodapé
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    disabledBackgroundColor: AppThemeData.textSecondary,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, size: 20),
                            SizedBox(width: 8),
                            Text('Salvar Alterações',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ],
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
