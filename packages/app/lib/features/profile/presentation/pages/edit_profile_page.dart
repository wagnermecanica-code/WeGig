import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';
import 'package:core_ui/features/profile/domain/entities/profile_entity.dart';
import 'package:core_ui/profile_result.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/app_snackbar.dart';
import 'package:core_ui/utils/debouncer.dart';
import 'package:core_ui/utils/location_utils.dart';
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
import 'package:wegig_app/app/router/app_router.dart';
import 'package:wegig_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:wegig_app/features/profile/presentation/providers/profile_providers.dart';

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
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();

  bool _isSaving = false;
  bool _isLoadingProfile = true;
  ProfileEntity? _profile;
  String? _photoUrl;
  bool? _isBand;
  final _locationDebouncer = Debouncer(milliseconds: 500);
  String? _selectedLevel;
  Set<String> _selectedInstruments = {};
  Set<String> _selectedGenres = {};

  GeoPoint? _selectedLocation;
  String? _selectedCity;
  String? _selectedNeighborhood;
  String? _selectedState;
  String? _accountUsername;

  // Computed property para evitar lógica no build
  bool get _isFirstAccess => _profile == null && !_isLoadingProfile;
  bool get _canNavigateBack => widget.isNewProfile || !_isFirstAccess;

  bool get _isUsernameLocked {
    final savedUsername = (_profile?.username ?? _accountUsername)?.trim();
    return !widget.isNewProfile && (savedUsername?.isNotEmpty ?? false);
  }

  static const int maxBioLength = 110;
  static const int maxInstruments = 5;
  static const int maxGenres = 3;

  static const List<String> _levelOptions = [
    'Iniciante',
    'Intermediário',
    'Avançado',
    'Profissional',
  ];

  static const List<String> _instrumentOptions = [
    'Violão',
    'Guitarra',
    'Baixo',
    'Contrabaixo',
    'Bateria',
    'Teclado',
    'Piano',
    'Saxofone',
    'Flauta',
    'Trompete',
    'Violino',
    'Cello',
    'Voz (cantor)',
    'DJ',
    'Percussão',
    'Harmônica',
    'Ukulele',
  ];

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
    'Folk',
    'Country',
    'Classical',
    'Metal',
    'Punk',
    'Indie',
    'Samba',
    'Bossa Nova',
    'Gospel',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _birthYearController.dispose();
    _locationController.dispose();
    _profileUsernameController.dispose();
    _locationFocusNode.dispose();
    _youtubeController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _locationDebouncer.dispose(); // ✅ Cancela Timer pendente
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
            _profileUsernameController.text =
                _sanitizeProfileUsername(username);
          }
        }
      }

      // Se é novo perfil, deixa tudo vazio
      if (widget.isNewProfile) {
        debugPrint('EditProfile: Modo novo perfil - campos vazios');
        setState(() => _isLoadingProfile = false);
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
          _instagramController.text = profile.instagramLink ?? '';
          _tiktokController.text = profile.tiktokLink ?? '';
          _photoUrl = profile.photoUrl;
          _isBand = profile.isBand;
          _selectedLevel = profile.level;
          _selectedInstruments = {...?profile.instruments};
          _selectedGenres = {...?profile.genres};
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
          _instagramController.text = activeProfile.instagramLink ?? '';
          _tiktokController.text = activeProfile.tiktokLink ?? '';
          _photoUrl = activeProfile.photoUrl;
          _isBand = activeProfile.isBand;
          _selectedLevel = activeProfile.level;
          _selectedInstruments = {...?activeProfile.instruments};
          _selectedGenres = {...?activeProfile.genres};
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

      // Crop da imagem com opções de aspect ratio
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        compressQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
        compressFormat: ImageCompressFormat.jpg,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Foto de Perfil',
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            statusBarColor: AppColors.primary,
            backgroundColor: Colors.black,
            activeControlsWidgetColor: AppColors.primary,
            initAspectRatio: CropAspectRatioPreset.square,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
            ],
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Editar Foto de Perfil',
            minimumAspectRatio: 0.5,
            aspectRatioLockDimensionSwapEnabled: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.original,
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
  }) async {
    final profileNotifier = ref.read(profileProvider.notifier);
    try {
      await profileNotifier.refresh();
    } catch (_) {
      if (mounted) {
        ref.invalidate(profileProvider);
      }
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
      debugPrint('EditProfile: Primeiro perfil criado, indo para home');
      router.go(AppRoutes.home);
    } else {
      if (navigator.canPop()) {
        navigator.pop(profile.profileId);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Executa navegação após a finalização do pop para evitar flicker
        router.go(AppRoutes.profile(profile.profileId));
      });
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar tipo de perfil (obrigatório na primeira edição)
    if (_isBand == null) {
      AppSnackBar.showWarning(
        context,
        'Por favor, selecione o tipo de perfil (Músico ou Banda)',
      );
      return;
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
          isBand: _isBand!,
          level: !_isBand! ? _selectedLevel : null,
          instruments: _selectedInstruments.toList(),
          genres: _selectedGenres.toList(),
          youtubeLink: _youtubeController.text.trim().isEmpty
              ? null
              : _youtubeController.text.trim(),
          instagramLink: _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          tiktokLink: _tiktokController.text.trim().isEmpty
              ? null
              : _tiktokController.text.trim(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // ✅ Usar profileProvider.notifier (Clean Architecture)
        final result =
            await ref.read(profileProvider.notifier).createProfile(newProfile);

        switch (result) {
          case ProfileSuccess(:final profile):
            debugPrint(
                '✅ EditProfile: Perfil criado - ID=${profile.profileId}');

            final profileNotifier = ref.read(profileProvider.notifier);
            await profileNotifier.switchProfile(profile.profileId);

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

            if (mounted) {
              ref.invalidate(userDocumentProvider);
            }

            await _handleSuccessfulProfileSave(
              profile,
              isCreation: true,
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
          isBand: _isBand ?? false,
          level: !(_isBand ?? false) ? _selectedLevel : null,
          instruments: _selectedInstruments.toList(),
          genres: _selectedGenres.toList(),
          youtubeLink: _youtubeController.text.trim().isEmpty
              ? null
              : _youtubeController.text.trim(),
          instagramLink: _instagramController.text.trim().isEmpty
              ? null
              : _instagramController.text.trim(),
          tiktokLink: _tiktokController.text.trim().isEmpty
              ? null
              : _tiktokController.text.trim(),
          updatedAt: DateTime.now(),
        );

        // ✅ Usar profileProvider.notifier (Clean Architecture)
        final result = await ref
            .read(profileProvider.notifier)
            .updateProfile(updatedProfile);

        switch (result) {
          case ProfileSuccess(:final profile):
            debugPrint(
                '✅ EditProfile: Perfil atualizado - ID=${profile.profileId}');

            await _handleSuccessfulProfileSave(
              profile,
              isCreation: false,
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
                  onPressed: () => Navigator.of(context).maybePop(),
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

                    // C. Bloco de Habilidades (adaptável)
                    _buildSkillsBlock(),
                    const SizedBox(height: 24),

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
                onPressed: _isSaving ? null : _saveProfile,
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
    final usernameValue = (_accountUsername ?? _profile?.username)?.trim();
    final hasUsername = usernameValue != null && usernameValue.isNotEmpty;
    final sanitizedUsername = hasUsername
        ? (usernameValue!.startsWith('@')
            ? usernameValue.substring(1)
            : usernameValue)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon:
                  const Icon(Icons.alternate_email, color: AppColors.primary),
            ),
            validator: _validateProfileUsername,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.none,
          ),
        ],
        const SizedBox(height: 16),

        // Nome
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome',
            hintText: _isBand ?? false ? 'Nome da banda' : 'Seu nome',
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
            hintText: _isBand ?? false
                ? 'Conte sobre a banda, estilo, história...'
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
            labelText:
                _isBand ?? false ? 'Ano de formação' : 'Ano de nascimento',
            hintText: _isBand ?? false
                ? 'Quando a banda foi formada'
                : 'Seu ano de nascimento',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon:
                Icon(_isBand ?? false ? Iconsax.calendar : Iconsax.cake),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return null; // Campo opcional
            }

            final yearStr = value.trim();
            final year = int.tryParse(yearStr);

            if (year == null) {
              return 'Digite apenas números';
            }

            final currentYear = DateTime.now().year;

            if (_isBand ?? false) {
              // BANDAS: Validação de ano de formação
              if (year < 1900) {
                return 'Ano muito antigo (mínimo: 1900)';
              }
              if (year > currentYear) {
                return 'Ano não pode ser no futuro';
              }
            } else {
              // MÚSICOS: Validação de idade (13 a 120 anos)
              final age = currentYear - year;

              // Idade muito baixa (< 13 anos)
              if (age < 13) {
                return 'Idade mínima é 13 anos (ano máximo: ${currentYear - 13})';
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
          suggestionsCallback: _fetchAddressSuggestions,
          builder: (context, controller, focusNode) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Buscar localização (cidade, bairro, endereço...)',
                prefixIcon:
                    const Icon(Iconsax.location, color: AppColors.primary),
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
          itemBuilder: (BuildContext context, Map<String, dynamic> suggestion) {
            return ListTile(
              leading: const Icon(Iconsax.location, color: AppColors.primary),
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
      ],
    );
  }

  Widget _buildTypologyBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        if (_isBand == null)
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
                isSelected: _isBand == false,
                onTap: () => setState(() => _isBand = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                icon: Iconsax.people,
                label: 'Banda',
                isSelected: _isBand ?? false,
                onTap: () => setState(() => _isBand = true),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          title: _isBand ?? false ? 'Instrumentação' : 'Instrumentos',
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
        const SizedBox(height: 16),

        // Nível (apenas para músicos)
        if (_isBand == false) ...[
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
            items: _levelOptions
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

  bool _isValidInstagramUrl(String url) {
    if (url.trim().isEmpty) return false;
    final instagramRegex = RegExp(
      r'^(https?://)?(www\.)?(instagram\.com|instagr\.am)/([a-zA-Z0-9._]+)/?',
      caseSensitive: false,
    );
    return instagramRegex.hasMatch(url.trim());
  }

  bool _isValidTikTokUrl(String url) {
    if (url.trim().isEmpty) return false;
    final tiktokRegex = RegExp(
      r'^(https?://)?(www\.)?(tiktok\.com|vm\.tiktok\.com)/@?([a-zA-Z0-9._]+)/?',
      caseSensitive: false,
    );
    return tiktokRegex.hasMatch(url.trim());
  }

  bool _isValidYouTubeUrl(String url) {
    if (url.trim().isEmpty) return false;
    final youtubeRegex = RegExp(
      r'^(https?://)?(www\.)?(youtube\.com|youtu\.be)/.+',
      caseSensitive: false,
    );
    return youtubeRegex.hasMatch(url.trim());
  }

  Widget _buildSocialLinksBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            hintText: 'https://instagram.com/seu_perfil',
            suffixIcon: _instagramController.text.isEmpty
                ? null
                : _isValidInstagramUrl(_instagramController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _instagramController.text.isNotEmpty
                ? (_isValidInstagramUrl(_instagramController.text)
                    ? '✓ Link válido'
                    : '✗ URL inválida. Use: instagram.com/perfil')
                : null,
            helperStyle: TextStyle(
              color: _isValidInstagramUrl(_instagramController.text)
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
            hintText: 'https://tiktok.com/@seu_perfil',
            suffixIcon: _tiktokController.text.isEmpty
                ? null
                : _isValidTikTokUrl(_tiktokController.text)
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.error_outline, color: Colors.red),
            helperText: _tiktokController.text.isNotEmpty
                ? (_isValidTikTokUrl(_tiktokController.text)
                    ? '✓ Link válido'
                    : '✗ URL inválida. Use: tiktok.com/@perfil')
                : null,
            helperStyle: TextStyle(
              color: _isValidTikTokUrl(_tiktokController.text)
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

        // YouTube
        TextFormField(
          controller: _youtubeController,
          decoration: InputDecoration(
            labelText: 'YouTube',
            hintText: 'https://youtube.com/watch?v=...',
            suffixIcon: _youtubeController.text.isEmpty
                ? null
                : _isValidYouTubeUrl(_youtubeController.text)
                    ? const Icon(Iconsax.tick_circle, color: Colors.green)
                    : const Icon(Iconsax.danger, color: Colors.red),
            helperText: _youtubeController.text.isNotEmpty
                ? (_isValidYouTubeUrl(_youtubeController.text)
                    ? '✓ Vídeo encontrado'
                    : '✗ URL inválida. Use: youtube.com ou youtu.be')
                : 'Cole o link completo (será convertido para shortlink)',
            helperStyle: _youtubeController.text.isEmpty
                ? null
                : TextStyle(
                    color: _isValidYouTubeUrl(_youtubeController.text)
                        ? Colors.green
                        : Colors.red,
                    fontSize: 12,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Iconsax.play_circle),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  String _sanitizeProfileUsername(String value) {
    final trimmed = value.trim();
    final withoutAt = trimmed.startsWith('@') ? trimmed.substring(1) : trimmed;
    return withoutAt.replaceAll(RegExp(r'\s+'), '');
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
    return null;
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
