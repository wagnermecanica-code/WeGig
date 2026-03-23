import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/features/profile/domain/entities/profile_type.dart';
import 'package:core_ui/profile_result.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/utils/location_utils.dart';
import 'package:core_ui/utils/music_constants.dart';
import 'package:core_ui/utils/objectionable_content_filter.dart';
import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/auth/presentation/widgets/age_verification_dialog.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_switcher_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({
    super.key,
    this.isNewProfile = false,
    this.profileIdToEdit,
  });
  final bool isNewProfile;
  final String? profileIdToEdit;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _locationController = TextEditingController();
  final _profileUsernameController = TextEditingController();
  final _locationFocusNode = FocusNode();
  final _youtubeController = TextEditingController();
  final _spotifyController = TextEditingController();
  final _deezerController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  // Space-specific controllers
  final _phoneController = TextEditingController();
  final _operatingHoursController = TextEditingController();
  final _websiteController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingProfile = true;
  ProfileEntity? _profile;
  String? _photoUrl;
  ProfileType? _profileType;
  // Space-specific state
  String? _selectedSpaceType;
  Set<String> _selectedAmenities = {};
  final _locationDebouncer = Debouncer(milliseconds: 500);
  String? _selectedLevel;
  Set<String> _selectedInstruments = {};
  Set<String> _selectedGenres = {};

  GeoPoint? _selectedLocation;
  String? _selectedCity;
  String? _selectedNeighborhood;
  String? _selectedState;
  String? _accountUsername;

  // ✅ Estado para validação de username em tempo real (apenas para novos perfis)
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable; // null = não verificado, true = disponível, false = em uso
  String? _lastCheckedUsername;
  Timer? _usernameDebounceTimer;
  List<String> _usernameSuggestions = []; // ✅ Sugestões de username do login social
  int _usernameAutoResolveGeneration = 0;

  // Computed property para evitar lógica no build
  bool get _isFirstAccess => _profile == null && !_isLoadingProfile;
  bool get _canNavigateBack => widget.isNewProfile || !_isFirstAccess;

  bool get _isUsernameLocked {
    final savedUsername = (_profile?.username ?? _accountUsername)?.trim();
    return !widget.isNewProfile && (savedUsername?.isNotEmpty ?? false);
  }

  static const int maxBioLength = 110;
  static const int maxInstruments = 5;
  static const int maxGenres = 5;

  @override
  void initState() {
    super.initState();
    
    // ✅ Para novos perfis, consumir dados do login social após o frame inicial
    // Isso garante que os providers foram atualizados antes de ler
    if (widget.isNewProfile) {
      debugPrint('EditProfile: 🆕 initState - isNewProfile=true, agendando consumo de dados');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _consumeSocialLoginData();
      });
    }
    
    _loadProfile();
  }
  
  /// Consome dados do login social (Apple/Google) e preenche os campos
  /// Deve ser chamado após o frame inicial para garantir sincronização
  Future<void> _consumeSocialLoginData() async {
    if (!widget.isNewProfile) {
      debugPrint('EditProfile: ⚠️ _consumeSocialLoginData ignorado - não é novo perfil');
      return;
    }
    
    debugPrint('EditProfile: 🔄 _consumeSocialLoginData() chamado');
    debugPrint('EditProfile: 🔄 mounted=$mounted');
    
    // ✅ Ler dados do login social
    final socialLoginData = ref.read(socialLoginDataProvider);
    final verifiedBirthYear = ref.read(verifiedBirthYearProvider);
    
    debugPrint('EditProfile: 📊 ====== VALORES DOS PROVIDERS ======');
    debugPrint('EditProfile: 📊 socialLoginDataProvider:');
    if (socialLoginData != null) {
      debugPrint('EditProfile:    ├─ provider: ${socialLoginData.provider}');
      debugPrint('EditProfile:    ├─ displayName: "${socialLoginData.displayName}"');
      debugPrint('EditProfile:    ├─ email: "${socialLoginData.email}"');
      debugPrint('EditProfile:    └─ photoUrl: "${socialLoginData.photoUrl}"');
    } else {
      debugPrint('EditProfile:    └─ NULL');
    }
    debugPrint('EditProfile: 📊 verifiedBirthYearProvider: $verifiedBirthYear');
    debugPrint('EditProfile: 📊 ===================================');
    
    // Pré-preencher ano de nascimento
    if (verifiedBirthYear != null && _birthYearController.text.isEmpty) {
      _birthYearController.text = verifiedBirthYear.toString();
      debugPrint('EditProfile: ✅ Ano de nascimento pré-preenchido: $verifiedBirthYear');
    }
    
    // Consumir dados do login social
    if (socialLoginData != null) {
      debugPrint('EditProfile: ✅ Processando dados de login social (${socialLoginData.provider})...');
      
      bool shouldUpdate = false;
      
      // Pré-preencher nome
      if (socialLoginData.displayName != null && 
          socialLoginData.displayName!.isNotEmpty &&
          _nameController.text.isEmpty) {
        _nameController.text = socialLoginData.displayName!;
        shouldUpdate = true;
        debugPrint('EditProfile: ✅ Nome pré-preenchido: "${socialLoginData.displayName}"');
      } else {
        debugPrint('EditProfile: ⏭️ Nome não pré-preenchido (displayName=${socialLoginData.displayName}, nameController.text=${_nameController.text})');
      }

      // Fallback Apple: usar parte local do email como nome (melhor que vazio)
      if ((_nameController.text.trim().isEmpty) &&
          (socialLoginData.email ?? '').trim().isNotEmpty) {
        final localPart = socialLoginData.email!.split('@').first.trim();
        final cleaned = localPart
            .replaceAll(RegExp(r'[._-]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleaned.isNotEmpty) {
          _nameController.text = cleaned;
          shouldUpdate = true;
          debugPrint('EditProfile: ✅ Nome fallback (email) pré-preenchido: "$cleaned"');
        }
      }
      
      // Pré-preencher foto
      if (socialLoginData.photoUrl != null && 
          socialLoginData.photoUrl!.isNotEmpty &&
          _photoUrl == null) {
        _photoUrl = socialLoginData.photoUrl;
        shouldUpdate = true;
        debugPrint('EditProfile: ✅ Foto pré-preenchida: "${socialLoginData.photoUrl}"');
      } else {
        debugPrint('EditProfile: ⏭️ Foto não pré-preenchida (photoUrl=${socialLoginData.photoUrl}, _photoUrl=$_photoUrl)');
      }
      
      // Gerar sugestões de username
      if (_profileUsernameController.text.isEmpty) {
        final suggestions = socialLoginData.generateUsernameSuggestions();
        debugPrint('EditProfile: 📝 Sugestões de username geradas: $suggestions');
        if (suggestions.isNotEmpty) {
          _usernameSuggestions = suggestions;
          shouldUpdate = true;
          debugPrint('EditProfile: ✅ Sugestões aplicadas - escolhendo automaticamente a primeira disponível');

          // ✅ Escolher automaticamente a primeira sugestão disponível
          await _autoPickFirstAvailableUsernameSuggestion(suggestions);
        }
      } else {
        debugPrint('EditProfile: ⏭️ Username não sugerido (usernameController.text=${_profileUsernameController.text})');
      }
      
      // ⚠️ NÃO limpar providers aqui - limpar apenas após SALVAR o perfil
      // Isso evita perda de dados se o usuário voltar para esta tela
      debugPrint('EditProfile: ℹ️ Providers NÃO limpos (serão limpos ao salvar)');
      
      // Atualizar UI se necessário
      if (shouldUpdate && mounted) {
        setState(() {});
        debugPrint('EditProfile: 🔄 UI atualizada com dados sociais');
      } else {
        debugPrint('EditProfile: ⚠️ UI não atualizada (shouldUpdate=$shouldUpdate, mounted=$mounted)');
      }
    } else {
      debugPrint('EditProfile: ⚠️ socialLoginData é NULL - cadastro manual ou email/senha');
    }
  }

  @override
  void dispose() {
    if (!mounted) return;
    _nameController.dispose();
    _bioController.dispose();
    _birthYearController.dispose();
    _locationController.dispose();
    _profileUsernameController.dispose();
    _locationFocusNode.dispose();
    _youtubeController.dispose();
    _spotifyController.dispose();
    _deezerController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    // Space-specific controllers
    _phoneController.dispose();
    _operatingHoursController.dispose();
    _websiteController.dispose();
    _locationDebouncer.dispose(); // ✅ Cancela Timer pendente
    _usernameDebounceTimer?.cancel(); // ✅ Cancela Timer de username
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final username = (userDoc.data()?['username'] as String?)?.trim();
        if (username != null && username.isNotEmpty) {
          _accountUsername = username;
          if (_profileUsernameController.text.isEmpty) {
            final base = _sanitizeProfileUsername(username);
            _profileUsernameController.text = base;

            // ✅ Para novo perfil: se este username estiver em uso, já sugerir/auto-escolher uma alternativa
            if (widget.isNewProfile) {
              final suggestions = _generateUsernameSuggestionsFromUsername(base);
              _usernameSuggestions = suggestions;
              await _autoPickFirstAvailableUsernameSuggestion(suggestions);
            }
          }
        }
      }

      // Se é novo perfil, apenas finaliza loading (dados sociais já consumidos via addPostFrameCallback)
      if (widget.isNewProfile) {
        debugPrint('EditProfile: Modo novo perfil - aguardando consumo de dados sociais via callback');
        
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
        return;
      }

      // Se tem profileIdToEdit, carrega esse perfil específico
      if (widget.profileIdToEdit != null) {
        debugPrint(
            'EditProfile: Carregando perfil específico: ${widget.profileIdToEdit}');
        final doc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(widget.profileIdToEdit)
            .get();

        if (doc.exists) {
          final profile = ProfileEntity.fromFirestore(doc);
          _profile = profile;
          _accountUsername ??= profile.username;
          _profileUsernameController.text = profile.username ?? '';
          _nameController.text = profile.name;
          _bioController.text = profile.bio ?? '';
          _birthYearController.text = profile.birthYear?.toString() ?? '';
          _selectedLocation = profile.location;
          _selectedCity = profile.city;
          _selectedNeighborhood = profile.neighborhood;
          _selectedState = profile.state;

          _locationController.text = formatCleanLocation(
            neighborhood: profile.neighborhood,
            city: profile.city,
            state: profile.state,
            fallback: '',
          );

          _youtubeController.text = profile.youtubeLink ?? '';
          _spotifyController.text = profile.spotifyLink ?? '';
          _deezerController.text = profile.deezerLink ?? '';
          _instagramController.text = _extractInstagramUsername(profile.instagramLink);
          _tiktokController.text = _extractTikTokUsername(profile.tiktokLink);
          _photoUrl = profile.photoUrl;
          _profileType = profile.profileType;
          _selectedLevel = profile.level;
          _selectedInstruments = {...?profile.instruments};
          _selectedGenres = {...?profile.genres};
          // Space-specific fields
          _selectedSpaceType = profile.spaceType;
          _phoneController.text = profile.phone ?? '';
          _operatingHoursController.text = profile.operatingHours ?? '';
          _websiteController.text = profile.website ?? '';
          _selectedAmenities = {...?profile.amenities};
        }
      } else {
        // Carrega perfil ativo
        final profileState = ref.read(profileProvider);
        final activeProfile = profileState.value?.activeProfile;

        if (activeProfile != null) {
          _profile = activeProfile;
          _accountUsername ??= activeProfile.username;
          _profileUsernameController.text = activeProfile.username ?? '';
          _nameController.text = activeProfile.name;
          _bioController.text = activeProfile.bio ?? '';
          _birthYearController.text = activeProfile.birthYear?.toString() ?? '';
          _selectedLocation = activeProfile.location;
          _selectedCity = activeProfile.city;
          _selectedNeighborhood = activeProfile.neighborhood;
          _selectedState = activeProfile.state;

          _locationController.text = formatCleanLocation(
            neighborhood: activeProfile.neighborhood,
            city: activeProfile.city,
            state: activeProfile.state,
            fallback: '',
          );

          _youtubeController.text = activeProfile.youtubeLink ?? '';
          _spotifyController.text = activeProfile.spotifyLink ?? '';
          _deezerController.text = activeProfile.deezerLink ?? '';
          _instagramController.text = _extractInstagramUsername(activeProfile.instagramLink);
          _tiktokController.text = _extractTikTokUsername(activeProfile.tiktokLink);
          _photoUrl = activeProfile.photoUrl;
          _profileType = activeProfile.profileType;
          _selectedLevel = activeProfile.level;
          _selectedInstruments = {...?activeProfile.instruments};
          _selectedGenres = {...?activeProfile.genres};
          // Space-specific fields
          _selectedSpaceType = activeProfile.spaceType;
          _phoneController.text = activeProfile.phone ?? '';
          _operatingHoursController.text = activeProfile.operatingHours ?? '';
          _websiteController.text = activeProfile.website ?? '';
          _selectedAmenities = {...?activeProfile.amenities};
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar perfil: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(
      String query) async {
    if (query.isEmpty) return [];

    // Debounce: aguarda 500ms após parar de digitar para fazer chamada API
    final completer = Completer<List<Map<String, dynamic>>>();

    _locationDebouncer.run(() async {
      try {
        debugPrint('🔍 Debounced search: $query');
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5',
        );
        final response = await http.get(
          url,
          headers: {'User-Agent': 'to-sem-banda-app'},
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List<dynamic>;
          final results = data
              .map<Map<String, dynamic>>(
                  (dynamic item) => item as Map<String, dynamic>)
              .toList();
          completer.complete(results);
        } else {
          completer.complete([]);
        }
      } catch (e) {
        debugPrint('❌ Erro ao buscar endereços: $e');
        completer.complete([]);
      }
    });

    return completer.future;
  }

  void _onAddressSelected(Map<String, dynamic> suggestion) {
    final lat = double.tryParse((suggestion['lat'] as String?) ?? '') ?? 0.0;
    final lon = double.tryParse((suggestion['lon'] as String?) ?? '') ?? 0.0;

    if (lat != 0.0 && lon != 0.0) {
      final address = suggestion['address'] as Map<String, dynamic>?;

      // Extrair componentes do endereço
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

      setState(() {
        _selectedLocation = GeoPoint(lat, lon);
        final formatted = formatCleanLocation(
          neighbourhood: neighbourhood,
          city: city,
          state: state,
          fallback: '',
        );
        _locationController.text = formatted.isNotEmpty
            ? formatted
            : (suggestion['display_name'] as String?) ?? '';
        _selectedCity = city;
        _selectedNeighborhood = neighbourhood.isEmpty ? null : neighbourhood;
        _selectedState = state.isEmpty ? null : state;
      });
      _locationFocusNode.unfocus();
    }
  }

  Future<void> _pickAndCropProfileImage() async {
    try {
      debugPrint('EditProfile: Iniciando seleção de imagem...');
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (picked == null) {
        debugPrint('EditProfile: Seleção de imagem cancelada pelo usuário');
        return;
      }

      debugPrint('EditProfile: Imagem selecionada: ${picked.path}');

      // Crop da imagem travado em 1:1 para evitar avatares achatados
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
        compressFormat: ImageCompressFormat.jpg,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Foto de Perfil',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            statusBarLight: false,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.primary,
            hideBottomControls: true,
            cropFrameColor: AppColors.primary,
            cropGridColor: Colors.white24,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Editar Foto de Perfil',
            minimumAspectRatio: 1,
            aspectRatioLockEnabled: true,
            aspectRatioLockDimensionSwapEnabled: false,
            rotateButtonsHidden: true,
            resetButtonHidden: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
          ),
        ],
      );

      if (cropped == null) {
        debugPrint('EditProfile: Crop cancelado pelo usuário');
        return;
      }

      final croppedPath = cropped.path;
      debugPrint('EditProfile: Imagem cortada: $croppedPath');

      debugPrint('EditProfile: Iniciando compressão da imagem...');
      final tempDir = Directory.systemTemp;
      final targetPath = p.join(
        tempDir.path,
        '${DateTime.now().millisecondsSinceEpoch}_profile_comp.jpg',
      );

      // Compressão direta (não em isolate, pois FlutterImageCompress não funciona em isolates no iOS)
      final compressed = await FlutterImageCompress.compressAndGetFile(
        croppedPath,
        targetPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
      );

      if (compressed != null && mounted) {
        final compressedPath = compressed.path;
        debugPrint(
            'EditProfile: Imagem comprimida com sucesso: $compressedPath');
        setState(() {
          _photoUrl = compressedPath;
          debugPrint('EditProfile: _photoUrl atualizado para: $_photoUrl');
        });

        // Evita mostrar snackbar redundante; feedback visual já atualiza o avatar.
      } else {
        debugPrint(
            'EditProfile: Compressão retornou null ou widget não montado');
      }
    } catch (e) {
      debugPrint('EditProfile: ERRO ao selecionar imagem: $e');
      if (mounted) {
        AppSnackBar.showError(
          context,
          'Erro ao selecionar imagem: $e',
        );
      }
    }
  }

  Future<void> _handleSuccessfulProfileSave(
    ProfileEntity profile, {
    required bool isCreation,
    required ProfileNotifier profileNotifier,
  }) async {
    try {
      await profileNotifier.refresh();
    } catch (_) {
      // Se falhar o refresh, silenciosamente ignora
      // pois o perfil já foi salvo com sucesso
    }

    // ✅ Limpar providers de login social após salvar com sucesso
    // Isso evita que os dados sejam reutilizados em futuras criações de perfil
    if (isCreation && widget.isNewProfile) {
      debugPrint('EditProfile: 🧹 Limpando providers de login social após salvar');
      ref.read(socialLoginDataProvider.notifier).state = null;
      ref.read(verifiedBirthYearProvider.notifier).state = null;
    }

    if (!mounted) return;

    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);

    AppSnackBar.showSuccess(
      context,
      isCreation
          ? 'Perfil criado com sucesso!'
          : 'Perfil atualizado com sucesso!',
    );

    // Para primeiro perfil criado (isNewProfile), vai direto para home
    // Para edição de perfil, volta para a página do perfil
    if (widget.isNewProfile && isCreation) {
      debugPrint(
        'EditProfile: Perfil criado, indo para Home (aba Perfil): ${profile.profileId}',
      );
      // ✅ Se a página foi aberta via Navigator.push (ex: modal), fechá-la.
      // Em alguns fluxos, um `router.go(...)` não remove rotas fora do GoRouter.
      if (navigator.canPop()) {
        navigator.pop(profile.profileId);
      }

      // ✅ Garantir que o usuário veja o perfil novo dentro do BottomNavScaffold.
      // Usamos post-frame para evitar navegar durante pop/transition.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('${AppRoutes.home}?tab=profile');
      });
      return;
    } else {
      // ✅ IMPORTANT: Do not force a `go(/profile/...)` here.
      // That replaces the navigation stack and lands the user on ViewProfile
      // with no BottomNavScaffold and (since it becomes the root) no back button.
      // Instead, return to the previous screen (ViewProfile/Home/Settings),
      // preserving the expected navigation chrome.
      if (navigator.canPop()) {
        navigator.pop(profile.profileId);
        return;
      }

      // Fallback for deep-linked edit route (no back stack): go to home.
      router.go(AppRoutes.home);
    }
  }

  Future<void> _waitForUserDocumentUsername(String uid) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    try {
      await docRef.snapshots().firstWhere((snapshot) {
        final username = (snapshot.data()?['username'] as String?)?.trim();
        return username != null && username.isNotEmpty;
      }).timeout(const Duration(seconds: 5));
    } catch (error) {
      debugPrint(
        'EditProfile: Timeout aguardando username em users/$uid: $error',
      );
    }
  }

  Future<void> _ensureUsernameLowercaseField(
    String profileId,
    String? username,
  ) async {
    final value = username?.trim();
    if (value == null || value.isEmpty) return;

    final lowercase = value.toLowerCase();
    try {
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(profileId)
          .set(
        {'usernameLowercase': lowercase},
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint(
        'EditProfile: Falha ao garantir usernameLowercase para $profileId: $error',
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar tipo de perfil (obrigatório na primeira edição)
    if (_profileType == null) {
      AppSnackBar.showWarning(
        context,
        'Por favor, selecione o tipo de perfil (Músico, Banda ou Espaço)',
      );
      return;
    }

    // Músico: ano de nascimento obrigatório e >= 18 anos
    if (_profileType == ProfileType.musician) {
      final birthYearStr = _birthYearController.text.trim();
      final birthYear = int.tryParse(birthYearStr);
      final currentYear = DateTime.now().year;

      if (birthYear == null) {
        AppSnackBar.showWarning(context, 'Informe um ano de nascimento válido (apenas números)');
        return;
      }

      if (birthYear > currentYear) {
        AppSnackBar.showWarning(context, 'Ano de nascimento não pode ser no futuro');
        return;
      }

      final age = currentYear - birthYear;
      if (age < 18) {
        AppSnackBar.showWarning(
          context,
          'Idade mínima para músicos é 18 anos',
        );
        return;
      }
    }

    // Validar campos específicos de Espaço
    if (_profileType == ProfileType.space) {
      if (_selectedSpaceType == null) {
        AppSnackBar.showWarning(
          context,
          'Por favor, selecione o tipo de espaço',
        );
        return;
      }
    }

    debugPrint('📝 EditProfile: Iniciando salvamento de perfil...');

    setState(() => _isSaving = true);

    try {
      final auth = FirebaseAuth.instance;
      final currentUser = auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      await currentUser.reload();
      final user = auth.currentUser ?? currentUser;
      debugPrint(
          '📝 EditProfile: Usuário autenticado (fresh) - uid=${user.uid}');

      var uploadedPhotoUrl = _photoUrl;
      final normalizedProfileUsername =
          _sanitizeProfileUsername(_profileUsernameController.text);
      final currentProfileUsername = _profile?.username != null
          ? _sanitizeProfileUsername(_profile!.username!)
          : '';
      final profileIdToExclude = _profile?.profileId ?? widget.profileIdToEdit;
      final requiresUsername =
          widget.isNewProfile || currentProfileUsername.isEmpty;

      if (requiresUsername && normalizedProfileUsername.isEmpty) {
        throw Exception('Informe um nome de usuário para este perfil');
      }

      final profileUsernameToSave = normalizedProfileUsername.isNotEmpty
          ? normalizedProfileUsername
          : (currentProfileUsername.isNotEmpty ? currentProfileUsername : null);

      if (profileUsernameToSave != null) {
        await _ensureProfileUsernameUnique(
          profileUsernameToSave,
          excludeProfileId: profileIdToExclude,
        );
      }

      // Upload da foto se for um arquivo local
      if (_photoUrl != null && !_photoUrl!.startsWith('http')) {
        debugPrint('📸 EditProfile: Detectado arquivo local: $_photoUrl');
        final photoFile = File(_photoUrl!);
        if (await photoFile.exists()) {
          debugPrint('📸 EditProfile: Fazendo upload da foto de perfil...');
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profiles')
              .child(user.uid)
              .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

          await storageRef.putFile(photoFile);
          uploadedPhotoUrl = await storageRef.getDownloadURL();
          debugPrint('✅ EditProfile: Foto uploaded - $uploadedPhotoUrl');
        } else {
          debugPrint('❌ EditProfile: Arquivo não existe: $_photoUrl');
        }
      } else if (_photoUrl != null) {
        debugPrint('📸 EditProfile: Usando URL existente: $_photoUrl');
      }

      // Use profileProvider.notifier methods (Clean Architecture)
      final currentProfile = _profile;

      final bioText = _bioController.text.trim();
      final bioError = ObjectionableContentFilter.validate(
        'bio',
        bioText.isEmpty ? null : bioText,
      );
      if (bioError != null) {
        throw Exception(bioError);
      }

      if (widget.isNewProfile || currentProfile == null) {
        // ✅ Criar novo perfil via ProfileService (Clean Architecture)
        debugPrint('✨ EditProfile: Criando novo perfil...');

        if (_selectedLocation == null ||
            _selectedCity == null ||
            _selectedCity!.isEmpty) {
          throw Exception('Localização é obrigatória');
        }

        final newProfile = ProfileEntity(
          profileId: FirebaseFirestore.instance.collection('profiles').doc().id,
          uid: user.uid,
          name: _nameController.text.trim(),
          username: profileUsernameToSave,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          birthYear: _birthYearController.text.trim().isEmpty
              ? null
              : int.tryParse(_birthYearController.text.trim()),
          location: _selectedLocation!,
          city: _selectedCity!,
          neighborhood: _selectedNeighborhood,
          state: _selectedState,
          photoUrl: uploadedPhotoUrl,
          isBand: _profileType == ProfileType.band,
          profileType: _profileType!,
          level: _profileType == ProfileType.musician ? _selectedLevel : null,
          instruments: _selectedInstruments.toList(),
          genres: _selectedGenres.toList(),
          youtubeLink: _youtubeController.text.trim().isEmpty
              ? null
              : _youtubeController.text.trim(),
            spotifyLink: _buildSpotifyUrl(_spotifyController.text),
          deezerLink: _buildDeezerUrl(_deezerController.text),
          instagramLink: _buildInstagramUrl(_instagramController.text),
          tiktokLink: _buildTikTokUrl(_tiktokController.text),
          // Space-specific fields
          spaceType: _selectedSpaceType,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          operatingHours: _operatingHoursController.text.trim().isEmpty
              ? null
              : _operatingHoursController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          amenities: _selectedAmenities.isEmpty
              ? null
              : _selectedAmenities.toList(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // ✅ Capturar notifier ANTES das operações assíncronas para evitar "ref after disposed"
        final profileNotifier = ref.read(profileProvider.notifier);
        
        // ✅ Usar profileProvider.notifier (Clean Architecture)
        final result = await profileNotifier.createProfile(newProfile);

        switch (result) {
          case ProfileSuccess(:final profile):
            debugPrint(
                '✅ EditProfile: Perfil criado - ID=${profile.profileId}');

            await _ensureUsernameLowercaseField(
              profile.profileId,
              profile.username,
            );

            await ref
                .read(profileSwitcherNotifierProvider.notifier)
                .switchToProfile(profile.profileId);

            final userDocRef =
                FirebaseFirestore.instance.collection('users').doc(user.uid);
            await userDocRef.set(
              {
                'username': profile.username,
                'activeProfileId': profile.profileId,
              },
              SetOptions(merge: true),
            );

            await _waitForUserDocumentUsername(user.uid);

            await _handleSuccessfulProfileSave(
              profile,
              isCreation: true,
              profileNotifier: profileNotifier,
            );
            return;

          case ProfileFailure(:final message):
            debugPrint('❌ EditProfile: Falha ao criar - $message');
            throw Exception(message);

          case ProfileValidationError(:final errors):
            debugPrint('⚠️ EditProfile: Erros de validação - $errors');
            final errorMsg = errors.values.join('\n');
            throw Exception(errorMsg);

          case ProfileNotFound():
            throw Exception('Erro inesperado ao criar perfil');

          case ProfileListSuccess():
            throw Exception('Resultado inesperado: ProfileListSuccess');

          case ProfileCancelled():
            debugPrint('⚠️ EditProfile: Operação cancelada pelo usuário');
            if (mounted) Navigator.of(context).pop();
            return;
        }
      } else {
        // ✅ Atualizar perfil existente via ProfileService
        debugPrint(
            '🔄 EditProfile: Atualizando perfil existente - ID=${currentProfile.profileId}');

        final updatedProfile = currentProfile.copyWith(
          name: _nameController.text.trim(),
          username: profileUsernameToSave ?? currentProfile.username,
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          birthYear: _birthYearController.text.trim().isEmpty
              ? null
              : int.tryParse(_birthYearController.text.trim()),
          location: _selectedLocation ?? currentProfile.location,
          city: _selectedCity ?? currentProfile.city,
          neighborhood: _selectedNeighborhood,
          state: _selectedState,
          photoUrl: uploadedPhotoUrl,
          isBand: _profileType == ProfileType.band,
          profileType: _profileType ?? ProfileType.musician,
          level: _profileType == ProfileType.musician ? _selectedLevel : null,
          instruments: _selectedInstruments.toList(),
          genres: _selectedGenres.toList(),
          youtubeLink: _youtubeController.text.trim().isEmpty
              ? null
              : _youtubeController.text.trim(),
            spotifyLink: _buildSpotifyUrl(_spotifyController.text),
          deezerLink: _buildDeezerUrl(_deezerController.text),
          instagramLink: _buildInstagramUrl(_instagramController.text),
          tiktokLink: _buildTikTokUrl(_tiktokController.text),
          // Space-specific fields
          spaceType: _selectedSpaceType,
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          operatingHours: _operatingHoursController.text.trim().isEmpty
              ? null
              : _operatingHoursController.text.trim(),
          website: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
          amenities: _selectedAmenities.isEmpty
              ? null
              : _selectedAmenities.toList(),
          updatedAt: DateTime.now(),
        );

        // ✅ Capturar notifier ANTES das operações assíncronas para evitar "ref after disposed"
        final profileNotifierUpdate = ref.read(profileProvider.notifier);
        
        // ✅ Usar profileProvider.notifier (Clean Architecture)
        final result = await profileNotifierUpdate.updateProfile(updatedProfile);

        switch (result) {
          case ProfileSuccess(:final profile):
            debugPrint(
                '✅ EditProfile: Perfil atualizado - ID=${profile.profileId}');

            await _ensureUsernameLowercaseField(
              profile.profileId,
              profile.username,
            );

            await _handleSuccessfulProfileSave(
              profile,
              isCreation: false,
              profileNotifier: profileNotifierUpdate,
            );
            return;

          case ProfileFailure(:final message):
            debugPrint('❌ EditProfile: Falha ao atualizar - $message');
            throw Exception(message);

          case ProfileValidationError(:final errors):
            debugPrint('⚠️ EditProfile: Erros de validação - $errors');
            final errorMsg = errors.values.join('\n');
            throw Exception(errorMsg);

          case ProfileNotFound():
            throw Exception('Perfil não encontrado');

          case ProfileListSuccess():
            throw Exception('Resultado inesperado: ProfileListSuccess');

          case ProfileCancelled():
            debugPrint('⚠️ EditProfile: Operação cancelada pelo usuário');
            if (mounted) Navigator.of(context).pop();
            return;
        }
      }
    } catch (e) {
      debugPrint('❌ EditProfile: Erro ao salvar perfil: $e');

      if (mounted) {
        // Mensagens de erro específicas
        final errorString = e.toString();
        
        // Validações de campo (warnings)
        if (errorString.contains('Este nome de usuário já está em uso')) {
          AppSnackBar.showWarning(
            context,
            'Este nome de usuário já está em uso. Escolha outro.',
          );
          return;
        }
        
        if (errorString.contains('Informe um nome de usuário')) {
          AppSnackBar.showWarning(
            context,
            'Por favor, informe um nome de usuário para o perfil',
          );
          return;
        }
        
        if (errorString.contains('Localização')) {
          AppSnackBar.showWarning(
            context,
            'Por favor, selecione uma localização válida',
          );
          return;
        }

        // Erros do sistema
        var errorMessage = 'Erro ao salvar perfil';

        if (errorString.contains('permission-denied')) {
          errorMessage = 'Você não tem permissão para realizar esta operação';
        } else if (errorString.contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet';
        } else if (e is Exception) {
          errorMessage = errorString.replaceAll('Exception: ', '');
        }

        AppSnackBar.showError(
          context,
          errorMessage,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevenir voltar apenas quando realmente bloqueado
      canPop: _canNavigateBack,
      // NÃO mostrar snackbar ao sair sem salvar (removido conforme solicitado)
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // Apenas fecha sem alertas
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: !_canNavigateBack
              ? null
              : IconButton(
                  icon: Icon(
                    widget.isNewProfile
                        ? Iconsax.arrow_left
                        : Iconsax.close_circle,
                    color: Colors.black,
                  ),
                  onPressed: () async {
                    if (widget.isNewProfile) {
                      // Verificar se usuário já tem outros perfis
                      final profileState = ref.read(profileProvider).valueOrNull;
                      final hasExistingProfiles = profileState?.profiles.isNotEmpty ?? false;
                      
                      if (hasExistingProfiles) {
                        // Usuário já tem perfis, apenas voltar para a tela anterior
                        if (mounted) {
                          Navigator.of(context).maybePop();
                        }
                      } else {
                        // Primeiro perfil (após autenticação): fazer logout e voltar para auth
                        await ref.read(authServiceProvider).signOut();
                        if (mounted) {
                          context.go(AppRoutes.auth);
                        }
                      }
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
          title: Text(
            widget.isNewProfile
                ? 'Novo Perfil'
                : (_isFirstAccess ? 'Complete seu Perfil' : 'Editar Perfil'),
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE47911)),
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // A. Bloco de Tipologia (MOVIDO PARA O TOPO)
                    _buildTypologyBlock(),
                    const SizedBox(height: 16),
                    Divider(thickness: 1, color: Colors.grey[300]),
                    const SizedBox(height: 24),

                    // B. Bloco Essencial
                    _buildEssentialBlock(),
                    const SizedBox(height: 24),

                    // C. Bloco de Habilidades (apenas músicos/bandas) ou Espaço
                    if (_profileType == ProfileType.musician ||
                        _profileType == ProfileType.band) ...[
                      _buildSkillsBlock(),
                      const SizedBox(height: 24),
                    ],
                    if (_profileType == ProfileType.space) ...[
                      _buildSpaceDetailsBlock(),
                      const SizedBox(height: 24),
                    ],

                    // D. Bloco de Links Sociais e Mídia
                    _buildSocialLinksBlock(),

                    const SizedBox(height: 80), // Espaço para o botão fixo
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: FractionallySizedBox(
              widthFactor: 0.8, // 80% da largura
              child: ElevatedButton(
                onPressed: _shouldDisableSaveButton ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isFirstAccess ? 'Salvar Perfil' : 'Salvar Alterações',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEssentialBlock() {
    final activeProfile = ref.watch(profileProvider).value?.activeProfile;
    final usernameValue = (activeProfile?.username ?? _profile?.username ?? _accountUsername)?.trim();
    final hasUsername = usernameValue != null && usernameValue.isNotEmpty;
    final sanitizedUsername = hasUsername
      ? (usernameValue.startsWith('@')
        ? usernameValue.substring(1)
        : usernameValue)
      : null;

    return Column(
      children: [
        const Text(
          'Informações Essenciais',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Foto de Perfil
        Center(
          child: GestureDetector(
            onTap: () {
              debugPrint(
                  'EditProfile: CircleAvatar clicado, chamando _pickAndCropProfileImage');
              _pickAndCropProfileImage();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  foregroundImage: _photoUrl != null
                      ? (_photoUrl!.startsWith('http')
                          ? CachedNetworkImageProvider(_photoUrl!)
                              as ImageProvider
                          : FileImage(File(_photoUrl!)))
                      : null,
                  child: _photoUrl == null
                      ? Icon(Iconsax.user, size: 64, color: Colors.grey[600])
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Iconsax.camera,
                        size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_isUsernameLocked && hasUsername && sanitizedUsername != null) ...[
          TextFormField(
            key: ValueKey('username-field-${sanitizedUsername.toLowerCase()}'),
            initialValue: '@$sanitizedUsername',
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Nome de usuário',
              prefixIcon: const Icon(
                Icons.alternate_email,
                color: AppColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O nome de usuário não pode ser alterado após o cadastro.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ] else ...[
          TextFormField(
            controller: _profileUsernameController,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: 'Nome de usuário do perfil',
              hintText: 'Escolha um @username único',
              helperText:
                  'Único por perfil. Use letras, números, ponto e underline.',
              prefixText: '@',
              // ✅ Sufixo com indicador de status (apenas para novos perfis)
              suffixIcon: _buildUsernameSuffixIcon(),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon:
                  const Icon(Icons.alternate_email, color: AppColors.primary),
            ),
            validator: _validateProfileUsername,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
            // ✅ Verificar disponibilidade em tempo real
            onChanged: _checkUsernameAvailability,
          ),
          // ✅ Indicador de disponibilidade abaixo do campo
          _buildUsernameAvailabilityIndicator(),
          // ✅ Sugestões de username do login social
          _buildUsernameSuggestions(),
        ],
        const SizedBox(height: 16),

        // Nome
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome',
            hintText: _profileType == ProfileType.band
                ? 'Nome da banda'
                : _profileType == ProfileType.space
                    ? 'Nome do espaço'
                    : 'Seu nome',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.user),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Biografia
        TextFormField(
          controller: _bioController,
          maxLines: 4,
          maxLength: maxBioLength,
          decoration: InputDecoration(
            labelText: 'Biografia',
            hintText: _profileType == ProfileType.band
                ? 'Conte sobre a banda, estilo, história...'
                : _profileType == ProfileType.space
                    ? 'Descreva o espaço, serviços, diferenciais...'
                    : 'Conte sobre você, experiência, objetivos...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.note),
            counterText: '${_bioController.text.length}/$maxBioLength',
          ),
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Ano de nascimento/formação
        TextFormField(
          controller: _birthYearController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: _profileType == ProfileType.band
                ? 'Ano de formação'
                : _profileType == ProfileType.space
                    ? 'Ano de fundação'
                    : 'Ano de nascimento',
            hintText: _profileType == ProfileType.band
                ? 'Quando a banda foi formada'
                : _profileType == ProfileType.space
                    ? 'Ano de fundação do espaço'
                    : 'Seu ano de nascimento',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(
              _profileType == ProfileType.musician ? Iconsax.cake : Iconsax.calendar,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              if (_profileType == ProfileType.musician) {
                return 'Informe seu ano de nascimento (18+)';
              }
              return null; // Opcional para banda/espaço
            }

            final yearStr = value.trim();
            final year = int.tryParse(yearStr);

            if (year == null) {
              return 'Digite apenas números';
            }

            final currentYear = DateTime.now().year;

            if (_profileType == ProfileType.band || _profileType == ProfileType.space) {
              // BANDAS/ESPAÇOS: Validação de ano de formação/fundação
              if (year < 1900) {
                return 'Ano muito antigo (mínimo: 1900)';
              }
              if (year > currentYear) {
                return 'Ano não pode ser no futuro';
              }
            } else {
              // MÚSICOS: Validação de idade (18 a 120 anos)
              if (year > currentYear) {
                return 'Ano não pode ser no futuro';
              }
              final age = currentYear - year;

              // Idade muito baixa (< 18 anos)
              if (age < 18) {
                return 'Idade mínima é 18 anos (ano máximo: ${currentYear - 18})';
              }

              // Idade muito alta (> 120 anos)
              if (age > 120) {
                return 'Idade máxima é 120 anos (ano mínimo: ${currentYear - 120})';
              }

              // Ano no futuro
              if (year > currentYear) {
                return 'Ano não pode ser no futuro';
              }
            }

            return null;
          },
        ),
        const SizedBox(height: 16),

        // Localização
        const Text(
          'Localização',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
          TypeAheadField<Map<String, dynamic>>(
            controller: _locationController,
            focusNode: _locationFocusNode,
            debounceDuration: const Duration(milliseconds: 600), // nativo!
            suggestionsCallback: _fetchAddressSuggestions,
            loadingBuilder: (context) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            emptyBuilder: (context) => Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.search_normal, color: Colors.grey[400]),
                  const SizedBox(width: 8),
                  Text('Digite para buscar endereço', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            builder: (context, controller, focusNode) {
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: 'Buscar localização (cidade, bairro, endereço...)',
                  prefixIcon: const Icon(Iconsax.location, color: AppColors.primary),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Iconsax.close_circle, color: AppColors.textSecondary),
                          onPressed: () {
                            controller.clear();
                            setState(() {
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                validator: (_) => _selectedLocation == null ? 'Selecione uma localização' : null,
              );
            },
            itemBuilder: (context, suggestion) {
              final displayName = suggestion['display_name'] as String? ?? '';
              return ListTile(
                leading: const Icon(Iconsax.location, color: AppColors.primary),
                title: Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            },
            onSelected: _onAddressSelected,
          ),
      ],
    );
  }

  Widget _buildTypologyBlock() {
    return Column(
      children: [
        const Text(
          'Tipo de Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        if (_profileType == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, color: Colors.orange[700], size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Esta escolha é importante e afeta como seu perfil será exibido',
                    style: TextStyle(fontSize: 13, color: Color(0xFF7A4100)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                icon: Iconsax.user,
                label: 'Músico',
                isSelected: _profileType == ProfileType.musician,
                onTap: () => setState(() => _profileType = ProfileType.musician),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                icon: Iconsax.people,
                label: 'Banda',
                isSelected: _profileType == ProfileType.band,
                onTap: () => setState(() => _profileType = ProfileType.band),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                icon: Iconsax.building,
                label: 'Espaço',
                isSelected: _profileType == ProfileType.space,
                onTap: () => setState(() => _profileType = ProfileType.space),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppColors.primary : Colors.grey[600],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsBlock() {
    return Column(
      children: [
        const Text(
          'Habilidades e Estilos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Gêneros musicais
        MultiSelectField(
          title: 'Gêneros musicais',
          placeholder: 'Selecione até 5 gêneros',
          options: MusicConstants.genreOptions,
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
          title: _profileType == ProfileType.band ? 'Instrumentação' : 'Instrumentos',
          placeholder: 'Selecione até 5 instrumentos',
          options: MusicConstants.instrumentOptions,
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
        const SizedBox(height: 16),

        // Nível (apenas para músicos)
        if (_profileType == ProfileType.musician) ...[
          const Text(
            'Nível',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedLevel,
            items: MusicConstants.levelOptions
                .map(
                  (level) => DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedLevel = value),
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
        ],
      ],
    );
  }

  Widget _buildSpaceDetailsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalhes do Espaço',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Tipo de Espaço (obrigatório)
        const Text(
          'Tipo de Espaço *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedSpaceType,
          items: SpaceType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type.value,
                  child: Text(type.label),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedSpaceType = value),
          decoration: InputDecoration(
            hintText: 'Selecione o tipo de espaço',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            prefixIcon: const Icon(Iconsax.building_4),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tipo de espaço é obrigatório';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Telefone/WhatsApp (opcional)
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            // Formatação brasileira para telefone
            _BrazilianPhoneFormatter(),
          ],
          decoration: InputDecoration(
            labelText: 'Telefone/WhatsApp',
            hintText: '(11) 99999-9999',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.call),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // Campo opcional
            }
            // Remove caracteres não numéricos
            final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
            if (digitsOnly.length < 10 || digitsOnly.length > 11) {
              return 'Telefone inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Horário de Funcionamento (opcional)
        TextFormField(
          controller: _operatingHoursController,
          decoration: InputDecoration(
            labelText: 'Horário de Funcionamento',
            hintText: 'Ex: Seg-Sex 9h-18h',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.clock),
          ),
        ),
        const SizedBox(height: 16),

        // Website (opcional)
        TextFormField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Website',
            hintText: 'https://seusite.com.br',
            suffixIcon: _websiteController.text.isEmpty
                ? null
                : _isValidWebsiteUrl(_websiteController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _websiteController.text.isNotEmpty
                ? (_isValidWebsiteUrl(_websiteController.text)
                    ? '✓ URL válida'
                    : '✗ URL deve começar com http:// ou https://')
                : null,
            helperStyle: TextStyle(
              color: _isValidWebsiteUrl(_websiteController.text)
                  ? Colors.green
                  : Colors.red,
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.global),
          ),
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final url = value.trim();
            if (!url.startsWith('http://') && !url.startsWith('https://')) {
              return 'URL deve começar com http:// ou https://';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Comodidades (opcional)
        const Text(
          'Comodidades',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildAmenityChip('Wi-Fi grátis'),
            _buildAmenityChip('Estacionamento'),
            _buildAmenityChip('Ar-condicionado'),
            _buildAmenityChip('Aberto 24 horas'),
            _buildAmenityChip('Área para fumantes'),
            _buildAmenityChip('Aceita pix'),
            _buildAmenityChip('Técnico de som'),
            _buildAmenityChip('Bebidas disponíveis'),
            _buildAmenityChip('Comida disponível'),
            _buildAmenityChip('Palco para apresentações'),
            _buildAmenityChip('Live streaming'), 
            _buildAmenityChip('Acessibilidade'),
            _buildAmenityChip('Próximo ao metrô'),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenityChip(String amenity) {
    final isSelected = _selectedAmenities.contains(amenity);
    return FilterChip(
      label: Text(amenity),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedAmenities.add(amenity);
          } else {
            _selectedAmenities.remove(amenity);
          }
        });
      },
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey[300]!,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  /// Valida username do Instagram (1-30 chars, letras, números, pontos e underscores)
  bool _isValidInstagramUsername(String username) {
    if (username.trim().isEmpty) return true; // Campo opcional
    final cleanUsername = username.trim().replaceFirst('@', '');
    // Instagram: 1-30 chars, letras, números, pontos e underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9._]{1,30}$');
    return usernameRegex.hasMatch(cleanUsername);
  }

  /// Valida username do TikTok (1-24 chars, letras, números, pontos e underscores)
  bool _isValidTikTokUsername(String username) {
    if (username.trim().isEmpty) return true; // Campo opcional
    final cleanUsername = username.trim().replaceFirst('@', '');
    // TikTok: 1-24 chars, letras, números, pontos e underscores
    final usernameRegex = RegExp(r'^[a-zA-Z0-9._]{1,24}$');
    return usernameRegex.hasMatch(cleanUsername);
  }

  /// Extrai username de uma URL do Instagram (para compatibilidade com dados existentes)
  String _extractInstagramUsername(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Se já é apenas o username (sem URL)
    if (!url.contains('/') && !url.contains('.com')) {
      return url.replaceFirst('@', '');
    }
    
    // Extrai username da URL
    final regex = RegExp(
      r'(?:instagram\.com|instagr\.am)/([a-zA-Z0-9._]+)/?',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(1) ?? url.replaceFirst('@', '');
  }

  /// Extrai username de uma URL do TikTok (para compatibilidade com dados existentes)
  String _extractTikTokUsername(String? url) {
    if (url == null || url.isEmpty) return '';
    
    // Se já é apenas o username (sem URL)
    if (!url.contains('/') && !url.contains('.com')) {
      return url.replaceFirst('@', '');
    }
    
    // Extrai username da URL
    final regex = RegExp(
      r'(?:tiktok\.com|vm\.tiktok\.com)/@?([a-zA-Z0-9._]+)/?',
      caseSensitive: false,
    );
    final match = regex.firstMatch(url);
    return match?.group(1) ?? url.replaceFirst('@', '');
  }

  /// Converte username para URL completa do Instagram
  String? _buildInstagramUrl(String username) {
    final cleanUsername = username.trim().replaceFirst('@', '');
    if (cleanUsername.isEmpty) return null;
    return 'https://instagram.com/$cleanUsername';
  }

  /// Converte username para URL completa do TikTok
  String? _buildTikTokUrl(String username) {
    final cleanUsername = username.trim().replaceFirst('@', '');
    if (cleanUsername.isEmpty) return null;
    return 'https://tiktok.com/@$cleanUsername';
  }

  bool _isValidSpotifyUrl(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return false;
    return normalized.startsWith('https://open.spotify.com/') || normalized.startsWith('spotify:');
  }

  bool _isValidDeezerUrl(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return false;
    return normalized.startsWith('https://www.deezer.com/') ||
        normalized.startsWith('https://deezer.com/') ||
        normalized.startsWith('https://deezer.page.link/') ||
        normalized.startsWith('deezer://');
  }

  String? _buildSpotifyUrl(String rawUrl) {
    final normalized = rawUrl.trim();
    if (normalized.isEmpty) return null;
    if (_isValidSpotifyUrl(normalized)) return normalized;
    // Se o usuário colar apenas o caminho (ex: /artist/abc), prefixa domínio
    if (normalized.startsWith('/')) {
      return 'https://open.spotify.com$normalized';
    }
    return null; // inválido
  }

  String? _buildDeezerUrl(String rawUrl) {
    final normalized = rawUrl.trim();
    if (normalized.isEmpty) return null;
    if (_isValidDeezerUrl(normalized)) return normalized;
    if (normalized.startsWith('/')) {
      return 'https://www.deezer.com$normalized';
    }
    return null;
  }

  bool _isValidYouTubeUrl(String url) {
    if (url.trim().isEmpty) return false;
    final youtubeRegex = RegExp(
      r'^(https?://)?(www\.)?(youtube\.com|youtu\.be)/.+',
      caseSensitive: false,
    );
    return youtubeRegex.hasMatch(url.trim());
  }

  /// Extrai o videoId de uma URL do YouTube
  String? _extractYouTubeVideoId(String? originalUrl) {
    if (originalUrl == null || originalUrl.isEmpty) return null;

    var url = originalUrl.trim();

    final patterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/embed\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/v\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/shorts\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com\/live\/([a-zA-Z0-9_-]{11})'),
      RegExp(r'\?v=([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Constrói a preview do vídeo do YouTube
  Widget _buildYouTubePreview() {
    final videoId = _extractYouTubeVideoId(_youtubeController.text);
    if (videoId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto explicativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Iconsax.video_play, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este vídeo será exibido na visualização do seu perfil',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Thumbnail do vídeo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(11)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: 'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error_outline, size: 40),
                    ),
                  ),
                  // Overlay escuro com ícone de play
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isValidWebsiteUrl(String url) {
    if (url.trim().isEmpty) return false;
    final trimmedUrl = url.trim();
    return trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://');
  }

  Widget _buildSocialLinksBlock() {
    return Column(
      children: [
        const Text(
          'Links Sociais e Mídia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),

        // Instagram
        TextFormField(
          controller: _instagramController,
          decoration: InputDecoration(
            labelText: 'Instagram',
            hintText: 'seu_usuario',
            prefixText: '@ ',
            suffixIcon: _instagramController.text.isEmpty
                ? null
                : _isValidInstagramUsername(_instagramController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _instagramController.text.isNotEmpty
                ? (_isValidInstagramUsername(_instagramController.text)
                    ? '✓ instagram.com/${_instagramController.text.trim().replaceFirst('@', '')}'
                    : '✗ Usuário inválido. Use letras, números, . ou _')
                : null,
            helperStyle: TextStyle(
              color: _isValidInstagramUsername(_instagramController.text)
                  ? Colors.green
                  : Colors.red,
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.camera),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),

        // TikTok
        TextFormField(
          controller: _tiktokController,
          decoration: InputDecoration(
            labelText: 'TikTok',
            hintText: 'seu_usuario',
            prefixText: '@ ',
            suffixIcon: _tiktokController.text.isEmpty
                ? null
                : _isValidTikTokUsername(_tiktokController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _tiktokController.text.isNotEmpty
                ? (_isValidTikTokUsername(_tiktokController.text)
                    ? '✓ tiktok.com/@${_tiktokController.text.trim().replaceFirst('@', '')}'
                    : '✗ Usuário inválido. Use letras, números, . ou _')
                : null,
            helperStyle: TextStyle(
              color: _isValidTikTokUsername(_tiktokController.text)
                  ? Colors.green
                  : Colors.red,
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.musicnote),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),

        // Spotify
        TextFormField(
          controller: _spotifyController,
          decoration: InputDecoration(
            labelText: 'Spotify (artista, álbum, playlist)',
            hintText: 'https://open.spotify.com/artist/...',
            suffixIcon: _spotifyController.text.isEmpty
                ? null
                : _isValidSpotifyUrl(_spotifyController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _spotifyController.text.isNotEmpty
                ? (_isValidSpotifyUrl(_spotifyController.text)
                    ? '✓ Link válido'
                    : '✗ Use open.spotify.com ou spotify:')
                : 'Link opcional para músicos/bandas',
            helperStyle: TextStyle(
              color: _spotifyController.text.isEmpty
                  ? AppColors.textSecondary
                  : (_isValidSpotifyUrl(_spotifyController.text)
                      ? Colors.green
                      : Colors.red),
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.musicnote),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            if (!_isValidSpotifyUrl(value)) {
              return 'Link do Spotify inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // Deezer
        TextFormField(
          controller: _deezerController,
          decoration: InputDecoration(
            labelText: 'Deezer (artista, álbum, playlist)',
            hintText: 'https://www.deezer.com/artist/...',
            suffixIcon: _deezerController.text.isEmpty
                ? null
                : _isValidDeezerUrl(_deezerController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _deezerController.text.isNotEmpty
                ? (_isValidDeezerUrl(_deezerController.text)
                    ? '✓ Link válido'
                    : '✗ Use deezer.com ou deezer.page.link')
                : 'Link opcional para músicos/bandas',
            helperStyle: TextStyle(
              color: _deezerController.text.isEmpty
                  ? AppColors.textSecondary
                  : (_isValidDeezerUrl(_deezerController.text)
                      ? Colors.green
                      : Colors.red),
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.music_square),
          ),
          keyboardType: TextInputType.url,
          onChanged: (_) => setState(() {}),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            if (!_isValidDeezerUrl(value)) {
              return 'Link do Deezer inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),

        // YouTube - Vídeo de apresentação
        TextFormField(
          controller: _youtubeController,
          decoration: InputDecoration(
            labelText: 'Vídeo de Apresentação (YouTube)',
            hintText: 'https://youtube.com/watch?v=...',
            suffixIcon: _youtubeController.text.isEmpty
                ? null
                : _isValidYouTubeUrl(_youtubeController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _youtubeController.text.isEmpty
                ? 'Adicione um vídeo do YouTube para destacar seu perfil!'
                : (_isValidYouTubeUrl(_youtubeController.text)
                    ? '✓ Vídeo encontrado'
                    : '✗ URL inválida. Use: youtube.com ou youtu.be'),
            helperMaxLines: 2,
            helperStyle: TextStyle(
              color: _youtubeController.text.isEmpty
                  ? AppColors.textSecondary
                  : (_isValidYouTubeUrl(_youtubeController.text)
                      ? Colors.green
                      : Colors.red),
              fontSize: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.play_circle),
          ),
          onChanged: (_) => setState(() {}),
        ),
        
        // ✅ Preview do vídeo do YouTube
        if (_youtubeController.text.isNotEmpty && _isValidYouTubeUrl(_youtubeController.text))
          _buildYouTubePreview(),
      ],
    );
  }

  String _sanitizeProfileUsername(String value) {
    final trimmed = value.trim();
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return withoutAt.replaceAll(RegExp(r'\s+'), '');
  }

  bool _isBasicProfileUsernameValid(String value) {
    final sanitized = _sanitizeProfileUsername(value);
    if (sanitized.length < 3) return false;
    final regex = RegExp(r'^[A-Za-z0-9._]+$');
    return regex.hasMatch(sanitized);
  }

  bool get _shouldDisableSaveButton {
    if (_isSaving) return true;
    if (!widget.isNewProfile) return false;

    final text = _profileUsernameController.text;
    final basicValid = _isBasicProfileUsernameValid(text);

    // ✅ Evita "Salvar" enquanto verifica / quando já sabemos que está em uso
    if (basicValid && _isCheckingUsername) return true;
    if (basicValid && _isUsernameAvailable == false) return true;
    return false;
  }

  List<String> _generateUsernameSuggestionsFromUsername(String baseUsername) {
    final base = _sanitizeProfileUsername(baseUsername).toLowerCase();
    if (base.length < 3) return [];

    String clamp20(String value) =>
        value.length <= 20 ? value : value.substring(0, 20);

    final suggestions = <String>[
      clamp20(base),
      clamp20('${base}1'),
      clamp20('${base}2'),
      clamp20('${base}3'),
      clamp20('${base}4'),
    ];

    return suggestions
        .where((s) => s.length >= 3)
        .where((s) => RegExp(r'^[a-z0-9._]+$').hasMatch(s))
        .toSet()
        .take(5)
        .toList();
  }

  List<String> _generateFallbackUsernameSuggestions(String baseUsername) {
    final base = _sanitizeProfileUsername(baseUsername).toLowerCase();
    if (base.length < 3) return [];

    String clamp20(String value) =>
        value.length <= 20 ? value : value.substring(0, 20);

    final year = DateTime.now().year;
    final shortYear = year % 100;
    final stamp = DateTime.now().millisecondsSinceEpoch % 1000;

    final candidates = <String>[
      clamp20('${base}_$year'),
      clamp20('$base$year'),
      clamp20('${base}_$shortYear'),
      clamp20('$base$shortYear'),
      clamp20('${base}_$stamp'),
      clamp20('$base$stamp'),
      clamp20('${base}01'),
      clamp20('${base}99'),
    ];

    return candidates
        .where((s) => s.length >= 3)
        .where((s) => RegExp(r'^[a-z0-9._]+$').hasMatch(s))
        .toSet()
        .take(8)
        .toList();
  }

  Future<bool> _isUsernameAvailableRemote(String normalizedUsername) async {
    final usernameLowercase = normalizedUsername.toLowerCase();
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .where('usernameLowercase', isEqualTo: usernameLowercase)
        .limit(1)
        .get();
    return snapshot.docs.isEmpty;
  }

  Future<void> _autoPickFirstAvailableUsernameSuggestion(
    List<String> suggestions,
  ) async {
    if (!widget.isNewProfile) return;
    if (suggestions.isEmpty) return;
    if (!mounted) return;

    final generation = ++_usernameAutoResolveGeneration;

    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
      _lastCheckedUsername = null;
    });

    final checked = <String>{};

    for (final rawSuggestion in suggestions) {
      if (!mounted) return;
      if (generation != _usernameAutoResolveGeneration) return;

      final candidate = _sanitizeProfileUsername(rawSuggestion);
      if (!_isBasicProfileUsernameValid(candidate)) {
        continue;
      }

      final normalized = candidate.toLowerCase();
      if (checked.contains(normalized)) continue;
      checked.add(normalized);

      bool available;
      try {
        available = await _isUsernameAvailableRemote(candidate);
      } catch (_) {
        // Em caso de falha na rede, não travar o usuário aqui; deixa para validar no save.
        if (!mounted) return;
        if (generation != _usernameAutoResolveGeneration) return;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = null;
        });
        return;
      }

      if (!mounted) return;
      if (generation != _usernameAutoResolveGeneration) return;

      if (available) {
        _profileUsernameController.text = candidate;
        setState(() {
          _isCheckingUsername = false;
          _isUsernameAvailable = true;
          _lastCheckedUsername = candidate.toLowerCase();
        });
        return;
      }
    }

    // ✅ Nenhuma sugestão inicial funcionou: gerar variações e tentar mais algumas
    final base = _profileUsernameController.text.trim().isNotEmpty
        ? _profileUsernameController.text
        : _sanitizeProfileUsername(suggestions.first);
    final fallback = _generateFallbackUsernameSuggestions(base);
    if (fallback.isNotEmpty) {
      final merged = <String>{
        ...suggestions.map(_sanitizeProfileUsername),
        ...fallback.map(_sanitizeProfileUsername),
      }
          .where((s) => s.trim().isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _usernameSuggestions = merged.take(8).toList();
        });
      }

      for (final rawSuggestion in fallback) {
        if (!mounted) return;
        if (generation != _usernameAutoResolveGeneration) return;

        final candidate = _sanitizeProfileUsername(rawSuggestion);
        if (!_isBasicProfileUsernameValid(candidate)) {
          continue;
        }

        final normalized = candidate.toLowerCase();
        if (checked.contains(normalized)) continue;
        checked.add(normalized);

        bool available;
        try {
          available = await _isUsernameAvailableRemote(candidate);
        } catch (_) {
          if (!mounted) return;
          if (generation != _usernameAutoResolveGeneration) return;
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = null;
          });
          return;
        }

        if (!mounted) return;
        if (generation != _usernameAutoResolveGeneration) return;

        if (available) {
          _profileUsernameController.text = candidate;
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = true;
            _lastCheckedUsername = candidate.toLowerCase();
          });
          return;
        }
      }
    }

    if (!mounted) return;
    if (generation != _usernameAutoResolveGeneration) return;

    // Nenhuma sugestão disponível
    final first = _sanitizeProfileUsername(suggestions.first);
    if (_profileUsernameController.text.trim().isEmpty) {
      _profileUsernameController.text = first;
    }
    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = false;
      _lastCheckedUsername = first.toLowerCase();
    });
  }

  String? _validateProfileUsername(String? value) {
    if (_isUsernameLocked) {
      return null;
    }
    final sanitized = _sanitizeProfileUsername(value ?? '');
    if (sanitized.isEmpty) {
      return 'Nome de usuário é obrigatório';
    }
    if (sanitized.length < 3) {
      return 'Mínimo de 3 caracteres';
    }
    final regex = RegExp(r'^[A-Za-z0-9._]+$');
    if (!regex.hasMatch(sanitized)) {
      return 'Use letras, números, ponto ou underline';
    }
    // ✅ Validação de disponibilidade em tempo real (apenas para novos perfis)
    if (widget.isNewProfile && _isUsernameAvailable == false) {
      return 'Este nome de usuário já está em uso';
    }
    return null;
  }

  /// ✅ Verifica disponibilidade do username em tempo real com debounce
  void _checkUsernameAvailability(String username) {
    // Só verifica em tempo real para novos perfis
    if (!widget.isNewProfile) return;

    // Usuário começou a digitar: cancela qualquer auto-seleção em andamento
    _usernameAutoResolveGeneration++;
    
    // Cancelar timer anterior
    _usernameDebounceTimer?.cancel();
    
    final normalizedUsername = _sanitizeProfileUsername(username).toLowerCase();
    
    // Se username inválido ou muito curto, resetar estado
    if (normalizedUsername.isEmpty || normalizedUsername.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
        _lastCheckedUsername = null;
      });
      return;
    }
    
    // Se já verificou este username, não verificar novamente
    if (_lastCheckedUsername == normalizedUsername) {
      return;
    }
    
    // Mostrar loading
    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });
    
    // Debounce de 500ms para não sobrecarregar o Firestore
    _usernameDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      
      try {
        debugPrint('🔍 EditProfile: Verificando disponibilidade de @$normalizedUsername...');
        
        final snapshot = await FirebaseFirestore.instance
            .collection('profiles')
            .where('usernameLowercase', isEqualTo: normalizedUsername)
            .limit(1)
            .get();
        
        if (!mounted) return;
        
        final isAvailable = snapshot.docs.isEmpty;
        
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
          _lastCheckedUsername = normalizedUsername;
        });
        
        debugPrint(isAvailable 
            ? '✅ EditProfile: @$normalizedUsername está disponível!' 
            : '❌ EditProfile: @$normalizedUsername já está em uso');
            
      } catch (e) {
        debugPrint('⚠️ EditProfile: Erro ao verificar username: $e');
        if (mounted) {
          setState(() {
            _isCheckingUsername = false;
            _isUsernameAvailable = null;
          });
        }
      }
    });
  }

  /// ✅ Ícone de status no sufixo do campo username (apenas para novos perfis)
  Widget? _buildUsernameSuffixIcon() {
    // Só mostra indicadores para novos perfis
    if (!widget.isNewProfile) return null;
    
    final username = _profileUsernameController.text.trim();
    
    // Não mostrar nada se username muito curto
    if (username.length < 3) return null;
    
    if (_isCheckingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }
    
    if (_isUsernameAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    
    if (_isUsernameAvailable == false) {
      return const Icon(Icons.cancel, color: AppColors.error);
    }
    
    return null;
  }

  /// ✅ Indicador de disponibilidade abaixo do campo (apenas para novos perfis)
  Widget _buildUsernameAvailabilityIndicator() {
    // Só mostra indicadores para novos perfis
    if (!widget.isNewProfile) return const SizedBox.shrink();
    
    final username = _profileUsernameController.text.trim();
    
    // Não mostrar nada se username muito curto ou validação básica falhou
    if (username.length < 3 || !RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(username)) {
      return const SizedBox.shrink();
    }
    
    if (_isCheckingUsername) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 12),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Verificando disponibilidade...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isUsernameAvailable == true) {
      return const Padding(
        padding: EdgeInsets.only(top: 6, left: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 14),
            SizedBox(width: 6),
            Text(
              'Nome de usuário disponível!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_isUsernameAvailable == false) {
      return Padding(
        padding: const EdgeInsets.only(top: 6, left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: AppColors.error, size: 14),
                SizedBox(width: 6),
                Text(
                  'Este nome de usuário já está em uso',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _usernameSuggestions.isNotEmpty
                  ? 'Escolha uma sugestão abaixo para continuar.'
                  : 'Tente adicionar números no final para ficar único.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// ✅ Mostra sugestões de username baseadas no nome do login social
  Widget _buildUsernameSuggestions() {
    // Só mostra se há sugestões e é novo perfil
    if (!widget.isNewProfile || _usernameSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugestões de username:',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _usernameSuggestions.take(5).map((suggestion) {
              final isSelected = _profileUsernameController.text.trim().toLowerCase() == suggestion.toLowerCase();
              return InkWell(
                onTap: () {
                  setState(() {
                    _profileUsernameController.text = suggestion;
                    // Reset estado de verificação para verificar a nova sugestão
                    _isUsernameAvailable = null;
                    _lastCheckedUsername = null;
                  });
                  // Disparar verificação de disponibilidade
                  _checkUsernameAvailability(suggestion);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppColors.primary.withOpacity(0.2) 
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.primary 
                          : AppColors.primary.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '@$suggestion',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _ensureProfileUsernameUnique(
    String username, {
    String? excludeProfileId,
  }) async {
    final usernameLowercase = username.toLowerCase();
    final snapshot = await FirebaseFirestore.instance
        .collection('profiles')
        .where('usernameLowercase', isEqualTo: usernameLowercase)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return;

    final existingId = snapshot.docs.first.id;
    if (excludeProfileId == null || existingId != excludeProfileId) {
      throw Exception('Este nome de usuário já está em uso');
    }
  }
}

class _BrazilianPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Permite digitação livre se estiver apagando
    if (newValue.text.length < oldValue.text.length) {
      return newValue;
    }

    String text = newValue.text;

    // Remove todos os caracteres não numéricos
    text = text.replaceAll(RegExp(r'\D'), '');

    // Limita a 11 dígitos (DDD + 9 dígitos)
    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    final buffer = StringBuffer();

    if (text.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Aplica formatação progressiva
    if (text.length <= 2) {
      buffer.write('(');
      buffer.write(text);
    } else if (text.length <= 6) {
      buffer.write('(');
      buffer.write(text.substring(0, 2));
      buffer.write(') ');
      buffer.write(text.substring(2));
    } else if (text.length <= 10) {
      buffer.write('(');
      buffer.write(text.substring(0, 2));
      buffer.write(') ');
      buffer.write(text.substring(2, 6));
      buffer.write('-');
      buffer.write(text.substring(6));
    } else {
      // 11 dígitos: (XX) XXXXX-XXXX
      buffer.write('(');
      buffer.write(text.substring(0, 2));
      buffer.write(') ');
      buffer.write(text.substring(2, 7));
      buffer.write('-');
      buffer.write(text.substring(7));
    }

    final formattedText = buffer.toString();

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
