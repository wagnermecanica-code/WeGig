import 'package:flutter_test/flutter_test.dart';
import 'package:wegig_app/features/post/presentation/widgets/genre_selector.dart';

/// Unit tests for GenreSelector widget's static utility methods
/// Widget interaction tests should be covered in integration tests due to
/// complexity of testing MultiSelectField interactions
void main() {
  group('GenreSelector - Validation Methods', () {
    test('validateRequired returns error for empty selection', () {
      final result = GenreSelector.validateRequired(<String>{});
      expect(result, 'Selecione pelo menos um gênero');
    });

    test('validateRequired returns null for non-empty selection', () {
      final result = GenreSelector.validateRequired({'Rock'});
      expect(result, isNull);
    });

    test('validateMaxSelections returns error when limit exceeded', () {
      final result =
          GenreSelector.validateMaxSelections({'Rock', 'Jazz', 'Pop'}, 2);
      expect(result, 'Selecione no máximo 2 gêneros');
    });

    test('validateMaxSelections returns null when within limit', () {
      final result = GenreSelector.validateMaxSelections({'Rock', 'Jazz'}, 3);
      expect(result, isNull);
    });

    test('validateMaxSelections with limit 0 always fails', () {
      final result = GenreSelector.validateMaxSelections({'Rock'}, 0);
      expect(result, isNotNull);
    });
  });

  group('GenreSelector - Formatting Methods', () {
    test('formatGenres returns comma-separated list', () {
      final result = GenreSelector.formatGenres({'Rock', 'Jazz', 'Pop'});
      // Sets don't guarantee order, just verify all genres are present
      expect(result.contains('Rock'), true);
      expect(result.contains('Jazz'), true);
      expect(result.contains('Pop'), true);
      expect(result.split(', ').length, 3);
    });

    test('formatGenres returns message for empty set', () {
      final result = GenreSelector.formatGenres(<String>{});
      expect(result, 'Nenhum gênero selecionado');
    });

    test('formatGenresShort shows all genres when count <= maxShow', () {
      final result =
          GenreSelector.formatGenresShort({'Rock', 'Jazz'}, maxShow: 3);
      expect(result.contains('Rock'), true);
      expect(result.contains('Jazz'), true);
      expect(result, isNot(contains('e +')));
    });

    test('formatGenresShort truncates when count > maxShow', () {
      final result = GenreSelector.formatGenresShort(
        {'Rock', 'Jazz', 'Pop', 'Blues'},
        maxShow: 2,
      );
      expect(result, contains('e +2'));
      // Verify only 2 genres are shown
      final shownGenres = result.split(' e +')[0].split(', ');
      expect(shownGenres.length, 2);
    });

    test('formatGenresShort with maxShow=0 shows only remaining count', () {
      final result =
          GenreSelector.formatGenresShort({'Rock', 'Jazz'}, maxShow: 0);
      expect(result, contains('e +2'));
    });
  });

  group('GenreSelector - Genre Options', () {
    test('genreOptions has expected total count', () {
      expect(GenreSelector.genreOptions.length, 22);
    });

    test('genreOptions contains popular international genres', () {
      expect(GenreSelector.genreOptions.contains('Rock'), true);
      expect(GenreSelector.genreOptions.contains('Jazz'), true);
      expect(GenreSelector.genreOptions.contains('Pop'), true);
      expect(GenreSelector.genreOptions.contains('Blues'), true);
    });

    test('genreOptions contains Brazilian genres', () {
      expect(GenreSelector.genreOptions.contains('Sertanejo'), true);
      expect(GenreSelector.genreOptions.contains('MPB'), true);
      expect(GenreSelector.genreOptions.contains('Forró'), true);
      expect(GenreSelector.genreOptions.contains('Samba'), true);
      expect(GenreSelector.genreOptions.contains('Pagode'), true);
    });

    test('genreOptions contains Outro option', () {
      expect(GenreSelector.genreOptions.contains('Outro'), true);
    });

    test('genreOptions contains electronic genres', () {
      expect(GenreSelector.genreOptions.contains('Eletrônica'), true);
    });

    test('genreOptions contains urban genres', () {
      expect(GenreSelector.genreOptions.contains('Hip Hop'), true);
      expect(GenreSelector.genreOptions.contains('Rap'), true);
      expect(GenreSelector.genreOptions.contains('Funk'), true);
    });

    test('genreOptions does not contain duplicates', () {
      final uniqueGenres = GenreSelector.genreOptions.toSet();
      expect(uniqueGenres.length, GenreSelector.genreOptions.length);
    });
  });
}
