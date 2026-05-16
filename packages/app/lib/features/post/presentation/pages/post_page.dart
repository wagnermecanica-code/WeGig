import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/post_result.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/music_constants.dart';
import 'package:core_ui/widgets/app_loading_overlay.dart';
import 'package:core_ui/widgets/multi_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
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
  final _spotifyController = TextEditingController();
  final _deezerController = TextEditingController();
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

  // === Data de contratação/apresentação (hiring) ===
  DateTime? _hiringDate;
  final Set<String> _selectedEventTypes = <String>{};
  final Set<String> _selectedGigFormats = <String>{};
  String? _budgetRange;
  final Set<String> _venueSetup = <String>{};
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int? _eventDurationMinutes;
  final TextEditingController _guestCountController = TextEditingController();

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
  bool _isFreeProduct = false; // Produto/serviço gratuito
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
    'Open Mic',
    'Aula/Workshop',
    'Freela',
    'Promoção',
    'Manutenção/Reparo',
    'Outro',
  ];
  
  // === Erros de validação ===
  String? _instrumentsError;
  String? _genresError;
  String? _eventTypeError;
  String? _budgetError;
  String? _dateError;
  String? _timeError;
  String? _guestCountError;
  String? _messageError;
  String? _photoError;
  String? _titleError;
  String? _priceError;

 // Lista para disponibilidade
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
    _spotifyController.text = (data['spotifyLink'] as String?) ?? '';
    _deezerController.text = (data['deezerLink'] as String?) ?? '';
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

    // Data de contratação (hiring)
    final dynamic hiringDateRaw =
        data['eventDate'] ?? data['hiringDate'] ?? data['gigDate'];
    final parsedHiringDate = _maybeExtractDate(hiringDateRaw);
    if (parsedHiringDate != null) {
      _hiringDate = parsedHiringDate;
    }

    // Campos específicos de hiring
    setState(() {
      _selectedEventTypes
        ..clear()
        ..addAll(_normalizeListOrSingle(data['eventType']));

      _selectedGigFormats
        ..clear()
        ..addAll(_normalizeListOrSingle(data['gigFormat']));

      _budgetRange = data['budgetRange'] as String?;

      if (data['venueSetup'] is List) {
        _venueSetup
          ..clear()
          ..addAll((data['venueSetup'] as List).cast<String>());
      }

      final guestCountRaw = data['guestCount'];
      if (guestCountRaw is num) {
        _guestCountController.text = guestCountRaw.toInt().toString();
      } else if (guestCountRaw is String && guestCountRaw.isNotEmpty) {
        _guestCountController.text = guestCountRaw;
      }

      final startStr = data['eventStartTime'] as String?;
      final endStr = data['eventEndTime'] as String?;
      _startTime = _parseTimeOfDay(startStr);
      _endTime = _parseTimeOfDay(endStr);

      final durationRaw = data['eventDurationMinutes'];
      if (durationRaw is num) {
        _eventDurationMinutes = durationRaw.toInt();
      } else {
        _eventDurationMinutes = _durationFromTimes(_startTime, _endTime);
      }
    });

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

    // ✅ SALES FIELDS - Carregar campos específicos de anúncios
    if (_postType == 'sales') {
      _titleController.text = (data['title'] as String?) ?? '';
      _salesType = (data['salesType'] as String?) ?? 'Venda';
      _whatsappController.text = (data['whatsappNumber'] as String?) ?? '';
      
      // Preço - agora data['price'] é o preço ORIGINAL (sem desconto)
      final originalPrice = data['price'];
      
      // ✅ Verificar se é gratuito (preço = 0 ou null)
      if (originalPrice == null || (originalPrice is num && originalPrice == 0)) {
        _isFreeProduct = true;
        _priceController.clear();
      } else if (originalPrice is num && originalPrice > 0) {
        _isFreeProduct = false;
        // Converter para centavos (formato esperado pelo _CurrencyInputFormatter)
        final priceInCents = (originalPrice.toDouble() * 100).toInt();
        _priceController.text = priceInCents.toString();
      }
      
      // Modo de desconto e valor
      _discountMode = (data['discountMode'] as String?) ?? 'none';
      final discountValue = data['discountValue'];
      if (discountValue != null && _discountMode != 'none') {
        if (discountValue is num) {
          if (_discountMode == 'fixed') {
            // Desconto fixo: converter para centavos
            final discountInCents = (discountValue * 100).toInt();
            _discountController.text = discountInCents.toString();
          } else if (_discountMode == 'percentage') {
            // Percentual: já é número inteiro (ex: 20 para 20%)
            _discountController.text = discountValue.toInt().toString();
          }
        } else if (discountValue is String) {
          final cleaned = discountValue.replaceAll(RegExp(r'[^\d]'), '');
          _discountController.text = cleaned.isEmpty ? '' : cleaned;
        }
      }
      
      // Datas da promoção
      if (data['promoStartDate'] != null) {
        if (data['promoStartDate'] is Timestamp) {
          _promoStartDate = (data['promoStartDate'] as Timestamp).toDate();
        } else if (data['promoStartDate'] is DateTime) {
          _promoStartDate = data['promoStartDate'] as DateTime;
        }
      }
      
      if (data['promoEndDate'] != null) {
        if (data['promoEndDate'] is Timestamp) {
          _promoEndDate = (data['promoEndDate'] as Timestamp).toDate();
        } else if (data['promoEndDate'] is DateTime) {
          _promoEndDate = data['promoEndDate'] as DateTime;
        }
      }
      
      // Recalcular preço final após carregar dados
      _calculateFinalPrice();
      
      debugPrint('''
✅ Sales fields loaded:
   Title: ${_titleController.text}
   Sales Type: $_salesType
   Price: ${_priceController.text}
   Discount Mode: $_discountMode
   Discount Value: ${_discountController.text}
   WhatsApp: ${_whatsappController.text}
   Promo Start: $_promoStartDate
   Promo End: $_promoEndDate
''');
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
    _spotifyController.dispose();
    _deezerController.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    _guestCountController.dispose();
    
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
      setState(
        () => _calculatedFinalPrice = (price / 100) * (1 - discountValue / 100),
      );
    } else if (_discountMode == 'fixed') {
      setState(() => _calculatedFinalPrice = (price / 100) - (discountValue / 100));
    }
  }

  TimeOfDay? _parseTimeOfDay(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return 'Selecionar horário';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _timeToString(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _recalculateDuration() {
    if (_startTime == null || _endTime == null) {
      setState(() => _eventDurationMinutes = null);
      return;
    }
    final duration = _durationFromTimes(_startTime!, _endTime!);
    setState(() => _eventDurationMinutes = duration);
  }

  int? _durationFromTimes(TimeOfDay? start, TimeOfDay? end) {
    if (start == null || end == null) return null;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes
        ? endMinutes - startMinutes
        : (endMinutes + 1440) - startMinutes; // cruza meia-noite
  }

  IconData _iconForPostType() {
    switch (_postType) {
      case 'musician':
        return Icons.person;
      case 'band':
        return Icons.groups;
      case 'sales':
        return Icons.store;
      case 'hiring':
        return Icons.work_outline;
      default:
        return Icons.person;
    }
  }

  String _headerTitle() {
    if (widget.existingPostData != null) {
      switch (_postType) {
        case 'sales':
          return 'Editar anúncio';
        case 'hiring':
          return 'Editar oportunidade';
        default:
          return 'Editar post';
      }
    }

    switch (_postType) {
      case 'sales':
        return 'Quero oferecer um\nproduto ou serviço';
      case 'musician':
        return 'Quero me juntar\na uma banda';
      case 'band':
        return 'Quero encontrar\num músico';
      case 'hiring':
        return 'Quero contratar\num músico ou banda';
      default:
        return 'Criar post';
    }
  }

  Future<void> _submitPost() async {
    _resetFieldErrors();

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Complete os campos destacados para continuar.', isError: true);
      return;
    }

    // Validações específicas por tipo
    if (_postType == 'sales') {
      // Sales: fotos, título, descrição, tipo, preço, localização (SEM gêneros/instrumentos)
      if (_photoPaths.isEmpty) {
        setState(() => _photoError = 'Adicione pelo menos uma foto para anunciar.');
        _showSnackBar('Inclua pelo menos uma foto para o anúncio.', isError: true);
        return;
      }
      if (_titleController.text.trim().isEmpty) {
        setState(() => _titleError = 'Informe um título para o anúncio.');
        _showSnackBar('Informe um título para o anúncio.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        setState(() => _messageError = 'Descreva o que está oferecendo.');
        _showSnackBar('Descreva o que está oferecendo.', isError: true);
        return;
      }
      // Preço obrigatório apenas se não for gratuito
      if (!_isFreeProduct && (_priceController.text.isEmpty || _calculatedFinalPrice <= 0)) {
        setState(() => _priceError = 'Defina um preço ou marque como gratuito.');
        _showSnackBar('Defina um preço ou marque como gratuito.', isError: true);
        return;
      }
      if (_promoEndDate.isBefore(_promoStartDate)) {
        _showSnackBar('A data final da promoção deve ser após a data inicial.', isError: true);
        return;
      }
      // Sales NÃO precisa de gêneros ou instrumentos
    } else if (_postType == 'musician') {
      // Musician: instrumentos, gêneros, descrição, localização
      if (_selectedInstruments.isEmpty) {
        setState(() => _instrumentsError = 'Selecione pelo menos um instrumento.');
        _showSnackBar('Escolha pelo menos um instrumento para continuar.', isError: true);
        return;
      }
      if (_selectedGenres.isEmpty) {
        setState(() => _genresError = 'Selecione pelo menos um gênero.');
        _showSnackBar('Escolha pelo menos um gênero musical.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        setState(() => _messageError = 'Conte mais sobre você ou sua busca.');
        _showSnackBar('Descreva sua mensagem para continuar.', isError: true);
        return;
      }
    } else if (_postType == 'band') {
      // Band: músicos procurados, gêneros, descrição, localização
      if (_selectedInstruments.isEmpty) {
        setState(() => _instrumentsError = 'Liste quem você procura.');
        _showSnackBar('Informe pelo menos um músico ou instrumento procurado.', isError: true);
        return;
      }
      if (_selectedGenres.isEmpty) {
        setState(() => _genresError = 'Selecione pelo menos um gênero.');
        _showSnackBar('Escolha pelo menos um gênero musical.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        setState(() => _messageError = 'Conte mais sobre a vaga ou banda.');
        _showSnackBar('Descreva sua mensagem para continuar.', isError: true);
        return;
      }
    } else if (_postType == 'hiring') {
      // Hiring: texto obrigatório, recomenda-se detalhar perfil e gênero
      if (_selectedGenres.isEmpty) {
        setState(() => _genresError = 'Selecione pelo menos um gênero.');
        _showSnackBar('Escolha pelo menos um gênero musical.', isError: true);
        return;
      }
      if (_selectedEventTypes.isEmpty) {
        setState(() => _eventTypeError = 'Selecione o tipo de evento.');
        _showSnackBar('Escolha o tipo de evento.', isError: true);
        return;
      }
      if (_startTime == null || _endTime == null) {
        setState(() => _timeError = 'Defina início e término.');
        _showSnackBar('Defina horário de início e término.', isError: true);
        return;
      }
      if (_hiringDate == null) {
        setState(() => _dateError = 'Selecione a data.');
        _showSnackBar('Selecione a data da apresentação/contratação.', isError: true);
        return;
      }
      if (_budgetRange == null || _budgetRange!.isEmpty) {
        setState(() => _budgetError = 'Selecione o orçamento.');
        _showSnackBar('Informe o orçamento aproximado.', isError: true);
        return;
      }
      if (_guestCountController.text.trim().isEmpty ||
          int.tryParse(_guestCountController.text.trim()) == null) {
        setState(() => _guestCountError = 'Informe um número de convidados.');
        _showSnackBar('Informe a quantidade aproximada de convidados.', isError: true);
        return;
      }
      if (_messageController.text.trim().isEmpty) {
        setState(() => _messageError = 'Conte mais sobre a oportunidade.');
        _showSnackBar('Conte mais sobre a oportunidade.', isError: true);
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
        final computedExpiresAt = _postType == 'hiring' && _hiringDate != null
          ? _hiringDate!.add(const Duration(days: 1))
          : _maybeExtractDate(widget.existingPostData?['expiresAt']);

        final selectedEventType =
          _selectedEventTypes.isNotEmpty ? _selectedEventTypes.first : null;
        final selectedGigFormat =
          _selectedGigFormats.isNotEmpty ? _selectedGigFormats.first : null;

      final input = PostFormInput(
        postId: widget.existingPostData?['postId'] as String?,
        type: _postType,
        
        // Campos específicos de sales
        title: _postType == 'sales' ? _titleController.text.trim() : null,
        salesType: _postType == 'sales' ? _salesType : null,
        price: _postType == 'sales' 
            ? (_isFreeProduct ? 0.0 : (double.tryParse(_priceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0) / 100) 
            : null,
        discountMode: _postType == 'sales' && !_isFreeProduct ? _discountMode : null,
        discountValue: _postType == 'sales' && _discountController.text.isNotEmpty
            ? (_discountMode == 'fixed' 
                ? (double.tryParse(_discountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0) / 100
                : double.tryParse(_discountController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0.0)
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
        spotifyLink: _spotifyController.text.trim().isEmpty ? null : _spotifyController.text.trim(),
        deezerLink: _deezerController.text.trim().isEmpty ? null : _deezerController.text.trim(),
        eventDate: _postType == 'hiring' ? _hiringDate : null,
        eventType: _postType == 'hiring' ? selectedEventType : null,
        gigFormat: _postType == 'hiring' ? selectedGigFormat : null,
        venueSetup: _postType == 'hiring' ? _venueSetup.toList() : <String>[],
        budgetRange: _postType == 'hiring' ? _budgetRange : null,
        eventStartTime: _postType == 'hiring' ? _timeToString(_startTime) : null,
        eventEndTime: _postType == 'hiring' ? _timeToString(_endTime) : null,
        eventDurationMinutes: _postType == 'hiring' ? _eventDurationMinutes : null,
        guestCount: _postType == 'hiring'
          ? int.tryParse(_guestCountController.text.trim())
          : null,
        
        // Campos de musician/band (null para sales)
        level: _postType != 'sales' ? _level : null,
        genres: _postType != 'sales' ? _selectedGenres.toList() : <String>[],
        selectedInstruments: _postType != 'sales' ? _selectedInstruments.toList() : <String>[],
        availableFor: _postType != 'sales' ? _selectedAvailableFor.toList() : <String>[],
        
        createdAt: _maybeExtractDate(widget.existingPostData?['createdAt']),
        expiresAt: computedExpiresAt,
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

  void _resetFieldErrors() {
    setState(() {
      _instrumentsError = null;
      _genresError = null;
      _eventTypeError = null;
      _budgetError = null;
      _dateError = null;
      _timeError = null;
      _guestCountError = null;
      _messageError = null;
      _photoError = null;
      _titleError = null;
      _priceError = null;
    });
  }

  List<String> _normalizeListOrSingle(dynamic value) {
    if (value is String && value.isNotEmpty) return [value];
    if (value is List) {
      return value
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sectionTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );
    final headerIcon = _iconForPostType();
    final headerTitle = _headerTitle();
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
                  child: AppRadioPulseLoader(size: 24),
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
          child: AppRadioPulseLoader(size: 52),
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
                                      headerIcon,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                    errorWidget: (context, url, error) => Icon(
                                      headerIcon,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  )
                                : Icon(
                                    headerIcon,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            headerTitle,
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
                  else if (_postType == 'hiring')
                    ..._buildHiringFields()
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
      if (_photoError != null) ...[
        const SizedBox(height: 8),
        Text(
          _photoError!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ],
      const Divider(height: 48, thickness: 0.5),

      // 2. Título do anúncio
      const Text(
        'Título do anúncio *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _titleController,
        maxLength: 25,
        decoration: InputDecoration(
          hintText: 'Ex: Estúdio de gravação profissional',
          counterText: '${_titleController.text.length}/25',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (v) {
          if (_titleError != null) return _titleError;
          if (v == null || v.trim().isEmpty) return 'Título é obrigatório';
          return null;
        },
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
        validator: (v) {
          if (_messageError != null) return _messageError;
          if (v == null || v.trim().isEmpty) return 'Descrição é obrigatória';
          return null;
        },
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

      // 5. Toggle Gratuito + Preço
      Row(
        children: [
          const Text(
            'Preço',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const Spacer(),
          Text(
            'Gratuito',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _isFreeProduct ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: _isFreeProduct,
            activeColor: AppColors.success,
            onChanged: (value) {
              setState(() {
                _isFreeProduct = value;
                if (value) {
                  _priceController.clear();
                  _discountMode = 'none';
                  _discountController.clear();
                  _calculatedFinalPrice = 0.0;
                }
              });
            },
          ),
        ],
      ),
      const SizedBox(height: 12),
      // Campo de preço (desabilitado se gratuito)
      IgnorePointer(
        ignoring: _isFreeProduct,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFreeProduct ? 0.4 : 1.0,
          child: TextFormField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: _isFreeProduct ? 'Gratuito' : '0,00',
              errorText: _priceError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: _isFreeProduct ? Colors.grey[200] : Colors.grey[50],
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CurrencyInputFormatter(),
            ],
          ),
        ),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 6. Desconto (desabilitado se gratuito)
      IgnorePointer(
        ignoring: _isFreeProduct,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFreeProduct ? 0.4 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      onSelected: _isFreeProduct ? null : (selected) => setState(() {
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
                      onSelected: _isFreeProduct ? null : (selected) => setState(() {
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
                      onSelected: _isFreeProduct ? null : (selected) => setState(() {
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
            ],
          ),
        ),
      ),
      const Divider(height: 48, thickness: 0.5),

      // 7. Valor final
      IgnorePointer(
        ignoring: _isFreeProduct,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFreeProduct ? 0.4 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Valor final',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isFreeProduct ? Colors.green.shade100 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isFreeProduct 
                          ? 'Grátis' 
                          : NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ').format(_calculatedFinalPrice),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (!_isFreeProduct && _discountMode != 'none' && _discountController.text.isNotEmpty)
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
            ],
          ),
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
                final now = DateTime.now();
                // Se a data atual é passada (edição de post antigo), usar hoje
                final safeInitialDate = _promoStartDate.isBefore(now) ? now : _promoStartDate;
                final date = await showDatePicker(
                  context: context,
                  initialDate: safeInitialDate,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 30)),
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
                final now = DateTime.now();
                final tomorrow = now.add(const Duration(days: 1));
                // firstDate deve ser no mínimo amanhã (mesmo se promoStartDate é passada)
                final safeFirstDate = _promoStartDate.isBefore(tomorrow) ? tomorrow : _promoStartDate;
                final safeLastDate = safeFirstDate.add(const Duration(days: 30));
                // initialDate deve estar no range [safeFirstDate, safeLastDate]
                DateTime safeInitialDate;
                if (_promoEndDate.isBefore(safeFirstDate)) {
                  safeInitialDate = safeFirstDate;
                } else if (_promoEndDate.isAfter(safeLastDate)) {
                  safeInitialDate = safeLastDate;
                } else {
                  safeInitialDate = _promoEndDate;
                }
                final date = await showDatePicker(
                  context: context,
                  initialDate: safeInitialDate,
                  firstDate: safeFirstDate,
                  lastDate: safeLastDate,
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
          child: AppRadioPulseLoader(size: 24),
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
      const SizedBox(height: 8),
      // Aviso de segurança sobre localização
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.shield_tick,
            size: 16,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dica de segurança: Use um ponto de referência próximo ao invés do seu endereço exato.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
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
  // HIRING FIELDS
  // ====================================================================

  List<Widget> _buildHiringFields() {
    final sectionTitleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return [
      MultiSelectField(
        title: 'Formato da contratação (opcional)',
        placeholder: 'Shows, gravações, eventos... (até 8)',
        options: MusicConstants.availableForOptions,
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

      MultiSelectField(
        title: 'Tipo de evento *',
        placeholder: 'Selecione 1 opção',
        options: MusicConstants.eventTypeOptions,
        selectedItems: _selectedEventTypes,
        errorText: _eventTypeError,
        maxSelections: 1,
        onSelectionChanged: (values) {
          setState(() {
            _selectedEventTypes
              ..clear()
              ..addAll(values.take(1));
          });
        },
      ),
      const Divider(thickness: 0.5, height: 48),

      MultiSelectField(
        title: 'Formato pretendido (opcional)',
        placeholder: 'Selecione 1 opção',
        options: MusicConstants.gigFormatOptions,
        selectedItems: _selectedGigFormats,
        maxSelections: 1,
        onSelectionChanged: (values) {
          setState(() {
            _selectedGigFormats
              ..clear()
              ..addAll(values.take(1));
          });
        },
      ),
      const Divider(thickness: 0.5, height: 48),

      MultiSelectField(
        title: 'Instrumentos ou funções (opcional)',
        placeholder: 'Selecione até 5 instrumentos/funções',
        options: MusicConstants.instrumentOptions,
        selectedItems: _selectedInstruments,
        errorText: _instrumentsError,
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
      const SizedBox(height: 16),

      MultiSelectField(
        title: 'Gêneros desejados *',
        placeholder: 'Selecione até 5 gêneros',
        options: MusicConstants.genreOptions,
        selectedItems: _selectedGenres,
        errorText: _genresError,
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

      Text(
        'Data da apresentação/contratação *',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final initial = _hiringDate ?? now;
                final date = await showDatePicker(
                  context: context,
                  initialDate: initial.isBefore(now) ? now : initial,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                  helpText: 'Selecione a data',
                  cancelText: 'Cancelar',
                  confirmText: 'OK',
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(primary: AppColors.primary),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => _hiringDate = date);
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _hiringDate == null
                    ? 'Selecionar data'
                    : DateFormat('dd/MM/yyyy').format(_hiringDate!),
              ),
            ),
          ),
          if (_hiringDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Limpar data',
              onPressed: () => setState(() => _hiringDate = null),
              icon: const Icon(Icons.clear),
            ),
          ],
        ],
      ),
      if (_dateError != null) ...[
        const SizedBox(height: 6),
        Text(
          _dateError!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ],
      const SizedBox(height: 8),
      Text(
        'Datas passadas são bloqueadas; altere se a apresentação mudou.',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      const Divider(thickness: 0.5, height: 48),

      // Horários
      Text(
        'Horário de início e término *',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _startTime ?? TimeOfDay.now(),
                  helpText: 'Horário de início',
                  cancelText: 'Cancelar',
                  confirmText: 'OK',
                );
                if (picked != null) {
                  setState(() => _startTime = picked);
                  _recalculateDuration();
                }
              },
              icon: const Icon(Icons.schedule),
              label: Text(_formatTimeOfDay(_startTime)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _endTime ?? TimeOfDay.now(),
                  helpText: 'Horário de término',
                  cancelText: 'Cancelar',
                  confirmText: 'OK',
                );
                if (picked != null) {
                  setState(() => _endTime = picked);
                  _recalculateDuration();
                }
              },
              icon: const Icon(Icons.schedule_outlined),
              label: Text(_formatTimeOfDay(_endTime)),
            ),
          ),
        ],
      ),
      if (_timeError != null) ...[
        const SizedBox(height: 6),
        Text(
          _timeError!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ],
      const SizedBox(height: 8),
      if (_eventDurationMinutes != null)
        Text(
          'Duração estimada: ${(_eventDurationMinutes! / 60).floor()}h ${_eventDurationMinutes! % 60}min',
          style: TextStyle(color: Colors.grey[700]),
        ),
      const Divider(thickness: 0.5, height: 48),

      // Convidados
      Text(
        'Quantidade aproximada de convidados *',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _guestCountController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Ex: 150',
          prefixIcon: const Icon(Icons.people_alt_outlined),
          errorText: _guestCountError,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      ),
      const Divider(thickness: 0.5, height: 48),

      const Text(
        'Localização *',
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
              streetLine.isNotEmpty
                  ? streetLine
                  : (suggestion['display_name'] as String?)?.split(',').first ?? 'Localização',
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
          child: AppRadioPulseLoader(size: 24),
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
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Iconsax.shield_tick,
            size: 16,
            color: Colors.orange.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Dica: use um ponto de referência, não seu endereço exato.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
      const Divider(thickness: 0.5, height: 48),

      // Estrutura disponível
      MultiSelectField(
        title: 'Estrutura do local (opcional)',
        placeholder: 'Selecione o que já existe no local',
        options: MusicConstants.venueSetupOptions,
        selectedItems: _venueSetup,
        maxSelections: 8,
        onSelectionChanged: (values) {
          setState(() {
            _venueSetup
              ..clear()
              ..addAll(values);
          });
        },
      ),
      const Divider(thickness: 0.5, height: 48),

      // Orçamento
      Text(
        'Orçamento aproximado *',
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
        children: MusicConstants.budgetRangeOptions.map((range) {
          final isSelected = _budgetRange == range;
          return FilterChip(
            label: Text(range),
            selected: isSelected,
            onSelected: (_) => setState(() => _budgetRange = range),
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
      if (_budgetError != null) ...[
        const SizedBox(height: 6),
        Text(
          _budgetError!,
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ],
      const Divider(thickness: 0.5, height: 48),

      Text('Fotos (opcional, até 4)', style: sectionTitleStyle),
      const SizedBox(height: 12),
      PhotoCarouselPicker(
        photoPaths: _photoPaths,
        onPhotosChanged: (paths) => setState(() => _photoPaths = paths),
        maxPhotos: 4,
      ),
      const Divider(height: 48, thickness: 0.5),

      Text('Detalhes da oportunidade *', style: sectionTitleStyle),
      const SizedBox(height: 12),
      PostFormFields(
        descriptionController: _messageController,
        descriptionValidator: (v) => v == null || v.trim().isEmpty
            ? 'Campo obrigatório'
            : null,
      ),
      const Divider(height: 48, thickness: 0.5),
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
                    options: MusicConstants.availableForOptions,
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
                      child: AppRadioPulseLoader(size: 24),
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
                  const SizedBox(height: 8),
                  // Aviso de segurança sobre localização
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Iconsax.shield_tick,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dica de segurança: Use um ponto de referência próximo ao invés do seu endereço exato.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(thickness: 0.5, height: 48),

                  // Gêneros musicais
                  MultiSelectField(
                    title: 'Gêneros musicais *',
                    placeholder: 'Selecione até 5 gêneros',
                    options: MusicConstants.genreOptions,
                    selectedItems: _selectedGenres,
                    maxSelections: maxGenres,
                    errorText: _genresError,
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
                    title: 'Instrumentos *',
                    placeholder: 'Selecione até 5 instrumentos',
                    options: MusicConstants.instrumentOptions,
                    selectedItems: _selectedInstruments,
                    maxSelections: maxInstruments,
                    enabled: !_isSaving,
                    errorText: _instrumentsError,
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
                        children: MusicConstants.levelOptions.map((level) {
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

                  // Spotify
                  Text('Spotify (opcional)', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _spotifyController,
                    decoration: InputDecoration(
                      hintText: 'https://open.spotify.com/artist/...',
                      prefixIcon: const Icon(Iconsax.music),
                      suffixIcon: _spotifyController.text.isEmpty
                          ? null
                          : _isValidSpotifyUrl(_spotifyController.text)
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.error_outline, color: Colors.red),
                      helperText: _spotifyController.text.isEmpty
                          ? 'Link para artista, álbum ou playlist no Spotify'
                          : (_isValidSpotifyUrl(_spotifyController.text)
                              ? '✓ Link válido'
                              : '✗ Use um link open.spotify.com ou spotify:'),
                      helperMaxLines: 2,
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
                      if (!_isValidSpotifyUrl(v)) {
                        return 'Insira um link válido do Spotify';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 48, thickness: 0.5),

                  // Deezer
                  Text('Deezer (opcional)', style: sectionTitleStyle),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deezerController,
                    decoration: InputDecoration(
                      hintText: 'https://www.deezer.com/artist/...',
                      prefixIcon: const Icon(Iconsax.music_square),
                      suffixIcon: _deezerController.text.isEmpty
                          ? null
                          : _isValidDeezerUrl(_deezerController.text)
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.error_outline, color: Colors.red),
                      helperText: _deezerController.text.isEmpty
                          ? 'Link para artista, álbum ou playlist no Deezer'
                          : (_isValidDeezerUrl(_deezerController.text)
                              ? '✓ Link válido'
                              : '✗ Use um link deezer.com ou deezer.page.link'),
                      helperMaxLines: 2,
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
                      if (!_isValidDeezerUrl(v)) {
                        return 'Insira um link válido do Deezer';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
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
                      helperText: _youtubeController.text.isEmpty
                          ? 'Adicione um vídeo do YouTube para enriquecer seu post!'
                          : (_extractYouTubeVideoId(_youtubeController.text) !=
                                  null
                              ? '✓ Vídeo encontrado'
                              : '✗ URL inválida'),
                      helperMaxLines: 2,
                      helperStyle: TextStyle(
                        color: _youtubeController.text.isEmpty
                            ? AppColors.textSecondary
                            : (_extractYouTubeVideoId(_youtubeController.text) !=
                                    null
                                ? Colors.green
                                : Colors.red),
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
                  if (_youtubeController.text.isNotEmpty &&
                      _extractYouTubeVideoId(_youtubeController.text) != null) ...[
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
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto explicativo discreto
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.play_circle_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este vídeo será exibido na visualização do seu post',
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
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: AppRadioPulseLoader(size: 36),
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
    final formatted = NumberFormat.currency(locale: 'pt_BR', symbol: '').format(value / 100);
    
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
