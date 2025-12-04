import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/home/presentation/providers/map_center_provider.dart';

void main() {
  group('MapCenterNotifier', () {
    test('starts with no centered profiles', () {
      final notifier = MapCenterNotifier();

      expect(notifier.hasCentered('profile_1'), isFalse);
    });

    test('marks a profile as centered and prevents duplicate entries', () {
      final notifier = MapCenterNotifier();

      notifier.markCentered('profile_1');
      notifier.markCentered('profile_1');

      expect(notifier.hasCentered('profile_1'), isTrue);
      expect(notifier.state.length, 1);
    });

    test('resetting a profile allows recentering', () {
      final notifier = MapCenterNotifier();

      notifier.markCentered('profile_1');
      notifier.reset('profile_1');

      expect(notifier.hasCentered('profile_1'), isFalse);
    });
  });
}
