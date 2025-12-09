import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_params.freezed.dart';

@freezed
class SearchParams with _$SearchParams {
  const factory SearchParams({
    required String city,
    required double maxDistanceKm,
    String? level,
    @Default({}) Set<String> instruments,
    @Default({}) Set<String> genres,
    String? postType, // 'musician', 'band', ou 'sales'
    String? availableFor, // 'gig', 'rehearsal', etc.
    bool? hasYoutube,
    // ✅ Campos de sales (anúncios)
    String? salesType, // 'Gravação', 'Ensaios', etc
    double? minPrice, // Faixa de preço mínima
    double? maxPrice, // Faixa de preço máxima
    bool? onlyWithDiscount, // Apenas anúncios com desconto
    bool? onlyActivePromos, // Apenas promoções ativas (não expiradas)
    String? searchUsername, // Busca por @username
  }) = _SearchParams;
}
