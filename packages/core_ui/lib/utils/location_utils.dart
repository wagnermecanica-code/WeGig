/// Shared helpers for formatting user-friendly location strings.
///
/// Centralizes common patterns used across the app so UI surfaces stay
/// consistent ("Bairro · Cidade · UF") and gracefully handle missing data.
const Map<String, String> _stateAbbreviations = {
  'São Paulo': 'SP',
  'Rio de Janeiro': 'RJ',
  'Minas Gerais': 'MG',
  'Bahia': 'BA',
  'Paraná': 'PR',
  'Rio Grande do Sul': 'RS',
  'Pernambuco': 'PE',
  'Ceará': 'CE',
  'Pará': 'PA',
  'Santa Catarina': 'SC',
  'Goiás': 'GO',
  'Maranhão': 'MA',
  'Paraíba': 'PB',
  'Espírito Santo': 'ES',
  'Amazonas': 'AM',
  'Mato Grosso': 'MT',
  'Rio Grande do Norte': 'RN',
  'Piauí': 'PI',
  'Alagoas': 'AL',
  'Distrito Federal': 'DF',
  'Mato Grosso do Sul': 'MS',
  'Sergipe': 'SE',
  'Rondônia': 'RO',
  'Tocantins': 'TO',
  'Acre': 'AC',
  'Amapá': 'AP',
  'Roraima': 'RR',
};

/// Returns a clean two-letter abbreviation for a given Brazilian state name.
///
/// Keeps already abbreviated inputs (e.g. "SP") and normalizes casing.
String abbreviateState(String? state) {
  if (state == null) return '';
  final trimmed = state.trim();
  if (trimmed.isEmpty) return '';

  final upper = trimmed.toUpperCase();
  final isAlreadyAbbreviation =
      upper.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(upper);
  if (isAlreadyAbbreviation) {
    return upper;
  }

  return _stateAbbreviations[trimmed] ?? trimmed;
}

/// Formats a location string following the "Neighborhood · City · UF" pattern.
///
/// - Skips empty/null segments
/// - Removes duplicated consecutive values (case insensitive)
/// - Falls back to [fallback] when nothing is available
String formatCleanLocation({
  String? neighborhood,
  String? neighbourhood,
  String? city,
  String? state,
  String fallback = 'Localização não informada',
}) {
  final parts = <String>[];

  void addPart(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }
    final alreadyAdded = parts.any(
      (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!alreadyAdded) {
      parts.add(trimmed);
    }
  }

  addPart(neighborhood ?? neighbourhood);
  addPart(city);
  addPart(abbreviateState(state));

  return parts.isEmpty ? fallback : parts.join(' · ');
}
