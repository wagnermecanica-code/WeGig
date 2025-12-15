import 'location_utils.dart';

/// Utility class for formatting addresses in a clean, Airbnb-style format
///
/// Examples:
/// - "São Paulo, SP" (city only)
/// - "Pinheiros, São Paulo" (neighborhood + city)
/// - "Rua Augusta, Pinheiros" (street + neighborhood)
/// 
/// NEVER shows full long addresses like:
/// "Rua Augusta, 123, Pinheiros, São Paulo, SP, Brasil, CEP..."

class AddressFormatter {
  /// Formats an address in Airbnb-style (short and clean)
  /// 
  /// Priority order:
  /// 1. If has street + neighborhood: "Street, Neighborhood"
  /// 2. If has neighborhood + city: "Neighborhood, City"
  /// 3. If has city + state: "City, State"
  /// 4. Fallback: city only or whatever is available
  static String formatShort({
    String? road,
    String? neighbourhood,
    String? city,
    String? state,
  }) {
    final parts = <String>[];

    // Priority 1: Street + Neighborhood (most specific)
    if (road != null && road.isNotEmpty && 
        neighbourhood != null && neighbourhood.isNotEmpty) {
      return '$road, $neighbourhood';
    }

    // Priority 2: Neighborhood + City
    if (neighbourhood != null && neighbourhood.isNotEmpty) {
      parts.add(neighbourhood);
      if (city != null && city.isNotEmpty) {
        parts.add(city);
      }
      return parts.join(', ');
    }

    // Priority 3: City + State
    if (city != null && city.isNotEmpty) {
      parts.add(city);
      if (state != null && state.isNotEmpty) {
        // Use abbreviation if available (e.g., "SP" instead of "São Paulo")
        parts.add(abbreviateState(state));
      }
      return parts.join(', ');
    }

    // Fallback: Just state or empty
    return state ?? '';
  }

  /// Formats an address for suggestion display (TypeAheadField)
  /// 
  /// Shows more context than formatShort but still clean:
  /// - "Rua Augusta - Pinheiros, São Paulo"
  /// - "Pinheiros - São Paulo, SP"
  static String formatSuggestion(Map<String, dynamic> suggestion) {
    final address = suggestion['address'] as Map<String, dynamic>?;
    if (address == null) {
      // Fallback to display_name but truncate
      final displayName = suggestion['display_name'] as String? ?? '';
      return truncate(displayName, maxLength: 50);
    }

    final road = (address['road'] as String?) ?? '';
    final neighbourhood = (address['neighbourhood'] as String?) ??
        (address['suburb'] as String?) ??
        (address['quarter'] as String?) ??
        '';
    final city = (address['city'] as String?) ??
        (address['town'] as String?) ??
        (address['village'] as String?) ??
        '';
    final state = (address['state'] as String?) ?? '';

    final parts = <String>[];

    // Main part (road or neighbourhood)
    if (road.isNotEmpty) {
      final main = neighbourhood.isNotEmpty 
          ? '$road - $neighbourhood' 
          : road;
      parts.add(main);
    } else if (neighbourhood.isNotEmpty) {
      parts.add(neighbourhood);
    }

    // Secondary part (city, state)
    if (city.isNotEmpty) {
        final secondary = state.isNotEmpty 
          ? '$city, ${abbreviateState(state)}'
          : city;
      parts.add(secondary);
    }

    return parts.isNotEmpty ? parts.join(', ') : '';
  }

  /// Truncates long strings with ellipsis
  static String truncate(String text, {int maxLength = 40}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

}
