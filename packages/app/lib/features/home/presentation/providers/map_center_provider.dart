import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls whether the Google Maps camera already centered on a profile.
class MapCenterNotifier extends StateNotifier<Map<String, bool>> {
  MapCenterNotifier() : super(const <String, bool>{});

  bool hasCentered(String profileId) => state[profileId] ?? false;

  void markCentered(String profileId) {
    if (profileId.isEmpty || state[profileId] == true) return;
    state = {
      ...state,
      profileId: true,
    };
  }

  void reset(String profileId) {
    if (profileId.isEmpty || !state.containsKey(profileId)) return;
    final updated = Map<String, bool>.from(state)..remove(profileId);
    state = updated;
  }

  void resetAll() {
    if (state.isEmpty) return;
    state = const <String, bool>{};
  }
}

final mapCenterProvider =
    StateNotifierProvider<MapCenterNotifier, Map<String, bool>>(
  (ref) => MapCenterNotifier(),
);
