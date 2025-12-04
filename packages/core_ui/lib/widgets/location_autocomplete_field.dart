import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_ui/theme/app_colors.dart';
import 'package:core_ui/utils/address_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';

/// Widget para seleção de localização com autocomplete
/// 
/// Integra com OpenStreetMap Nominatim API para busca de endereços.
/// Retorna coordenadas geográficas (GeoPoint) e dados estruturados de localização.
/// 
/// ⚡ PERFORMANCE: Extraído de post_page.dart para reutilização
/// - Reusável em post_page, edit_post_page, profile_page
/// - Encapsula lógica de debouncing e API calls
/// - Testável isoladamente
class LocationAutocompleteField extends StatefulWidget {
  /// Cria um campo de autocomplete para seleção de localização
  const LocationAutocompleteField({
    required this.onLocationSelected,
    this.initialAddress,
    this.hintText = 'Buscar localização (cidade, bairro, endereço...)',
    this.validator,
    this.enabled = true,
    super.key,
  });

  /// Callback quando uma localização é selecionada
  /// 
  /// Parâmetros:
  /// - location: GeoPoint com latitude e longitude
  /// - city: Nome da cidade
  /// - neighborhood: Nome do bairro (pode ser null)
  /// - state: Nome do estado (pode ser null)
  /// - fullAddress: Endereço completo formatado
  final Function(
    GeoPoint location,
    String city,
    String? neighborhood,
    String? state,
    String fullAddress,
  ) onLocationSelected;

  /// Endereço inicial a ser exibido no campo
  final String? initialAddress;

  /// Texto de hint a ser exibido quando o campo está vazio
  final String hintText;

  /// Validador customizado para o campo
  final String? Function(String?)? validator;

  /// Se o campo está habilitado para edição
  final bool enabled;

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  /// Listener para atualizar UI quando texto mudar
  void _onTextChanged() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialAddress);
    _focusNode = FocusNode();
    
    // ✅ Atualizar UI quando texto mudar (para mostrar/esconder botão clear)
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged); // ✅ Remove listener antes de dispose
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Busca sugestões de endereço usando OpenStreetMap Nominatim API
  /// 
  /// Retorna no máximo 5 sugestões filtradas e formatadas.
  /// Implementa rate limiting básico via query mínimo de 3 caracteres.
  /// 
  /// ⚠️ IMPORTANTE: Só busca sugestões se o campo estiver focado
  Future<List<Map<String, dynamic>>> _fetchAddressSuggestions(String query) async {
    // ✅ NÃO buscar sugestões se o campo não estiver focado
    if (!_focusNode.hasFocus) return [];
    
    if (query.isEmpty || query.length < 3) return [];

    try {
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
      
      debugPrint('⚠️ LocationAutocompleteField: Nominatim API returned ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('❌ LocationAutocompleteField: Error fetching suggestions - $e');
      return [];
    }
  }

  /// Processa a seleção de um endereço
  /// 
  /// Extrai componentes estruturados (cidade, bairro, estado) e
  /// chama o callback com os dados processados.
  void _onAddressSelected(Map<String, dynamic> suggestion) {
    final lat = double.tryParse((suggestion['lat'] as String?) ?? '') ?? 0.0;
    final lon = double.tryParse((suggestion['lon'] as String?) ?? '') ?? 0.0;

    if (lat == 0.0 && lon == 0.0) {
      debugPrint('⚠️ LocationAutocompleteField: Invalid coordinates');
      return;
    }

    final address = suggestion['address'] as Map<String, dynamic>?;

    // Extrair componentes estruturados
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

    // Montar endereço formatado no estilo Airbnb (clean)
    final fullAddress = AddressFormatter.formatShort(
      road: road.isNotEmpty ? road : null,
      neighbourhood: neighbourhood.isNotEmpty ? neighbourhood : null,
      city: city.isNotEmpty ? city : null,
      state: state.isNotEmpty ? state : null,
    );

    // Atualizar campo de texto
    _controller.text = fullAddress;

    // Notificar callback
    widget.onLocationSelected(
      GeoPoint(lat, lon),
      city,
      neighbourhood.isNotEmpty ? neighbourhood : null,
      state.isNotEmpty ? state : null,
      fullAddress,
    );

    debugPrint('✅ LocationAutocompleteField: Selected location - $city ($lat, $lon)');
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<Map<String, dynamic>>(
      controller: _controller,
      focusNode: _focusNode,
      suggestionsCallback: _fetchAddressSuggestions,
      // ✅ Só mostra overlay quando está focado E tem sugestões
      hideOnEmpty: true,
      hideOnLoading: false,
      hideOnSelect: true,
      // ✅ Fecha automaticamente ao perder foco
      hideOnUnfocus: true,
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: widget.enabled,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Iconsax.location, color: AppColors.primary),
            // ✅ Botão para limpar o campo
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle, color: AppColors.textSecondary),
                    onPressed: () {
                      _controller.clear();
                      _focusNode.unfocus();
                    },
                  )
                : null,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          validator: widget.validator,
        );
      },
      itemBuilder: (context, suggestion) {
        return ListTile(
          leading: const Icon(Iconsax.location, color: AppColors.primary),
          title: Text(
            (suggestion['display_name'] as String?) ?? '',
            style: const TextStyle(fontSize: 14),
          ),
        );
      },
      onSelected: (suggestion) {
        _onAddressSelected(suggestion);
        // ✅ Remove foco após seleção para fechar o teclado
        _focusNode.unfocus();
      },
      emptyBuilder: (context) => const SizedBox.shrink(), // ✅ Não mostra nada quando vazio
    );
  }

  /// Limpa o campo de localização
  void clear() {
    _controller.clear();
  }

  /// Define o texto do campo programaticamente
  void setText(String text) {
    _controller.text = text;
  }
}
