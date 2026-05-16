import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_params.freezed.dart';

@freezed
class SearchParams with _$SearchParams {
  const factory SearchParams({
    required String city,
    required double maxDistanceKm,
    @Default(false) bool onlyConnections,
    String? level,
    @Default({}) Set<String> instruments,
    @Default({}) Set<String> genres,
    String? postType, // 'musician', 'band', 'sales' ou 'hiring'
    @Default({}) Set<String> availableFor, // Disponibilidades/formatos
    bool? hasYoutube,
    bool? hasSpotify,
    bool? hasDeezer,

    // ✅ Campos de hiring (contratação)
    @Default({}) Set<String> eventTypes,
    @Default({}) Set<String> gigFormats,
    @Default({}) Set<String> venueSetups,
    @Default({}) Set<String> budgetRanges,

    // ✅ Campos de sales (anúncios)
    @Default({}) Set<String> salesTypes, // 'Gravação', 'Ensaios', etc (multi)
    double? minPrice, // Faixa de preço mínima
    double? maxPrice, // Faixa de preço máxima
    bool? onlyWithDiscount, // Apenas anúncios com desconto
    String? searchUsername, // Busca por @username
  }) = _SearchParams;
}
